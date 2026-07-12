#include "LuauConsole.h"

#include <cstdlib>
#include <cstring>

#include "lua.h"
#include "lualib.h"
#include "luacode.h"

namespace {
constexpr const char* kInstanceMetatableName = "Instance";
constexpr const char* kSelfRegistryKey = "__luauconsole_self";

std::string ToDisplayString(lua_State* L, int index) {
    lua_getglobal(L, "tostring");
    lua_pushvalue(L, index);
    lua_call(L, 1, 1);
    const char* s = lua_tostring(L, -1);
    std::string result = s ? s : "<error converting to string>";
    lua_pop(L, 1);
    return result;
}
} // namespace

LuauConsole::LuauConsole()
    : L_(luaL_newstate())
    , game_("DataModel", "game")
    , workspace_("Workspace", "Workspace") {
    OpenLibraries();

    lua_pushlightuserdata(L_, this);
    lua_setfield(L_, LUA_REGISTRYINDEX, kSelfRegistryKey);

    RegisterInstanceMetatable();

    lua_pushcfunction(L_, Lua_print, "print");
    lua_setglobal(L_, "print");
    lua_pushcfunction(L_, Lua_warn, "warn");
    lua_setglobal(L_, "warn");

    RegisterService("Workspace", workspace_);
    PushGlobals();
}

LuauConsole::~LuauConsole() {
    lua_close(L_);
}

void LuauConsole::OpenLibraries() {
    luaL_openlibs(L_);
}

void LuauConsole::RegisterInstanceMetatable() {
    luaL_newmetatable(L_, kInstanceMetatableName);

    lua_pushcfunction(L_, Instance_Index, "Instance.__index");
    lua_setfield(L_, -2, "__index");

    lua_pushcfunction(L_, Instance_NewIndex, "Instance.__newindex");
    lua_setfield(L_, -2, "__newindex");

    lua_pushcfunction(L_, Instance_ToString, "Instance.__tostring");
    lua_setfield(L_, -2, "__tostring");

    lua_pushcfunction(L_, Instance_Eq, "Instance.__eq");
    lua_setfield(L_, -2, "__eq");

    lua_pop(L_, 1);
}

void LuauConsole::PushInstance(lua_State* L, Instance* instance) {
    if (!instance) {
        lua_pushnil(L);
        return;
    }
    Instance** ud = static_cast<Instance**>(lua_newuserdata(L, sizeof(Instance*)));
    *ud = instance;
    luaL_getmetatable(L, kInstanceMetatableName);
    lua_setmetatable(L, -2);
}

void LuauConsole::PushGlobals() {
    PushInstance(L_, &game_);
    lua_setglobal(L_, "game");

    PushInstance(L_, &workspace_);
    lua_setglobal(L_, "workspace");
}

void LuauConsole::RegisterService(const std::string& name, Instance& service) {
    service.SetParent(&game_);
    services_[name] = &service;
    PushInstance(L_, &service);
    lua_setglobal(L_, name.c_str());
}

void LuauConsole::Report(const std::string& message, bool isError) {
    if (outputCallback_) {
        outputCallback_(message, isError);
    }
}

bool LuauConsole::Execute(const std::string& source, const std::string& chunkName) {
    size_t bytecodeSize = 0;
    char* bytecode = luau_compile(source.c_str(), source.size(), nullptr, &bytecodeSize);

    if (bytecodeSize == 0) {
        std::free(bytecode);
        Report("compiler returned an empty result", true);
        return false;
    }

    // luau_compile's contract: byte 0 == 0 means success; non-zero means the
    // rest of the buffer (offset 1..) is the error message text.
    if (bytecode[0] != 0) {
        std::string error(bytecode + 1, bytecodeSize - 1);
        std::free(bytecode);
        Report(error, true);
        return false;
    }

    int loadResult = luau_load(L_, chunkName.c_str(), bytecode, bytecodeSize, 0);
    std::free(bytecode);

    if (loadResult != 0) {
        const char* err = lua_tostring(L_, -1);
        Report(err ? err : "unknown load error", true);
        lua_pop(L_, 1);
        return false;
    }

    int callResult = lua_pcall(L_, 0, LUA_MULTRET, 0);
    if (callResult != LUA_OK) {
        const char* err = lua_tostring(L_, -1);
        Report(err ? err : "unknown runtime error", true);
        lua_pop(L_, 1);
        return false;
    }

    return true;
}

