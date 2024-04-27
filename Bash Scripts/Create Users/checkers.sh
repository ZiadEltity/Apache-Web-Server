# Function takes a parameter with username, and return 0 if the requested user is the same as the current user
function checkUser {
    RUSER=${1}
    [ ${RUSER} == ${USER} ] && return 0
    return 1 
}
# Function takes a parameter with username, and return 0 if the new user is not exist
function userExist {
    NUSER=${1}
    cat /etc/passwd | grep -w ${NUSER} > /dev/null 2>&1
    [ ${?} -ne 0 ] && return 0
    return 1
}
# Function takes a parameter with groupname, and return 0 if the new group is not exist
function groupExist {
    NGRP=${1}
    cat /etc/group | grep -w ${NGRP} > /dev/null 2>&1
    [ ${?} -ne 0 ] && return 0
    return 1
}