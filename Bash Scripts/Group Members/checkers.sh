# Function takes a parameter with username, and return 0 if the requested user is the same as the current user
function checkUser {
    RUSER=${1}
    [ ${RUSER} == ${USER} ] && return 0
    return 1 
}

# Function takes a parameter with groupname, and return 0 if the group is exist
function groupExist {
    NGRP=${1}
    VAR2=cat /etc/group | grep -w ${NGRP} > /dev/null 2>&1
    [ ${?} -eq 0 ] && return 0
    return 1
}