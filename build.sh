#!/bin/bash

# Variables
SRC_DIR="src"
SRC_EXT="*.c"			# *.c  *.cpp
TYPE="executable"		# executable/static
BUILD_DIR="build"
TARGET="test"
CXX="gcc"				# gcc  g++
CFLAGS="-Wall -I include"
LFLAGS=""

##############################################

OBJECT_FILES=()
REBUILD_TARGET=false

build_objects() {
	# Create build dir if not exists
	mkdir -p "$BUILD_DIR"

	# Seek and compile files
	while IFS= read -r SRC_FILE; do
		# Base name from source file.
		local REL_PATH=$(realpath --relative-to="$SRC_DIR" "$SRC_FILE")
		local OBJ_FILE="$BUILD_DIR/${REL_PATH%.cpp}.o"

		# Create directories for the file object if necessary
		mkdir -p "$(dirname "$OBJ_FILE")"

		# Add the object to array
		OBJECT_FILES+=("$OBJ_FILE")

		# Verify if compiling is needed
		if [[ ! -f "$OBJ_FILE" || "$SRC_FILE" -nt "$OBJ_FILE" ]]; then
			echo "Compiling $SRC_FILE..."
			$CXX $CFLAGS -c "$SRC_FILE" -o "$OBJ_FILE"
			REBUILD_TARGET=true
		fi
	done < <(find "$SRC_DIR" -type f -name "$SRC_EXT")
}

link_exec() {

	# Linking the objects
	# Verify the executable date.
	if [[ $REBUILD_TARGET == true || ! -f "$BUILD_DIR/$TARGET" ]]; then
		echo "Linking ..."
		$CXX "${OBJECT_FILES[@]}" -o "$BUILD_DIR/$TARGET" $LFLAGS
		echo "Build complete. Executable: $BUILD_DIR/$TARGET"
	else
		echo "Executable $BUILD_DIR/$TARGET is up to date."
	fi

}

link_static() {
    local LIB_FILE="$BUILD_DIR/lib$TARGET.a"
    if [[ $REBUILD_TARGET == true || ! -f "$LIB_FILE" ]]; then
        echo "Creating static library: $LIB_FILE..."
        ar rcs "$LIB_FILE" "${OBJECT_FILES[@]}"
        echo "Build complete: $LIB_FILE"
    else
        echo "Static library $LIB_FILE is up to date."
    fi
}

clean() {
	echo "Cleaning generated $BUILD_DIR ..."
	rm -rf "$BUILD_DIR"
}

# Sets the current directory
echo "Entering directory $(dirname "$0")."
pushd "$(dirname "$0")" > /dev/null

case "$1" in
	build|"" )
		build_objects

		if [[ "$TYPE" == "executable" ]]; then
			link_exec
		elif [[ "$TYPE" == "static" ]]; then
			link_static
		else
			echo "Error: Unknoun '$TYPE'. Expected 'executable' o 'static'."
		fi
        ;;
	clean )
        clean
        ;;
    * )
        echo "Usage: $0 [build|clean]"
        exit 1
        ;;

esac

# Back to the prev dir
echo "Leaving directory $(dirname "$0")"
printf '%*s\n' "$(tput cols)" '' | tr ' ' '-'
popd > /dev/null
