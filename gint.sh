#!/bin/bash 

#Please, specify the location of the gam.py file here. 
GAM_FILE="/home/apinchuk/Documents/clients/autogrid/Gam/gam.py"


#If any commnad within the pipe fails, the whole pipe shall fail. 
set -o pipefail
set -e
#set -x

#Define which groups a user is a part of 
groupprint(){
    
        local usergroups="$($GAM_FILE info user $1 2> /dev/null | grep -i "<*>" | cut -d '<' -f 2 | cut -d '@' -f 1)"
        if [ "$(userexists $1)" -eq 0 ] && [ -n "$usergroups" ]; then  
            for group in $usergroups 
            do 
                echo $group 
            done
        else 
            usernotingroups
        fi     
}

help(){
    echo "usage: You must edit GAM_FILE variable inside the script.
       gint.sh [printgroups] {username}
       gint.sh [atg|--add-to-groups] {username} {group1} [group2 ...]
       gint.sh [rfg|--remove-from-groups] [-a] {username} {group1} [group2 ...]
       gint.sh [clone|--clone-groups] {user to be cloned} {user to clone to}

       -a flag marks for removal of user from all groups
      "
}


# Check for the user's existance
userexists(){
    local status=0
    if $GAM_FILE info user $1 &> /dev/null; then 
        founduser
    else 
        nousererror
        status=1
    fi
    echo "$status"
}

#Check for the group's existance
groupexists(){
    local status=1
    for GROUP in $($GAM_FILE print groups name 2> /dev/null | grep "@" | cut -d "@" -f 1)
    do 
        if [ $GROUP = "$1" ]; then 
            status=0
            foundgroup
            break
        fi
    done 
    echo "$status"

}

#These are the error messsages if something goes wrong. 
nousererror() { 
    echo "Couldn't find such user" >&2
    exit 1
}

nogrouperror() { 
    echo "Couldn't find such group" >&2 
    exit 2
}

grouporusererror() { 
    echo "The user or the group are wrong" >&2
    exit 3
}

gamfileerror() { 
    if [ -z "$GAM_FILE" ] || ! [[ "$GAM_FILE" =~ gam.py$ ]]; then 
        printf "The location of gam.py is either not set or wrong.\n" >&2 
        printf "Please, open the script and edit the location.\n" >&2
        exit 4
    fi
}


#########################################################################################

#These are system messages that inform you about the progress
foundgroup() { 
    echo "The group was found" >&2 
}

founduser() { 
    echo "The user was found" >&2
}

usernotingroups() { 
    echo "The user is currently not in any groups" >&2
}

##########################################################################################



#Main logic of the script
gamfileerror
case $1 in 
    printgroups)
        echo "Printing groups..." >&2 
        if [ "$2" != "" ]; then 
            groupprint $2
        else
            nousererror
        fi
        ;;
    atg|--add-to-groups)
        echo "Adding to groups..." >&2
        if [ "$(userexists $2)" -eq 0 ] && [ "$(groupexists $3)" -eq 0 ]; then 
            for GROUP in "${@:3}"
            do
                $GAM_FILE update group $GROUP add member "$2"
            done  
        else
            echo "Someting went wrong" >&2
        fi
        ;;
    rfg|--remove-from-groups)
        echo "Removing from groups..." >&2
        if [ "$2" = -a ] && [ "$(userexists $3)" -eq 0 ]; then 
               for GROUP in $(groupprint $3)
               do 
                   $GAM_FILE update group $GROUP remove member "$3"
               done
        elif [ "$(userexists $2)" -eq 0 ] && [ "$(groupexists $3)" -eq 0 ]; then 
            foundgroup
            for GROUP in "${@:3}"
            do
                $GAM_FILE update group $GROUP remove member "$2" 
            done  
        else
            grouporusererror
        fi
        ;;
    clone|--clone-groups)
        echo "Cloning groups..." >&2
        if [ "$(userexists $2)" -eq 0 ] && [ "$(userexists $3)" -eq 0 ]; then 
            for GROUP in $($GAM_FILE info user $2 2> /dev/null | grep -i "<*>" | cut -d '<' -f 2 | cut -d '@' -f 1)
            do
                $GAM_FILE update group $GROUP add member "$3"
            done
        fi
        ;;
    -h|--help)
        echo "Brining up help..." >&2
        help
        ;;
    *) 
        echo "No such option" >&2
        help
        ;;
esac

set +o pipefail
set +e
set +x
