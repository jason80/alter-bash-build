#!/bin/bash

# Variables
SRC_DIR="src"
SRC_EXT="*.cpp"				# *.c  *.cpp
TYPE="executable"			# executable/static/shared
BUILD_DIR="build"
TARGET="main"
CXX="g++"					# gcc  g++
CFLAGS="-Wall -I include"
LFLAGS=""
MODULE_DEPS=""

# Translation
DOMAIN="$TARGET"
LOCALE_DIR="locales"
LANGUAGES="es fr it"        # space-separated list
POT_FILE="$DOMAIN.pot"
TRANSL_SRC_EXTRA="build.sh"			# Extra source files to translate (space-separated list)

##############################################
#Internals:

XGETTEXT='xgettext --keyword=_ -d $DOMAIN -o $POT_FILE $ALL_SRC_FILES'
MSGINIT='msginit -l $LANG -i $POT_FILE -o $PO_FILE --no-translator'
MSGMERGE='msgmerge --update $PO_FILE $POT_FILE'

##############################################

OBJECT_FILES=()
REBUILD_TARGET=false
BUILD_ERROR=false

CFLAGS="-MD $CFLAGS"

build_objects() {
	# Create build dir if not exists
	mkdir -p "$BUILD_DIR"

	# Seek and compile files
	while IFS= read -r SRC_FILE; do
		# Base name from source file.
		local REL_PATH=$(realpath --relative-to="$SRC_DIR" "$SRC_FILE")
		local OBJ_FILE="$BUILD_DIR/${REL_PATH%.cpp}.o"
		local DEP_FILE="${OBJ_FILE%.o}.d"

		# Create directories for the file object if necessary
		mkdir -p "$(dirname "$OBJ_FILE")"

		# Add the object to array
		OBJECT_FILES+=("$OBJ_FILE")

		# Verify if compiling is needed
		if [[ ! -f "$OBJ_FILE" || "$SRC_FILE" -nt "$OBJ_FILE" ]]; then
			echo "Compiling $SRC_FILE..."
			$CXX $CFLAGS -c "$SRC_FILE" -o "$OBJ_FILE"

			# Check error
			if [[ $? -ne 0 ]]; then
				BUILD_ERROR=true
			fi

			REBUILD_TARGET=true
		elif [[ -f "$DEP_FILE" ]]; then

    		local DEPENDENCIES=$(sed ':a;N;$!ba;s/\\\n//g' "$DEP_FILE" | awk '{$1=""; sub(/^ /, ""); print}' | tr ' ' '\n')

			for DEP in $DEPENDENCIES; do
				if [[ -f "$DEP" && "$DEP" -nt "$OBJ_FILE" ]]; then
					echo "Recompiling $SRC_FILE due to changes in $DEP..."
					$CXX $CFLAGS -c "$SRC_FILE" -o "$OBJ_FILE"

					# Check error
					if [[ $? -ne 0 ]]; then
						BUILD_ERROR=true
					fi

					REBUILD_TARGET=true
					break
				fi
			done
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

link_shared() {
	# Crear una biblioteca compartida
	local LIB_FILE="$BUILD_DIR/lib$TARGET.so"
	if [[ $REBUILD_TARGET == true || ! -f "$LIB_FILE" ]]; then
		echo "Creating shared library: $LIB_FILE..."
		$CXX -shared "${OBJECT_FILES[@]}" -o "$LIB_FILE" $LFLAGS
		echo "Build complete: $LIB_FILE"
	else
		echo "Shared library $LIB_FILE is up to date."
	fi
}

clean() {
	echo "Cleaning generated $BUILD_DIR ..."
	rm -rf "$BUILD_DIR"
}

check_libraries() {
	for LIB in $MODULE_DEPS; do
		if [[ -f "$LIB" && "$LIB" -nt "$BUILD_DIR/$TARGET" ]]; then
			echo "Library $LIB has been updated. Relinking required."
			REBUILD_TARGET=true
			return
		fi
	done
}

build_target() {
	build_objects

	if [[ $BUILD_ERROR == true ]]; then
		echo "Build process stopped due to compilation errors."
        exit 1
	fi

	check_libraries

	if [[ "$TYPE" == "executable" ]]; then
		link_exec
	elif [[ "$TYPE" == "static" ]]; then
		link_static
	elif [[ "$TYPE" == "shared" ]]; then
		link_shared
	else
		echo "Error: Unknoun '$TYPE'. Expected 'executable', 'static' or 'shared'."
	fi
}

build_translations() {
    echo "Running build_translations ..."

    # Remove the wildcard (*.) to extract the extension (e.g. c from *.c)
    EXT="${SRC_EXT#*.}"

    # Find all source files matching the extension
    SRC_FILES=$(find "$SRC_DIR" -type f -name "*.${EXT}")

    # Append extra translation sources
    ALL_SRC_FILES="$SRC_FILES $TRANSL_SRC_EXTRA"

    # Remove leading/trailing spaces
    ALL_SRC_FILES=$(echo "$ALL_SRC_FILES" | xargs)

    if [[ -z "$ALL_SRC_FILES" ]]; then
        echo "No source files found for translation."
        return
    fi

    # Determine if POT needs to be updated
    local regenerate_pot=false
    if [[ ! -f "$POT_FILE" ]]; then
        regenerate_pot=true
    else
        for SRC in $ALL_SRC_FILES; do
            if [[ -f "$SRC" && "$SRC" -nt "$POT_FILE" ]]; then
                regenerate_pot=true
                break
            fi
        done
    fi

    if [[ "$regenerate_pot" == true ]]; then
        echo "Generating updated POT file..."
        eval $XGETTEXT
    else
        echo "POT file $POT_FILE is up to date."
    fi

    for LANG in $LANGUAGES; do
        local PO_FILE="po/${LANG}.po"
        local MO_FILE="$LOCALE_DIR/$LANG/LC_MESSAGES/$DOMAIN.mo"

        if [[ ! -f "$PO_FILE" ]]; then
            echo "Creating new PO file for language $LANG..."
            mkdir -p "$(dirname "$PO_FILE")"
            eval $MSGINIT
        else
            if [[ "$POT_FILE" -nt "$PO_FILE" ]]; then
                echo "Merging changes into $PO_FILE..."
                eval $MSGMERGE
            else
                echo "PO file $PO_FILE is up to date."
            fi
        fi

        echo "Generating MO file for $LANG..."
        mkdir -p "$(dirname "$MO_FILE")"
        msgfmt "$PO_FILE" -o "$MO_FILE"
    done
}


# Sets the current directory
echo "Entering directory [$(dirname "$0")]"
pushd "$(dirname "$0")" > /dev/null

case "$1" in
	build|"" )
		build_target
		;;
	clean )
		clean
		;;
	run )
		build_target
		if [[ "$TYPE" == "executable" ]]; then
			echo "Running $BUILD_DIR/$TARGET ..."
			"./$BUILD_DIR/$TARGET"
		fi
		;;
	debug )
		build_target
		if [[ "$TYPE" == "executable" ]]; then
			echo "Running $BUILD_DIR/$TARGET in debug mode ..."
			gdb "./$BUILD_DIR/$TARGET"
		fi
		;;
	translations|transl )
        build_translations
        ;;
	* )
		echo "Usage: $0 [build|clean|run|debug|translations|transl]"
		exit 1
		;;

esac

# Back to the prev dir
echo "Leaving directory [$(dirname "$0")]"
printf '%*s\n' "$(tput cols)" '' | tr ' ' '-'
popd > /dev/null
