ARCHS = arm64
TARGET = iphone:14.5:14.5

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LuauConsoleTweak

# Tweak logic + our C++ console bindings
LuauConsoleTweak_FILES = Tweak.xm ../src/LuauConsole.cpp

# Luau VM + Compiler + Ast + Bytecode source files (populated by fetch-luau.sh)
LuauConsoleTweak_FILES += $(wildcard luau/VM/src/*.cpp)
LuauConsoleTweak_FILES += $(wildcard luau/Compiler/src/*.cpp)
LuauConsoleTweak_FILES += $(wildcard luau/Ast/src/*.cpp)
LuauConsoleTweak_FILES += $(wildcard luau/Bytecode/src/*.cpp)

# -fno-modules: the L1ghtmann toolchain's libc++ ships as Clang modules whose
# __config_site header isn't resolvable when cross-compiling here; forcing
# textual includes avoids the "could not build module 'std_*'" wall of errors.
LuauConsoleTweak_CFLAGS  = -fobjc-arc -I../include -fno-modules
LuauConsoleTweak_CCFLAGS = -std=c++17 -fno-modules
LuauConsoleTweak_CFLAGS += -Iluau/VM/include -Iluau/VM/src
LuauConsoleTweak_CFLAGS += -Iluau/Compiler/include -Iluau/Compiler/src
LuauConsoleTweak_CFLAGS += -Iluau/Ast/include -Iluau/Ast/src
LuauConsoleTweak_CFLAGS += -Iluau/Bytecode/include -Iluau/Bytecode/src
LuauConsoleTweak_CFLAGS += -Iluau/Common/include

# libc++'s __config includes <__config_site>, which lives in the toolchain's
# target-specific include dir that the arm64-apple-ios cross-compile doesn't
# search by default. Add it explicitly.
LuauConsoleTweak_CFLAGS += -I$(THEOS)/toolchain/linux/iphone/include/x86_64-unknown-linux-gnu/c++/v1

LuauConsoleTweak_FRAMEWORKS = UIKit Foundation QuartzCore

include $(THEOS)/makefiles/tweak.mk
