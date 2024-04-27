#!/bin/bash
############# Fetch a list of users from the "webAdmins" group #############
## Exit codes:
#	0: Success
#   1: Script is executed with a user has no privileges 
#   2: Group is existed 
source ./checkers.sh

checkUser "root"
[ ${?} -ne 0 ] && echo "Scrip must execute with sudo privilege" && exit 1
groupExist "webAdmins"
[ ${?} -ne 0 ] && echo "webAdmins group is not exist" && exit 2

# Fetch the users of "webAdmins" group
GROUP_MEMBERS=$(groupmems -l -g webAdmins) > members.txt
echo "Users in the webAdmins group: $GROUP_MEMBERS"
echo "$GROUP_MEMBERS" > members.txt

exit 0


