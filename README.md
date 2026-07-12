# LuauConsole

A dev-console component for a game engine that already embeds Luau. Exposes
a small Roblox-shaped `Instance` model (`Name`, `ClassName`, `Parent`,
`GetChildren()`, `FindFirstChild()`, `Destroy()`) plus `game` / `workspace`
globals, and runs arbitrary Luau source against them.

This links the real open-source [Luau VM](https://github.com/luau-lang/luau)
into **your own binary** — it is not injected into any other process and
does not touch Roblox's client. `game`/`workspace` here are plain C++
objects you own; they start out empty and only contain whatever you wire in.

## Quick start

### GitHub Codespaces (recommended)

Open in Codespaces (`.devcontainer.json` auto-runs setup):

```bash
source env.sh
./build.sh
./build/luauconsole_repl
```

### Local build

```bash
chmod +x build.sh
./build.sh
./build/luauconsole_repl
```

Or manually:

```bash
cmake -S . -B build
cmake --build build
./build/luauconsole_repl
```

By default `CMakeLists.txt` fetches Luau from its GitHub repo via
`FetchContent`. If your engine already links Luau elsewhere, delete that
block and point `target_link_libraries(luauconsole PUBLIC ...)` at your
existing `Luau.Compiler` / `Luau.VM` targets instead.

## iOS Integration

For iOS games, the `ios/` folder contains a ready-made popup console UI:

- **`LuauConsoleViewController.mm`** — the modal console window (code editor + output)
- **`LuauConsoleButton.mm`** — a floating "W" button at top-center that opens it

Just add them to your iOS project, instantiate `LuauConsoleButton` in your game's
main view controller, and wire your C++ `LuauConsole` instance to the UI bridge.

See `ios/INTEGRATION.md` for setup steps.

## Wiring in real engine objects

`Instance` (`include/Instance.h`) is a plain base class — `Name`,
`ClassName`, parent/child links, nothing else. Subclass it for your real
engine types and pass a reference to `RegisterService`:

```cpp
class PlayersService : public Instance {
public:
    PlayersService() : Instance("Players", "Players") {}
    // add real fields/methods, then expose them to Luau by extending
    // Instance_Index / Instance_NewIndex in LuauConsole.cpp for this
    // ClassName, or give PlayersService its own metatable if the shape
    // diverges a lot from base Instance.
};

PlayersService players;
console.RegisterService("Players", players);
```

```lua
-- now reachable from Luau as both a global and via game:
print(Players.Name)
print(game.Players == Players)
```

## Console output

Wire `SetOutputCallback` to your engine's on-screen console/log UI instead
of stdout:

```cpp
console.SetOutputCallback([&](const std::string& msg, bool isError) {
    devConsoleUI.AppendLine(msg, isError ? Color::Red : Color::White);
});
```

`print()` and `warn()` in Luau route through this callback, as do
compile/runtime errors.

## Extending the API surface

Everything Roblox-specific here is just a naming convention we chose
(`game`, `workspace`, `Parent`, `FindFirstChild`) — there's no dependency on
Roblox internals. Add whatever else your scripts need (`Vector3`,
`CFrame`, `RunService`, custom events) as additional C functions/userdata
registered the same way `Instance` is in `RegisterInstanceMetatable()`.
