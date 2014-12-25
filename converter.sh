#!/bin/bash

# Author: Joel Holder
# Description: Does the following things:
#				1. recursively opens files that match filter and replaces $search with $replace in content.  
#				2. recursively renames files that match filter by replacing $search with $replace in file name.
# Example Usage: converter.sh "./Dir" "*.txt" "foo" "bar"
#
# Dev: Basecases -GNU find one liners
#	find . -type f -exec sed -i 's/FOO/BAR/g;s/$/\r/g' {} +
#	find . -name '*-FOO-*' -exec bash -c 'mv $0 ${0/FOO/BAR}' {} +
# Note On Scoping:
#   use + for all files
#   use \; for first file


replace_content() {

    dir=$1
	search=$2
	replace=$3

	# ReAdd Windows line endings if we're in Windows
	# os=$(uname -a)
	# if [[ $os == *"CYGWIN_NT"* ]]
	# then
	#   winEOL=';s/$/\r/g'
	# fi

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

	dir=$1
	search=$2
	replace=$3

	for file in $(find $dir -name "*" | sort -r)
	do
		renamedFile=$(echo $file | sed -e 's/'$search'/'$replace'/g')
		echo "file: "$file

	 	fileDir=$(dirname $renamedFile)
	 	if [ ! -d "$fileDir" ]; then
	 		echo "fileDir: "$fileDir
	 		mkdir -p $fileDir
	 	fi
	 	
	 	if [ "$file" != "$renamedFile" ]; then
			
			#remove and pass over this iteration if its a renamed empty directory
			if [ ! "$(ls -A $file)" ]; then
				 if [ -d "$file" ]; then
				 	if grep -q "$search" <<<$file; then
				 		rm -rf $file
			     		continue
			     	fi
			     fi
			fi
	 		
	 		mv "$file" "$renamedFile"
	 	fi
	done

}

backup_directory() {
	set +e 

	dir=$1
	archive_file=archive-$(date +%s).tar.gz
	tar -czvf $archive_file $dir --exclude="$archive_file" --ignore-failed-read

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
   ! isDosFile $1
}

#RUN

dir=$1
search=$2
replace=$3

filter='*' #hard time with this because star is expanding to files list before getting passed into main script.  Needs to be this on cli: '*'

##example
#dir="./Dir"
#filter='*.txt'
#search="foo"
#replace="bar"

if [[ -z "$dir" ]] || [[ -z "$search" ]] || [[ -z "$replace" ]]; then
	  echo ""
	  echo "ERROR: pass in all required variables"
      echo "usage: " $0 "directory" "filter" "search" "replace"
	  echo ""
	  exit
fi

#backup and run
backup_directory $dir
if [ $? -eq 0 ]; then
    echo "Backup succeeded"
    rename_files $dir $search $replace
    replace_content $dir $search $replace
else
    echo "Backup failed"
fi
