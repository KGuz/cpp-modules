#!/usr/bin/env bash

CMAKE_VERSION=3.31.6
CLANG_VERSION=19
GCC_VERSION=14

function install-clang {
    wget https://apt.llvm.org/llvm.sh;
    chmod +x llvm.sh;

    sudo ./llvm.sh ${CLANG_VERSION} all;

    sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${CLANG_VERSION} 100;
    sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_VERSION} 100;

    sudo update-alternatives --install /usr/bin/cc cc /usr/bin/clang-${CLANG_VERSION} 100;
    sudo update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-${CLANG_VERSION} 100;

    rm ./llvm.sh;
}

function set-clang {
    sudo update-alternatives --set clang /usr/bin/clang-${CLANG_VERSION};
    sudo update-alternatives --set clang++ /usr/bin/clang++-${CLANG_VERSION};

    sudo update-alternatives --set cc /usr/bin/clang-${CLANG_VERSION};
    sudo update-alternatives --set c++ /usr/bin/clang++-${CLANG_VERSION};
}

function install-gcc {
    sudo apt install software-properties-common -y;
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y;
    sudo apt update;

    sudo apt install gcc-${GCC_VERSION} g++-${GCC_VERSION} -y;

    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 100;
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 100;

    sudo update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-${GCC_VERSION} 100;
    sudo update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-${GCC_VERSION} 100;
}

function set-gcc {
    sudo update-alternatives --set gcc /usr/bin/gcc-${GCC_VERSION};
    sudo update-alternatives --set g++ /usr/bin/g++-${GCC_VERSION};

    sudo update-alternatives --set cc /usr/bin/gcc-${GCC_VERSION};
    sudo update-alternatives --set c++ /usr/bin/g++-${GCC_VERSION};
}

function install-cmake {
    wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh;
    chmod +x cmake-${CMAKE_VERSION}-linux-x86_64.sh;

    sudo mkdir -p /opt/cmake-${CMAKE_VERSION}-linux-x86_64;
    sudo ./cmake-${CMAKE_VERSION}-linux-x86_64.sh --skip-license --prefix=/opt/cmake-${CMAKE_VERSION}-linux-x86_64/;
    sudo ln -sfn /opt/cmake-${CMAKE_VERSION}-linux-x86_64/bin/* /usr/local/bin;

    rm cmake-${CMAKE_VERSION}-linux-x86_64.sh;
}

function install-ninja {
    sudo apt install ninja-build -y;
}

function install-clang-fmt {
    sudo apt install clang-format-${CLANG_VERSION} -y;

    sudo update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-${CLANG_VERSION} 100;
    sudo update-alternatives --set clang-format /usr/bin/clang-format-${CLANG_VERSION};
}

function install-clang-lsp {
    sudo apt install clangd-${CLANG_VERSION} -y;
    
    sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-${CLANG_VERSION} 100;
    sudo update-alternatives --set clangd /usr/bin/clangd-${CLANG_VERSION};
}

function install-gtest {
    sudo apt-get install libgtest-dev -y;

    cd /usr/src/gtest;

    sudo cmake CMakeLists.txt;
    sudo make;

    sudo cp ./lib/libgtest*.a /usr/lib;

    sudo mkdir -p /usr/local/lib/gtest;
    sudo ln -sfn /usr/lib/libgtest.a /usr/local/lib/gtest/libgtest.a;
    sudo ln -sfn /usr/lib/libgtest_main.a /usr/local/lib/gtest/libgtest_main.a;

    cd -;
}

function setup-lsp {
    settings='{
    "clangd.path": "/usr/bin/clangd",
    "clangd.arguments": [
        "--background-index", 
        "--compile-commands-dir=${workspaceFolder}/build/compile_commands.json"
    ],
    "clangd.fallbackFlags": [ 
        "-std=c++23",
        "-I${workspaceFolder}/src",
    ]
}';
    mkdir -p ./.vscode && (cd ./.vscode && echo "$settings" > settings.json);
}

function precompile-std-modules {
    clang++ -std=c++23 -stdlib=libc++ -Wno-reserved-module-identifier --precompile -o std.pcm /usr/lib/llvm-${CLANG_VERSION}/share/libc++/v1/std.cppm;
    
    sudo mkdir -p /usr/share/libc++;
    sudo ln -s /usr/lib/llvm-${CLANG_VERSION}/share/libc++/v1 /usr/share/libc++/v1;
}

function prepare {
    sudo apt-get update && sudo apt-get install build-essential -y;
    install-cmake;    
    install-gtest;
    install-gcc;
    install-clang;
    install-clang-fmt;
    install-clang-lsp;
    setup-lsp;
    set-clang;
    precompile-std-modules;
}

function build {
    mkdir -p ./build && (cd ./build && cmake .. -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -GNinja && ninja -j$(nproc));
}

function rebuild {
    rm -rf ./build && build;
}

function run {
    if [[ $# -eq 0 ]]; then echo "missing target executable"
    else build && ./build/$1 "${@:1}";
    fi
}

function format {
    [[ -f ".clang-format" ]] || clang-format-${CLANG_VERSION} -style=llvm -dump-config > .clang-format
    find src/ -iname *.hh -o -iname *.cc | xargs clang-format-${CLANG_VERSION} -i -style=file:.clang-format --sort-includes --verbose 
}

function deactivate {
    export PS1=${PS1/"(dev) "/}
    unset -f install-clang set-clang install-gcc set-gcc install-cmake install-ninja install-clang-fmt install-clang-lsp install-gtest setup-lsp precompile-std-modules prepare build rebuild run format deactivate
}

export PS1="(dev) $PS1"