#!/bin/bash

# nQuake2 Bash Installer Script v0.1 beta (for Linux)
# by Empezar

# Check if unzip is installed
unzip=`which unzip`
if [ "$unzip"  = "" ]
then
	echo "Unzip is not installed. Please install it and run the nQuake installation again."
	exit
fi

# Download function
error=false
function distdl {
	wget --inet4-only -O $file $1/$2
	if [ -s $2 ]
	then
			if [ "$(du $2 | cut -f1)" \> "0" ]
			then
					error=false
			else
					error=true
			fi
	else
			error=true
	fi
}

echo
echo Welcome to the nQuake2 v0.1 beta installation
echo =======================================
echo
echo Press ENTER to use [default] option.
echo

# Create the nQuake2 folder
defaultdir="~/nquake2"
read -p "Where do you want to install nQuake2? [$defaultdir]: " directory
if [ "$directory" = "" ]
then
        directory=$defaultdir
fi
eval directory=$directory
if [ -d "$directory" ]
then
	if [ -w "$directory" ]
	then
		created=false
	else
		echo;echo "Error: You do not have write access to $directory. Exiting."
		exit
	fi
else
	if [ -e "$directory" ]
	then
		echo;echo "Error: $directory already exists and is a file, not a directory. Exiting."
		exit
	else
		mkdir -p $directory 2> /dev/null
		created=true
	fi
fi
if [ -d "$directory" ] && [ -w "$directory" ]
then
	cd $directory
	directory=$(pwd)
else
	echo;echo "Error: You do not have write access to $directory. Exiting."
	exit
fi

# Ask for addons
ctf="n"
eraser="n"
textures="n"
read -p "Do you want to install the CTF addon? (y/n) [n]: " ctf
echo
read -p "Do you want to install the Eraser Bot addon? (y/n) [n]: " eraser
echo
read -p "Do you want to install the high resolution textures addon? (y/n) [n]: " textures
echo

# Search for pak0.pak
defaultsearchdir="~/"
pak=""
read -p "Do you want setup to search for pak0.pak? (y/n) [n]: " search
if [ "$search" = "y" ]
then
	read -p "Enter path to search for pak0.pak [$defaultsearchdir]: " path
	if [ "$path" = "" ]
	then
		path=$defaultsearchdir
	fi
	eval path=$path
	pak=$(echo $(find $path -type f -iname "pak0.pak" -size 176M -exec echo {} \; 2> /dev/null) | cut -d " " -f1)
	if [ "$pak" != "" ]
	then
		echo;echo "* Found at location $pak"
	else
		echo;echo "* Could not find pak0.pak"
	fi
fi
echo

# Download nquake2.ini
wget --inet4-only -q -O nquake2.ini http://nquake2.sourceforge.net/nquake2.ini
if [ -s "nquake2.ini" ]
then
	echo foo >> /dev/null
else
	echo "Error: Could not download nquake2.ini. Better luck next time. Exiting."
        if [ "$created" = true ]
        then
                cd
				read -p "The directory $directory is about to be removed, press Enter to confirm or CTRL+C to exit." remove
                rm -rf $directory
        fi
	exit
fi

# List all the available mirrors
echo "From what mirror would you like to download nQuake2?"
grep "[0-9]\{1,2\}=\".*" nquake2.ini | cut -d "\"" -f2 | nl
read -p "Enter mirror number [random]: " mirror
mirror=$(grep "^$mirror=[fhtp]\{3,4\}://[^ ]*$" nquake2.ini | cut -d "=" -f2)
if [ "$mirror" = "" ]
then
        echo;echo -n "* Using mirror: "
        RANGE=$(expr$(grep "[0-9]\{1,2\}=\".*" nquake2.ini | cut -d "\"" -f2 | nl | tail -n1 | cut -f1) + 1)
        while [ "$mirror" = "" ]
        do
                number=$RANDOM
                let "number %= $RANGE"
                mirror=$(grep "^$number=[fhtp]\{3,4\}://[^ ]*$" nquake2.ini | cut -d "=" -f2)
				mirrorname=$(grep "^$number=\".*" nquake2.ini | cut -d "\"" -f2)
        done
        echo "$mirrorname"
fi
mkdir -p baseq2
echo;echo

# Download all the packages
echo "=== Downloading ==="
distdl $mirror q2-314-demo-x86.zip
if [ "$error" == false ]
then
	distdl $mirror q2-3.20-x86-full_3.zip
fi
if [ "$error" == false ]
then
	distdl $mirror nquake2-gpl.zip
fi
if [ "$error" == false ]
then
	distdl $mirror nquake2-non-gpl.zip
fi
if [ "$error" == false ]
then
	if [ "$ctf" != "n" ]
	then
		distdl $mirror nquake2-addon-ctf.zip
	fi