LuauConsole* LuauConsole::GetSelf(lua_State* L) {
    lua_getfield(L, LUA_REGISTRYINDEX, kSelfRegistryKey);
    LuauConsole* self = static_cast<LuauConsole*>(lua_touserdata(L, -1));
    lua_pop(L, 1);
    return self;
}

Instance* LuauConsole::CheckInstance(lua_State* L, int index) {
    void* ud = luaL_checkudata(L, index, kInstanceMetatableName);
    return *static_cast<Instance**>(ud);
}

int LuauConsole::Lua_print(lua_State* L) {
    LuauConsole* self = GetSelf(L);
    int n = lua_gettop(L);
    std::string message;
    for (int i = 1; i <= n; ++i) {
        if (i > 1) message += "\t";
        message += ToDisplayString(L, i);
    }
    self->Report(message, false);
    return 0;
}

int LuauConsole::Lua_warn(lua_State* L) {
    LuauConsole* self = GetSelf(L);
    int n = lua_gettop(L);
    std::string message;
    for (int i = 1; i <= n; ++i) {
        if (i > 1) message += "\t";
        message += ToDisplayString(L, i);
    }
    self->Report(message, true);
    return 0;
}

int LuauConsole::Instance_Index(lua_State* L) {
    Instance* self = CheckInstance(L, 1);
    const char* key = luaL_checkstring(L, 2);
    LuauConsole* console = GetSelf(L);

    if (std::strcmp(key, "Name") == 0) {
        lua_pushstring(L, self->Name.c_str());
        return 1;
    }
    if (std::strcmp(key, "ClassName") == 0) {
        lua_pushstring(L, self->ClassName.c_str());
        return 1;
    }
    if (std::strcmp(key, "Parent") == 0) {
        console->PushInstance(L, self->GetParent());
        return 1;
    }
    if (std::strcmp(key, "FindFirstChild") == 0) {
        lua_pushcfunction(L, Instance_FindFirstChild, "Instance.FindFirstChild");
        return 1;
    }
    if (std::strcmp(key, "GetChildren") == 0) {
        lua_pushcfunction(L, Instance_GetChildren, "Instance.GetChildren");
        return 1;
    }
    if (std::strcmp(key, "Destroy") == 0) {
        lua_pushcfunction(L, Instance_Destroy, "Instance.Destroy");
        return 1;
    }

    // Only `game` exposes registered services as properties (mirrors
    // Roblox's game.Workspace / game.Players style access).
    if (self == &console->game_) {
        auto it = console->services_.find(key);
        if (it != console->services_.end()) {
            console->PushInstance(L, it->second);
            return 1;
        }
    }

    lua_pushnil(L);
    return 1;
}

int LuauConsole::Instance_NewIndex(lua_State* L) {
    Instance* self = CheckInstance(L, 1);
    const char* key = luaL_checkstring(L, 2);

    if (std::strcmp(key, "Name") == 0) {
        self->Name = luaL_checkstring(L, 3);
        return 0;
    }
    if (std::strcmp(key, "Parent") == 0) {
        if (lua_isnil(L, 3)) {
            self->SetParent(nullptr);
        } else {
            Instance* parent = CheckInstance(L, 3);
            self->SetParent(parent);
        }
        return 0;
    }

    luaL_error(L, "%s is not a valid member of %s", key, self->ClassName.c_str());
    return 0;
}

int LuauConsole::Instance_ToString(lua_State* L) {
    Instance* self = CheckInstance(L, 1);
    lua_pushstring(L, self->Name.c_str());
    return 1;
}

int LuauConsole::Instance_Eq(lua_State* L) {
    Instance* a = CheckInstance(L, 1);
    Instance* b = CheckInstance(L, 2);
    lua_pushboolean(L, a == b);
    return 1;
}

int LuauConsole::Instance_FindFirstChild(lua_State* L) {
    Instance* self = CheckInstance(L, 1);
    const char* name = luaL_checkstring(L, 2);
    LuauConsole* console = GetSelf(L);
    console->PushInstance(L, self->FindFirstChild(name));
    return 1;
}

int LuauConsole::Instance_GetChildren(lua_State* L) {
    Instance* self = CheckInstance(L, 1);
    LuauConsole* console = GetSelf(L);
    const auto& children = self->GetChildren();
    lua_createtable(L, static_cast<int>(children.size()), 0);
    for (size_t i = 0; i < children.size(); ++i) {
        console->PushInstance(L, children[i]);
        lua_rawseti(L, -2, static_cast<int>(i) + 1);
    }
    return 1;
}

int LuauConsole::Instance_Destroy(lua_State* L) {
    Instance* self = CheckInstance(L, 1);
    self->Destroy();
    return 0;
}
