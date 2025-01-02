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
SRC_DIR="src"				# Source code dir.
SRC_EXT="*.c"				# *.c  *.cpp extensions.
TYPE="executable"			# "executable" or "static" library target.
BUILD_DIR="build"			# Target build directory.
TARGET="test"				# Name of the executable or library.
CXX="gcc"					# "gcc" or "g++" compiler selection.
CFLAGS="-Wall -I include"	# Compiler options.
LFLAGS=""					# Linker options.
MODULE_DEPS=""				# Module lib dependences.
```

## Running

Mark `build.sh` as executable using:

```bash
chmod +x build.sh
```

and run the script in the following ways:

* `./build.sh` or `./build.sh build`: build the project.
* `./build.sh clean`: clean the built files.

## Static Libraries

Setting the option `TYPE="static"`, the script will generate a static library inside the `build/` directory.

Then: if `target="Example"`, it will generate `libExample.a`

## Modules

Projects can be created with modules as follows:

- 📂 Project root
	- 📂 ExtendLib
		- 📂 src
			- 📄 utils.cpp
		- 📂 include
			- 📄 utils.h
		- 📄 **build_1.sh**

	- 📂 main
		- 📂 src
			- 📄 main.cpp
		- 📄 **build_2.sh**
	- 📄 **build.sh**

### build_1.sh (lib):
```bash
SRC_DIR="src"
SRC_EXT="*.cpp"
TYPE="static"			# Static library
BUILD_DIR="build"
TARGET="ExtendLib"		# Generates: "build/libExtendLib.a"
CXX="g++"
CFLAGS="-Wall -I include"
LFLAGS=""
MODULE_DEPS=""
```

### build_2.sh (main module):
```bash
SRC_DIR="src"
SRC_EXT="*.cpp"
TYPE="executable"		# Static library
BUILD_DIR="build"
TARGET="test"			# Executable name
CXX="g++"
CFLAGS="-Wall -I include -I ../ExtendLib/include"	# Compiler options
LFLAGS="-L ../ExtendLib/build -l ExtendLib"			# Linker options
MODULE_DEPS="../ExtendLib/build/libExtendLib.a"		# Add module dependence to rebuild project
```

### build.sh (simple root build script):
```bash
#!/bin/bash
./ExtendLib/build_1.sh
./main/build_2.sh
```

Consider `ExtendLib` and `main` as modules. `main` depends on `ExtendLib`. The following line makes the dependency more robust:

```bash
MODULE_DEPS="../ExtendLib/build/libExtendLib.a"
```

If anything in `ExtendLib` changes, the `main` target is rebuilt.
