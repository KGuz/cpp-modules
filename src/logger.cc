module;
#include <unistd.h>

export module logger;
import std;

export namespace logger {

void log(std::string_view sv = "", std::source_location loc = std::source_location::current()) {
    auto filename = std::filesystem::path{loc.file_name()}.filename().c_str();
    std::println("{}:{} | tid:{} > {}", filename, loc.line(), ::gettid(), sv);
}

} // namespace logger
