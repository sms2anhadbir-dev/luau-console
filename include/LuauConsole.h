#pragma once

#include <functional>
#include <string>
#include <unordered_map>

#include "Instance.h"

struct lua_State;

// Embeds a Luau VM and exposes a small Roblox-shaped global surface
// (game / workspace / Instance-likes) that your engine populates with real
// objects via RegisterService(). Not a Roblox client, not injected into
// anything — this links directly into your own game binary.
class LuauConsole {
public:
    // isError=false for print()/normal output, true for warn()/error()/runtime errors.
    using OutputCallback = std::function<void(const std::string& message, bool isError)>;

    LuauConsole();
    ~LuauConsole();

    LuauConsole(const LuauConsole&) = delete;
    LuauConsole& operator=(const LuauConsole&) = delete;

    void SetOutputCallback(OutputCallback callback) { outputCallback_ = std::move(callback); }

    // Compiles and runs a chunk of Luau source. Returns false and reports
    // the error via the output callback if compilation or execution fails.
    bool Execute(const std::string& source, const std::string& chunkName = "console");

    Instance& Game() { return game_; }
    Instance& Workspace() { return workspace_; }

    // Parents `service` under game and exposes it as both game.<name> and a
    // bare global `name` (mirrors Roblox's GetService()-style access).
    // LuauConsole does not own `service`; your engine keeps it alive.
    void RegisterService(const std::string& name, Instance& service);

private:
    lua_State* L_;
    Instance game_;
    Instance workspace_;
    std::unordered_map<std::string, Instance*> services_;

    void OpenLibraries();
    void RegisterInstanceMetatable();
    void PushInstance(lua_State* L, Instance* instance);
    void PushGlobals();
    void Report(const std::string& message, bool isError);

    static int Lua_print(lua_State* L);
    static int Lua_warn(lua_State* L);

    static int Instance_Index(lua_State* L);
    static int Instance_NewIndex(lua_State* L);
    static int Instance_ToString(lua_State* L);
    static int Instance_Eq(lua_State* L);
    static int Instance_FindFirstChild(lua_State* L);
    static int Instance_GetChildren(lua_State* L);
    static int Instance_Destroy(lua_State* L);

    static Instance* CheckInstance(lua_State* L, int index);
    static LuauConsole* GetSelf(lua_State* L);
};
