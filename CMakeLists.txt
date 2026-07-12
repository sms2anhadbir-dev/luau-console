cmake_minimum_required(VERSION 3.16)
project(LuauConsole CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# If your engine already vendors/links Luau elsewhere, skip this block and
# just target_link_libraries(luauconsole PUBLIC <your Luau targets>) instead.
include(FetchContent)
FetchContent_Declare(
    luau
    GIT_REPOSITORY https://github.com/luau-lang/luau.git
    GIT_TAG        master
)
FetchContent_MakeAvailable(luau)

add_library(luauconsole SHARED
    src/LuauConsole.cpp
)
target_include_directories(luauconsole PUBLIC include)
target_link_libraries(luauconsole PUBLIC Luau.Compiler Luau.VM)

add_executable(luauconsole_repl examples/console_main.cpp)
target_link_libraries(luauconsole_repl PRIVATE luauconsole)
