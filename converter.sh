#!/bin/bash

# Author: Joel Holder
# Description:  
#				This script can be used to make filesystem changes changes on mass.  It will drill through directory heirarchies and modify names and content.
#
#				Does the following things:
#				1. recursively opens all text files in a directory and replaces $search with $replace in content.  
#				2. recursively renames files in a directory by replacing $search with $replace in file and directory names.
#
# Example Usage: converter.sh "./project" "foo" "bar"
#
# Note On Scoping with find:
#   use + for all files
#   use \; for first file


replace_content() {

    dir=$1
	search=$2
	replace=$3

	# ReAdd Windows line endings if we're in Windows
	os=$(uname -a)
	if [[ $os == *"CYGWIN_NT"* ]]
	then
	  winEOL=';s/$/\r/g'
	fi

	echo 'dir: '$dir
	echo 'search: '$search
	echo 'replace: '$replace

	#unix only line endings
	find $dir -name '*' -type f -print | xargs file | grep -i 'ASCII\|UNICODE' | cut -d: -f1 | xargs sed -i "s/$search/$replace/g"
	
	
	#windows only line endings
	#find $dir -name "$filter" -type f -print | xargs file | grep -i 'ASCII\|UNICODE' | cut -d: -f1 | xargs sed -i "s/$search/$replace/g"$winEOL 
	
	
	#conditional discovery of line-ending type
	#find $dir -name "*" -type f -print | xargs file | grep -i 'ASCII\|UNICODE' | cut -d: -f1 | { read file; if isDosFile $file; then echo $file; fi } | xargs sed -i "s/$search/$replace/g"$winEOL # | { read blah; echo $blah; } 
	#find $dir -name "*" -type f -print | xargs file | grep -i 'ASCII\|UNICODE' | cut -d: -f1 | { read file; if isNixFile $file; then echo $file; fi } | xargs sed -i "s/$search/$replace/g" # | { read blah; echo $blah; } 
		
}


rename_files() {

	startDir=$1
	search=$2
	replace=$3

	#todo: combine these

	#rename the directories, ensuring folders are ready for files
	for dir in $(find $startDir -name '*' -type d)
	do
		renamedDir=$(echo $dir | sed -e 's/'$search'/'$replace'/g')

		if [ "$dir" != "$renamedDir" ]; then
	 		if [[ ! -e $renamedDir ]]; then
			    rename $search $replace $dir
			fi
	 	fi
	done



	#rename the files
	for file in $(find $startDir -name '*' -type f)
	do
		renamedFile=$(echo $file | sed -e 's/'$search'/'$replace'/g')
	 	if [ "$file" != "$renamedFile" ]; then
	 		rename $search $replace $file
	 	fi
	done

	

}

backup_directory() {
	set +e 

	dir=$1
	archive_file=archive-$(date +%s).tar.gz
	tar -czf $archive_file $dir --exclude="$archive_file" --ignore-failed-read

	exitcode=$?

	if [ "$exitcode" != "1" ] && [ "$exitcode" != "0" ]; then
	    exit $exitcode
	fi
	set -e  
}

isDosFile() {
    [[ $(file $1) =~ CRLF ]] 
}

isNixFile() {
   return ! isDosFile $1
}

#RUN

dir=$1
search=$2
replace=$3

#filter='*' #hard time with this because star is expanding to files list before getting passed into main script.  Needs to be this on cli: '*'

##example
#dir="./Dir"
#filter='*.txt'
#search="foo"
#replace="bar"

if [[ -z "$dir" ]] || [[ -z "$search" ]] || [[ -z "$replace" ]]; then
	  echo ""
	  echo "ERROR: pass in all required variables"
      echo "usage: " $0 "directory" "search" "replace"
	  echo ""
	  exit
fi

#backup and run
backup_directory $dir
if [ $? -eq 0 ]; then
    echo "Backup succeeded"
    replace_content $dir $search $replace
    rename_files $dir $search $replace
else
    echo "Backup failed"
fi
