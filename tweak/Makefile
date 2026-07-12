ARCHS = arm64
TARGET = iphone:14.5:14.5

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LuauConsoleTweak

# Tweak logic + our C++ console bindings
LuauConsoleTweak_FILES = Tweak.xm ../src/LuauConsole.cpp

# Luau VM + Compiler + Ast source files (populated by fetch-luau.sh)
LuauConsoleTweak_FILES += $(wildcard luau/VM/src/*.cpp)
LuauConsoleTweak_FILES += $(wildcard luau/Compiler/src/*.cpp)
LuauConsoleTweak_FILES += $(wildcard luau/Ast/src/*.cpp)

LuauConsoleTweak_CFLAGS  = -fobjc-arc -I../include
LuauConsoleTweak_CCFLAGS = -std=c++17
LuauConsoleTweak_CFLAGS += -Iluau/VM/include -Iluau/VM/src
LuauConsoleTweak_CFLAGS += -Iluau/Compiler/include -Iluau/Compiler/src
LuauConsoleTweak_CFLAGS += -Iluau/Ast/include -Iluau/Ast/src
LuauConsoleTweak_CFLAGS += -Iluau/Common/include

LuauConsoleTweak_FRAMEWORKS = UIKit Foundation QuartzCore

include $(THEOS)/makefiles/tweak.mk