fi
if [ "$error" == false ]
then
	if [ "$eraser" != "n" ]
	then
		distdl $mirror nquake2-addon-eraser.zip
	fi
fi
if [ "$error" == false ]
then
	if [ "$textures" != "n" ]
	then
		distdl $mirror nquake2-addon-textures.zip
	fi
fi

# Terminate installation if not all packages were downloaded
if [ "$error" == true ]
then
	echo "Error: Some distribution files failed to download. Better luck next time. Exiting."
	rm -rf $directory/q2-314-demo-x86.zip $directory/q2-3.20-x86-full_3.zip $directory/nquake2-gpl.zip $directory/nquake2-non-gpl.zip $directory/nquake2-addon-ctf.zip $directory/nquake2-addon-eraser.zip $directory/nquake2-addon-textures.zip
	if [ "$created" = true ]
	then
		cd
		read -p "The directory $directory is about to be removed, press Enter to confirm or CTRL+C to exit." remove
		rm -rf $directory
	fi
	exit
fi

# Extract all the packages
echo "=== Installing ==="
echo -n "* Extracting Quake 2 demo..."
unzip -qqo q2-314-demo-x86.zip Install/Data/baseq2/pak0.pak 2> /dev/null;echo "done"
echo -n "* Extracting Quake 2 v3.20 point release..."
unzip -qqo q2-3.20-x86-full_3.zip 2> /dev/null;echo "done"
echo -n "* Extracting nQuake setup files (2 of 2)..."
unzip -qqo non-gpl.zip 2> /dev/null;echo "done"
echo -n "* Extracting nQuake Linux files..."
unzip -qqo linux.zip 2> /dev/null;echo "done"
if [ "$pak" != "" ]
then
	echo -n "* Copying pak1.pak..."
	cp $pak $directory/id1/pak1.pak 2> /dev/null;echo "done"
	rm -rf $directory/id1/gpl-maps.pk3 $directory/id1/readme.txt
fi
echo

# Rename files
echo "=== Cleaning up ==="
echo -n "* Removing trash files..."
rm -rf "$directory\DOCS"
rm -rf "$directory\rogue"
rm -rf "$directory\xatrix"
rm "$directory\baseq2\maps.lst"
rm "$directory\3.20_Changes.txt"
rm "$directory\quake2.exe"
rm "$directory\ref_soft.dll"
rm "$directory\ref_gl.dll"
echo -n "* Renaming files..."
#mv $directory/ID1/PAK0.PAK $directory/id1/pak0.pak 2> /dev/null
#mv $directory/ezquake/sb/update_sources.bat $directory/ezquake/sb/update_sources
#rm -rf $directory/ID1
echo "done"

# Remove the Windows specific files
echo -n "* Removing Windows specific binaries..."
#rm -rf $directory/ezquake-gl.exe $directory/ezquake/sb/wget.exe
echo "done"

# Set architecture
echo -n "* Setting architecture..."
binary=`uname -i`
if [ "$binary" == "x86_64" ]
then
	#unzip -qqo $directory/x64.zip 2> /dev/null
else
    #unzip -qqo $directory/x86.zip 2> /dev/null
fi
echo "done"

# Remove distribution files
echo -n "* Removing distribution files..."
rm -rf $directory/q2-314-demo-x86.zip $directory/q2-3.20-x86-full_3.zip $directory/nquake2-gpl.zip $directory/nquake2-non-gpl.zip $directory/nquake2-addon-ctf.zip $directory/nquake2-addon-eraser.zip $directory/nquake2-addon-textures.zip
echo "done"

# Convert DOS files to UNIX
echo -n "* Converting DOS files to UNIX..."
#for file in $directory/readme.txt $directory/id1/readme.txt $directory/ezquake/cfg/* $directory/ezquake/configs/* $directory/ezquake/sb/* $directory/ezquake/gnu.txt
for file in $directory/*.txt
do
	if [ -f "$file" ]
	then
	        awk '{ sub("\r$", ""); print }' $file > /tmp/.nquake2.tmp
        	mv /tmp/.nquake2.tmp $file
	fi
done
echo "done"

# Set the correct permissions
echo -n "* Setting permissions..."
find $directory -type f -exec chmod -f 644 {} \;
find $directory -type d -exec chmod -f 755 {} \;
#chmod -f +x $directory/ezquake-gl.glx 2> /dev/null
echo "done"

# Create an install_dir in ~/.nquake detailing where nQuake is installed
mkdir -p ~/.nquake2
rm -rf ~/.nquake2/install_dir
echo $directory >> ~/.nquake2/install_dir

echo;echo "Installation complete. Happy gibbing!"