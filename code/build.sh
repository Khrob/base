#!/bin/sh

echo
echo "Building Base"

SOURCES="macos_layer.swift main.swift"
OUTFOLDER="../build"
OUTPUT="$OUTFOLDER/base"
FLAGS=""
COMMAND="swiftc $FLAGS $SOURCES -o $OUTPUT"

mkdir $OUTFOLDER > /dev/null 2>&1

rm $OUTPUT > /dev/null 2>&1

echo
echo "Building executable..."

TIMEFORMAT=%R
COMPILE_TIME=$(time $($COMMAND) 2>&1) 
unset TIMEFORMAT

if [ -e $OUTPUT ]; then 
	echo "Build completed in $COMPILE_TIME seconds"
	echo "$(date), $COMPILE_TIME" >> $OUTFOLDER/buildtimes
	echo "Running executable." 
	$OUTPUT
else 
	echo "Build failed." 
fi

echo
echo
