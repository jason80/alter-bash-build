# Alternative Build Script for C and C++
This bash script serves as a quick alternative to tools like Make and CMake.

![NEW](https://img.shields.io/badge/NEW-brightgreen) GNU gettext translation support ![NEW](https://img.shields.io/badge/NEW-brightgreen)

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
SRC_DIR="src"                  # Source code dir.
SRC_EXT="*.c"                  # *.c  *.cpp extensions.
TYPE="executable"              # "executable" target, "static" library or "shared" library.
BUILD_DIR="build"              # Target build directory.
TARGET="test"                  # Name of the executable or library.
CXX="gcc"                      # "gcc" or "g++" compiler selection.
CFLAGS="-Wall -I include"      # Compiler options.
LFLAGS=""                      # Linker options.
MODULE_DEPS=""                 # Module lib dependences.

# Translation
DOMAIN="$TARGET"
LOCALE_DIR="locales"
LANGUAGES="es fr it"           # space-separated list
POT_FILE="$DOMAIN.pot"
TRANSL_SRC_EXTRA=""            # Extra source files to translate (space-separated list)
```

## Running

Mark `build.sh` as executable using:

```bash
chmod +x build.sh
```
or
```bash
bash build.sh
```

You can create an alias
```bash
alias build='bash ./build.sh'
```

and run the script in the following ways:

* `./build.sh` or `./build.sh build`: build the project.
* `./build.sh clean`: clean the built files.
* `./build.sh run`: run the target (only executables).
* `./build.sh debug`: run the executable using the GDB debugger (only executables). *Note: The object files and the executable must include debugging information generated with the compiler's options.*
* `./build.sh translations` or
`./build.sh transl`: create or update gettext translation files.

## Static and Shared Libraries

Setting the option `TYPE="static"`, the script will generate a static library inside the `build/` directory.

Then: if `TARGET="Example"`, it will generate `libExample.a`

On the other hand, the option `TYPE="shared"` generates a shared library (.so).

## Dependencies

Only the translation files that have been modified compared to the compiled objects will be compiled. If any object is compiled, the target is relinked.

The script enables the compiler option to generate dependency files within the build directory. It then checks if they have been modified to regenerate the object.

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
TYPE="executable"		# Executable
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
./ExtendLib/build_1.sh $1
./main/build_2.sh $1
```

Consider `ExtendLib` and `main` as modules. `main` depends on `ExtendLib`. The following line makes the dependency more robust:

```bash
MODULE_DEPS="../ExtendLib/build/libExtendLib.a"
```

If anything in `ExtendLib` changes, the `main` target is rebuilt.

When using the `run` option, it checks if the target is available. It also recompiles if there are changes.

## Translations

The `translation` argument generates the file and directory structure for the project’s translation. You only need to list the languages separated by spaces. All the project’s source files will be included. Gettext must be properly configured, including both the domain and the strings to be read.

### Generated example if `LANGUAGE="es fr it"`:

- 📂 Project root
	- 📂 locales
		- 📂 es
			- 📂 LC_MESSAGES
				- 📄 test.mo
		- 📂 fr
			- 📂 LC_MESSAGES
				- 📄 test.mo
		- 📂 it
			- 📂 LC_MESSAGES
				- 📄 test.mo
	- 📂 po
		- 📄 es.po
		- 📄 fr.po
		- 📄 it.po
	- 📄 test.pot
	- 📄 **build.sh**


