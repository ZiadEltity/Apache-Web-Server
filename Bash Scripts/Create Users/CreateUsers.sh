#!/bin/bash
############# Create users named "DevTeam" and "OpsTeam" on VM3 #############
## Exit codes:
#	0: Success
#   1: Script is executed with a user has no privileges 
#   2: Users are existed 
#   3: Group is existed 
source ./checkers.sh

checkUser "root"
[ ${?} -ne 0 ] && echo "Scrip must execute with sudo privilege" && exit 1
userExist "DevTeam"
[ ${?} -ne 0 ] && echo "DevTeam user is already exist" && exit 2
userExist "OpsTeam"
[ ${?} -ne 0 ] && echo "OpsTeam user is already exist" && exit 2
groupExist "webAdmins"
[ ${?} -ne 0 ] && echo "webAdmins group is already exist" && exit 3

# Create users named "DevTeam" and "OpsTeam"
useradd DevTeam
echo "DevTeam user created"
useradd OpsTeam
echo "OpsTeam user created"
# Create group named "webAdmins" for centralized access control
groupadd webAdmins
echo "webAdmins group created."
# Assign these users to "webAdmins" group
gpasswd -M DevTeam,OpsTeam webAdmins
echo "Users DevTeam and OpsTeam assigned to webAdmins group"

exit 0


