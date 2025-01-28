#!/bin/bash

clear;
#Defines variable that holds file to be modified
file='';
#Defines variable that will determine whether or not the final modified file with be saved to disk
save='false';
#Defines function which checks for the existence of a file or string
existence_check(){
if [ "$2" == '' ];
then
	echo "File $file does not exist! Exitting.";
	exit;
else
	testValue="$2";
fi
exists=0;
while [ "$exists" -eq 0 ];
do 
	if  [ "$1" == "file"  ];
	then
		if [ -e "$testValue"  ];
		then
			exists=1;	
			file="$testValue";
		fi
	elif [ "$1" == "string"  ];
	then
		if [ "$(grep -wc "$testValue" "$file")"  -gt 0 ];
		then
			exists=1;
			trigger_strings+=("$testValue")
		fi	
	fi
	if [ "$exists" -eq 0  ];
		then
			echo -e "\n$testValue doees not exist please re-enter value."
			read -r testValue;
		fi
done	
}
#Defines function that requires the user to input a yes or no answer
yesORno(){
while [[ "${answer,,}" != "no" ]] && [[  "${answer,,}" != "yes" ]] ;
do 
	read -r answer
	if [ "$(echo "$answer" | cut -b1)" == 'n' ];
	then
		answer='no';
	else
		answer='yes';
	fi
	if [[ "${answer,,}" != "no" ]] && [[  "${answer,,}" != "yes" ]];
	then
		echo -e "\nPlease enter 'yes' or 'no'."
	fi
done
}
#Defines arrays that hold trigger strings and user strings
trigger_strings=();
user_strings=();
while getopts 'f:t:s:S:h' OPTION; do
	case "$OPTION" in
		f)
			#Defines name of file to be modified
			file="$OPTARG";
			;;	
		t)
			#Defines trigger strings that will habe user strings added below them
			triggerCount="$(echo "$OPTARG" | wc -w)";
			#Checks if trigger string is empty
			if [ "$triggerCount" -eq 0  ];
			then
				echo "Trigger string cannot be empty! Exitting.";
				exit;
			fi
			#Adds trigger strings to trigger_strings array
			i=1;
			while [[ "${#trigger_strings[@]}" -lt "$triggerCount" ]];
			do
				existence_check string "$(echo "$OPTARG" | cut -d ' ' -f"$i")";
				i=$((i + 1));
			done
			;;
		s)
			#Defines user strings to be added below trigger strings
			stringCount="$(echo "$OPTARG" | wc -w)";
			#Checks if user string ammount are equal to trigger string ammount
			if [ "$triggerCount" != "$stringCount" ]; 
			then
				echo "Must have same ammount of strings as triggers! Exitting.";
				exit;
			fi
			#Adds user strings to user_strings array
			i=1;
			while [[ "${#user_strings[@]}" -lt "$triggerCount" ]];
			do
				userString="$(echo "$OPTARG" | cut -d ' ' -f"$i")";
				if [ "$userString" == '' ];
				then
					userString=$'\n';
				fi
				user_strings+=("$userString");
				i=$((i + 1));
			done
			;;
		S)
			#Defines whether or not to save modified file to disk
			save='true';
			fileName="$OPTARG";
			;;
		h)
			#Displays help information about different command line arguments
			echo -e "Flags:\n-f | file that will be modified\n-t | trigger string(s) seperated by a space that will have lines added after them\n-s | string(s) seperated by a space that will come after their corresponding trigger string(s)\n-S | name of file that will hold newly modified file (echos to standard output by defualt)";
			exit;
			;;
		*)
			#Directs user to "help" command line argument
			echo "Use -h for flag information."
			exit;
			;;
	esac
done

#Checks for the existence of the original file 
existence_check file "$file";
#Checks if trigger strings are greater than zero
if [ "${#trigger_strings[@]}" -eq 0  ];
then
	echo "Ammount of triggers cannot be zero! Exitting.";
	exit;
fi

trigger="${trigger_strings[0]}";
userString="${user_strings[0]}";
occurenceCount=$(grep -no "$trigger" "$file" | wc -l);
file="$(cat "$file")"
o=0;
while [ "$o" -lt "${#trigger_strings[@]}" ];
do
	i=1;
	while [ "$i" -le "$occurenceCount" ];
	do
		file=$(echo "$file" | sed "$(($(echo "$file" | grep -no -m $i "$trigger" | tail -n 1 | cut -d ":" -f 1) + 1)) i $userString");
		i=$((i + 1));
	done
	o=$((o + 1));
	trigger="${trigger_strings[$o]}";
	userString="${user_strings[$o]}";
	occurenceCount=$(echo "$file" | grep -no "$trigger" | wc -l);

done
#Checks if save variable is true, if so saves to file
if [ "$save" == 'true' ];
then
	#Checks if file already exists before saving file
	if [ -e "$fileName" ];
	then
		echo -e "\nFile exists. Overwrite $fileName?";
		answer="null";
		yesORno
		if [ "${answer,,}" == "yes"  ];
		then
			echo "$file" > "$fileName";
			elif [ "${answer,,}" == "no"  ];
			then
				echo -e "\nAppend to file?";
				answer="null";
				yesORno
				if [ "${answer,,}" == "yes"  ];
				then
					echo "$file" >> "$fileName";	
				fi
		fi
	else
		echo "$file" > "$fileName";
	fi
else
	#Echos file to standard output
	echo -e "\n$file";
fi

