#!/bin/sh

# Part of the Arduino project
# http://arduino.berlios.de
#
# this is derived from the processing project
# http://www.processing.org
#
# This file is subjected to the GPL License
#

### -- SETUP WORK DIR -------------------------------------------

if test -d work 
then
  BUILD_PREPROC=false
else
  BUILD_PREPROC=true

  # needs to make the dir because of packaging goofiness
  echo Setting up directories to build under Mac OS X
  mkdir -p work/classes/processing/app/preproc
  mkdir -p work/classes/processing/app/syntax
  mkdir -p work/classes/processing/app/tools
  mkdir -p work/lib/build

  # to have a copy of this guy around for messing with
  echo Copying Arduino.app...

  cp -pR dist/Arduino.app work/
  # cvs doesn't seem to want to honor the +x bit 
  chmod +x work/Arduino.app/Contents/MacOS/JavaApplicationStub
  
  # copy the avr-gcc distribution
  echo Copying tools \(this may take a minute\)...
  cp -pR dist/tools.zip work/
  cd work
  unzip -oq tools.zip
  rm tools.zip
  cd ..

  # get jikes and depedencies
  echo Copying jikes...
  cp dist/jikes work/
  chmod +x work/jikes
fi

echo Copying shared and core files...
cp -r ../shared/* work
cp -r ../../core work

echo Copying dist files...
cp -r dist/lib work/
cp -r dist/core work/

### -- START BUILDING -------------------------------------------

# move to root 'arduino' directory
cd ../..


### -- BUILD GCC ------------------------------------------------
# in the future we will build avr-gcc and tools (if they don't exist)

### -- BUILD JAVA -----------------------------------------------

# set classpath
CLASSPATH=/System/Library/Frameworks/JavaVM.framework/Classes/classes.jar:/System/Library/Frameworks/JavaVM.framework/Classes/ui.jar:/System/Library/Java/Extensions/MRJToolkit.jar
export CLASSPATH

cd app

### -- BUILD PARSER ---------------------------------------------

#BUILD_PREPROC=true

if $BUILD_PREPROC
then
  cd preproc
  # build classes/grammar for preprocessor
  echo Building antlr grammar code...
  # first build the default java goop
  java -cp ../../build/macosx/work/lib/antlr.jar antlr.Tool java.g
  # now build the pde stuff that extends the java classes
  java -cp ../../build/macosx/work/lib/antlr.jar antlr.Tool -glib java.g pde.g
  cd ..
fi

### -- BUILD PDE ------------------------------------------------

echo Building the PDE...

# compile the code as java 1.3, so that the application will run and
# show the user an error, rather than crapping out with some strange
# "class not found" crap
../build/macosx/work/jikes -target 1.3 +D -classpath ../build/macosx/work/classes:../build/macosx/work/lib/antlr.jar:../build/macosx/work/lib/oro.jar:../build/macosx/work/lib/registry.jar:../build/macosx/work/lib/RXTXcomm.jar:$CLASSPATH -d ../build/macosx/work/classes tools/*.java preproc/*.java syntax/*.java *.java 

cd ../build/macosx/work/classes
rm -f ../lib/pde.jar
zip -0rq ../lib/pde.jar .
cd ../..

# get the libs
mkdir -p work/Arduino.app/Contents/Resources/Java/
cp work/lib/*.jar work/Arduino.app/Contents/Resources/Java/

echo
echo Done.