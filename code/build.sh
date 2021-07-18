#!/bin/sh

echo
echo "Building Base"

# Editable bits here
SOURCES="macos_layer.swift main.swift"
OUTFOLDER="../build"
OUTPUT="$OUTFOLDER/base"
FLAGS=""
COMMAND="swiftc $FLAGS $SOURCES -o $OUTPUT"

# Make the output folder if it doesn't exist
mkdir $OUTFOLDER > /dev/null 2>&1

# Delete the old build
rm $OUTPUT > /dev/null 2>&1

echo
echo "Building executable..."

# Perform and time the build
TIMEFORMAT=%R
COMPILE_TIME_OR_ERROR=$((time $($COMMAND)) 2>&1)
unset TIMEFORMAT

# Record the time if we were successful...
if [ -e $OUTPUT ]; then 
	echo "Build completed in $COMPILE_TIME_OR_ERROR seconds"
	echo "$(date), $COMPILE_TIME_OR_ERROR" >> $OUTFOLDER/buildtimes
	echo "Running executable." 
	$OUTPUT

# ...or show the compile errors if we weren't.
# TODO (khrob): Somehow preserve the colouring of this?
else 
	echo 
	echo "Build failed:"
	echo
	echo $COMPILE_TIME_OR_ERROR 
fi

echo
echo
