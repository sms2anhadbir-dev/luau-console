# LuauConsole Theos Tweak

Builds `LuauConsoleTweak.dylib` — injects a floating **"W" button** at the
top-center of **your own app**. Tapping it opens a popup with a Luau code
editor, **Run** / **Clear** / **✕** buttons, and an output console. The real
open-source Luau VM is compiled directly into the dylib.

This is injected into **your own app's** process using the standard Theos /
`LC_LOAD_DYLIB` pipeline (see the `hello-world-ipa-test` repo for the injection
steps). It does not touch any other process.

## Prerequisites

A working Theos + L1ghtmann toolchain + iOS 14.5 SDK in your Codespace. If you
haven't set that up, run the `setup-toolchain.sh` from the
`hello-world-ipa-test` repo first.

## Build

```bash
cd tweak

# 1. Set your app's bundle ID as the injection target
#    Edit LuauConsoleTweak.plist and replace com.yourcompany.yourapp

# 2. Fetch the Luau source (one-time)
chmod +x fetch-luau.sh
./fetch-luau.sh

# 3. Build the dylib
export THEOS=~/theos
export PATH=$THEOS/bin:$THEOS/toolchain/linux/iphone/bin:$PATH
make clean
make package

# dylib lands at: .theos/obj/debug/LuauConsoleTweak.dylib
```

## Inject into your app's IPA

Use the `inject-dylib.sh` from `hello-world-ipa-test`:

```bash
./inject-dylib.sh YourApp.ipa \
    path/to/.theos/obj/debug/LuauConsoleTweak.dylib \
    YourApp-console.ipa
```

## Notes

- **No Substrate required**: this tweak does **not** use `%hook`. It installs
  the W button from a constructor (`__attribute__((constructor))`) that
  registers for `UIApplicationDidBecomeActiveNotification`. That means it works
  with plain dylib injection via **Scarlet / Sideloadly / TrollStore** on a
  non-jailbroken device — no jailbreak, no MobileSubstrate.
- **Scarlet install**: point Scarlet at your app + this `LuauConsoleTweak.dylib`
  and let it inject + re-sign. The filter plist (`LuauConsoleTweak.plist`) is
  only used by Substrate-based loaders; Scarlet injects the dylib directly, so
  the plist is harmless but unused in that path.
- **Compile time**: the first `make package` compiles the whole Luau VM
  (~100+ source files), so it takes a few minutes. Subsequent builds only
  recompile `Tweak.xm` / `LuauConsole.cpp`.
- **Wiring in real objects**: right now `game` / `workspace` are empty stubs.
  Extend `../src/LuauConsole.cpp` to expose your engine's actual scene objects.
