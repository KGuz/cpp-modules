cmake_minimum_required(VERSION 3.31)
project(example)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_compile_definitions(-D_LIBCPP_REMOVE_TRANSITIVE_INCLUDES)
add_compile_options(-fdiagnostics-color -pedantic-errors -Wall -Wextra -Wdeprecated -fno-exceptions -fexperimental-library -stdlib=libc++)
add_link_options(-fuse-ld=lld -stdlib=libc++ -Wl,--color-diagnostics -fdiagnostics-color -fexperimental-library)

# standard modules
set(MOD_BASE_DIR /usr/share/libc++/v1)
add_library(std_modules STATIC)
target_sources(std_modules PUBLIC FILE_SET std_modules TYPE CXX_MODULES BASE_DIRS ${MOD_BASE_DIR} FILES
    ${MOD_BASE_DIR}/std.cppm
    ${MOD_BASE_DIR}/std.compat.cppm
)
target_compile_options(std_modules PRIVATE -Wno-reserved-module-identifier -Wno-reserved-user-defined-literal)
link_libraries(std_modules)

# libraries
add_library(logger)
target_sources(logger PUBLIC FILE_SET CXX_MODULES FILES
    src/logger.cc
)

# executable
add_executable(main)
target_sources(main PRIVATE src/main.cc)
target_link_libraries(main PRIVATE logger)
