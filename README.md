# Alternative Build Script for C and C++
This bash script serves as a quick alternative to tools like Make and CMake.

## Usage

For the following example project structure, simply copy the `build.sh` file.

- 📂 Project root
    - 📂 src
        - 📄 main.c
        - 📄 test.c
    - 📂 include
        - 📄 test.h
        - 📄 tools.h
    - 📄 **build.sh**

Then, simply modify the first lines of the script:

```bash
SRC_DIR="src"               # Source code dir.
SRC_EXT="*.c"		        # *.c  *.cpp extensions.
TYPE="executable"	        # "executable" or "static" library target.
BUILD_DIR="build"           # Target build directory.
TARGET="test"               # Name of the executable or library.
CXX="gcc"                   # "gcc" or "g++" compiler selection.
CFLAGS="-Wall -I include"   # Compiler options.
LFLAGS=""                   # Linker options.
```

## Running

Mark `build.sh` as executable using:

```bash
chmod +x build.sh
```

and run the script in the following ways:

* `./build.sh` or `./build.sh build`: build the project.
* `./build.sh clean`: clean the built files.

