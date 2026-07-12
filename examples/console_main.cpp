// Minimal stdin REPL demonstrating LuauConsole as a standalone runner.
// In your engine, drive Execute() from your dev-console UI instead of stdin.
#include <iostream>
#include <string>

#include "LuauConsole.h"

int main() {
    LuauConsole console;
    console.SetOutputCallback([](const std::string& message, bool isError) {
        std::ostream& out = isError ? std::cerr : std::cout;
        out << (isError ? "[error] " : "") << message << std::endl;
    });

    // Example of wiring a real engine subsystem in as a service:
    //   Players playersService;
    //   console.RegisterService("Players", playersService);

    std::cout << "Luau console. Type Luau code, blank line to run, 'exit' to quit.\n";
    std::string buffer;
    std::string line;
    while (true) {
        std::cout << (buffer.empty() ? "> " : ">> ");
        if (!std::getline(std::cin, line)) break;
        if (buffer.empty() && line == "exit") break;

        if (line.empty()) {
            if (!buffer.empty()) {
                console.Execute(buffer, "repl");
                buffer.clear();
            }
            continue;
        }
        buffer += line;
        buffer += "\n";
    }

    return 0;
}
