# Apache-Web-Server with Jenkins/Ansible

![Project Flowchart](https://github.com/ZiadEltity/Apache-Web-Server-/assets/70934743/0b22336b-f70d-4d9b-bbcd-bf074b82c32d)


## Project Description

This project aims to set up a (CI/CD) pipeline using Jenkins, Ansible, and GitLab. It involves provisioning virtual machines (VMs) with dedicated services, managing user access, integrating GitLab with Jenkins, and detecting a code commit to make the Jenkins pipeline autonomously execute an ansible playbook to install and configure Apache HTTP Server and generate an email notification if the pipeline fails.

## Prerequisites

1. VMware workstation installed on your machine (using CentOS 9 stream image).
2. VM1- Jenkins Server: A dedicated Jenkins server for orchestrating the CI/CD pipeline.
3. VM2 - GitLab Instance: Implementation of a private GitLab instance for hosting Git.
4. VM3- Web Server: Deployment of a web server with Apache HTTP Server service using Ansible. 

## Setup

1. **Provisioning VMs**: 

    - VM1: Jenkins Server
      - IP: 192.168.44.100:8080
      - Admin User: jenkins
    - VM2: GitLab Instance
      - IP: 192.168.44.120
      - Admin User: gitlab
    - VM3: Web Server with Apache HTTP Server
      - IP: 192.168.44.140
      - Admin User: apache

2. **Create users named "DevTeam" and "OpsTeam" on VM3**:
- checkers.sh bash script:
    #### Function takes a parameter with username, and return 0 if the requested user is the same as the current user
        function checkUser {
            RUSER=${1}
            [ ${RUSER} == ${USER} ] && return 0
            return 1 
        }
    #### Function tasks a parameter with username, and return 0 if the new user is not exist
        function userExist {
            NUSER=${1}
            cat /etc/passwd | grep -w ${NUSER} > /dev/null 2>&1
            [ ${?} -ne 0 ] && return 0
            return 1
        }
    #### Function takes a parameter with groupname, and return 0 if the new group is not exist
        function groupExist {
            NGRP=${1}
            cat /etc/group | grep -w ${NGRP} > /dev/null 2>&1
            [ ${?} -ne 0 ] && return 0
            return 1
        }

    #### Exit codes:
        -	0: Success
        -   1: Script is executed with a user has no privileges 
        -   2: Users are existed 
        -   3: Group is existed 

- CreateUsers.sh bash script:
    #### Check according to the previous exit codes:
   ```bash
    source ./checkers.sh
    checkUser "root"
    [ ${?} -ne 0 ] && echo "Scrip must execute with sudo privilege" && exit 1
    userExist "DevTeam"
    [ ${?} -ne 0 ] && echo "DevTeam user is already exist" && exit 2
    userExist "OpsTeam"
    [ ${?} -ne 0 ] && echo "OpsTeam user is already exist" && exit 2
    groupExist "webAdmins"
    [ ${?} -ne 0 ] && echo "webAdmins group is already exist" && exit 3
    ```
    #### Create users named "DevTeam" and "OpsTeam"
   ```bash
    useradd DevTeam
    echo "DevTeam user created"
    useradd OpsTeam
    echo "OpsTeam user created"
    ```
    #### Create group named "webAdmins" for centralized access control
   ```bash
    groupadd webAdmins
    echo "webAdmins group created."
    ```
    #### Assign these users to "webAdmins" group
   ```bash
    gpasswd -M DevTeam,OpsTeam webAdmins
    echo "Users DevTeam and OpsTeam assigned to webAdmins group"

    exit 0
    ```
3. **Fetch a list of users from the "webAdmins" group on VM3**:
- checkers.sh bash script:
    #### Function takes a parameter with username, and return 0 if the requested user is the same as the current user
        function checkUser {
            RUSER=${1}
            [ ${RUSER} == ${USER} ] && return 0
            return 1 
        }
    #### Function takes a parameter with groupname, and return 0 if the new group is exist
        function groupExist {
            NGRP=${1}
            cat /etc/group | grep -w ${NGRP} > /dev/null 2>&1
            [ ${?} -ne 0 ] && return 0
            return 1
        }

    #### Exit codes:
        -	0: Success
        -   1: Script is executed with a user has no privileges 
        -   2: Group is existed 

- GroupMembers.sh bash script:
    #### Check according to the previous exit codes:
   ```bash
    source ./checkers.sh
    checkUser "root"
    [ ${?} -ne 0 ] && echo "Scrip must execute with sudo privilege" && exit 1
    groupExist "webAdmins"
    [ ${?} -ne 0 ] && echo "webAdmins group is not exist" && exit 2
    ```
    #### Fetch the users of "webAdmins" group
   ```bash
    GROUP_MEMBERS=$(groupmems -l -g webAdmins) > members.txt
    echo "Users in the webAdmins group: $GROUP_MEMBERS"
    echo "$GROUP_MEMBERS" > members.txt

    exit 0
    ```
4. **Creating a Git repository on Gogs**:
    - Create a Git repository called "Apache Web Server" in GitLab.
    - Push all files (Ansible playbook, roles, Jenkinsfile) to that repository. 

5. **GitLab Integration with Jenkins**:
    #### In GitLab Instance
    - Generate Access Token called "Jenkins_GitLab_API_Access" from the account settings. 
    #### In Jenkins web console
    - Install (GitLab, GitLab API, GitLab Authentication) Plugins.
    - Add a credential of kind "GitLab API token" by using "Jenkins_GitLab_API_Access" from GitLab.

6. **Detect a code commit from GitLab repo to trigger the Jenkins pipeline**:

    #### In Jenkins web console
    - Generate API Token called "GitLab_Webhook" from "admin > Configure". 
    #### In GitLab Instance
    - Add a Webhook in the repo from the repo settings using "GitLab_Webhook" from Jenkins.

7. **Jenkins Configuration**:
    #### To access the private GitLab repository
    - Add a credential of kind "Username with password" include "Jenkins_GitLab_API_Access".

    #### To Make the ansible playbook reach VM3
    - Add a credential of kind "SSH Username with private key" include a private key which its public key is on VM3.
    - Add a credential of kind "Secret text" include the VM3 apache user sudo password.

    #### To send the email notification successfully
    - Install (Email Extension, Email Extension Template) Plugins.
    - Add a credential of kind "Username with password" include the app password which generated in email app (Gmail).
   
## Ansible Playbook to deploy Apache server

 ### Configure the inventory file:
   ```ini
   [webservers]
   192.168.44.140
   ```
 ### Upade the ansible configuration file:
   ```ini
   [defaults]
   inventory = inventory
   remote_user = apache
   host_key_checking = no

  [privilege_escalation]
  become = yes
  become_user = root
  become_method = sudo
  become_ask_pass = no
  ```
 ### Install the role with ansible-galaxy command:
    ansible-galaxy init roles/webserver-role
 ### Ansible Playbook (WebServerSetup.yml)
    - name: Playbook to install and configure Apache HTTP Server on VM3
    hosts: webservers
    gather_facts: no
    roles:  
        - webserver-role
 ### Ansible Role (webserver-role)

   #### Tasks (roles/tasks/main.yml)
   ###### Install httpd server package 
    - name: install apache
    ansible.builtin.yum:
        name: httpd
        state: present
   ###### Start httpd service
    - name: start and enable httpd service
    ansible.builtin.service:
        name: httpd
        state: started
        enabled: yes
   ###### Allow HTTP traffic through firewall and notify the handler to restart firewall service  
    - name: allow HTTP traffic through firewall
    ansible.posix.firewalld:
        service: http
        permanent: yes
        state: enabled
    notify:
        - reload firewalld
   ###### Configure Apache home page and notify a handler to restart httpd service 
    - name: add custom root page
    ansible.builtin.template:
        src: index.html.j2
        dest: /var/www/html/index.html
        mode: 0644
    notify:
        - restart apache svc
   #### Handlers (roles/handlers/main.yml)
   ###### Restart firewall service  
    - name: reload firewalld
    service:
        name: firewalld
        state: reloaded
   ###### Restart httpd service  
    - name: restart apache svc
    ansible.builtin.service:
        name: httpd
        state: restarted
   #### Variables (roles/vars/main.yml)
   ###### Variable to be showed in the apache new home page
    username: "Eng. Ziad Magdy"
   #### Templates (roles/templates/index.html.j2)
   ###### Coding the new apache home page with html
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Project-2</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                margin: 0;
                padding: 0;
                background-color: #f3f3f3;
            }
            .container {
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                background-color: #fff;
                border-radius: 10px;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            }
            h1 {
                color: #333;
                text-align: center;
            }
            p {
                color: #666;
                line-height: 1.6;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Welcome To Apache Web Server</h1>
            <p>Project-2 Completed Successfully by {{ username }}</p>
        </div>
    </body>
    </html>

## Jenkins File to deploy the Ansible Playbook

#### First stage: To run GroupMembers.sh script to fetch the admin members when the failure of the pipeline and save it in "MEMS" variable
    stage('Bach Script Execution') {
        steps {
            script {
                // Initialize the variable to avoid the error of null if the script didn't executed successfully
                env.MEMS = "Undefined - Destination unreachable"  
                // Use the withCredentials block to temporarily add the SSH private key to the environment
                withCredentials([sshUserPrivateKey(credentialsId: 'Apache_Credential', keyFileVariable: 'SSH_PRIVATE_KEY'),
                                    string(credentialsId: 'sudo_pass', variable: 'SUDO_PASS')]) {
                    // Run bash-script
                    sh """
                        scp -i ${SSH_PRIVATE_KEY} -r ./groupMemScript/ apache@192.168.44.140:/home/apache/Desktop/
                        ssh -i ${SSH_PRIVATE_KEY} apache@192.168.44.140 "echo ${SUDO_PASS} | sudo -S chmod a+x /home/apache/Desktop/groupMemScript/*"
                        """
                    env.MEMS = sh( script: "ssh -i ${SSH_PRIVATE_KEY} apache@192.168.44.140 'echo ${SUDO_PASS} | sudo -S /home/apache/Desktop/groupMemScript/GroupMembers.sh'",
                                    returnStdout: true).trim() 
                    echo "Members: ${MEMS}" 
                }
            }    
        }
    }

#### Second stage: To run ansible playbook in the target machine (VM3) using "SSH_PRIVATE_KEY" & "SUDO_PASS" credentials
    stage('Run Ansible Playbook') {
        steps {
            // Use the withCredentials block to temporarily add the SSH private key to the environment
            withCredentials([sshUserPrivateKey(credentialsId: 'Apache_Credential', keyFileVariable: 'SSH_PRIVATE_KEY'),
                             string(credentialsId: 'sudo_pass', variable: 'SUDO_PASS')]) {
                // Run the ansible-playbook command
                sh "ansible-playbook WebServerSetup.yml --private-key=${SSH_PRIVATE_KEY} --extra-vars ${SUDO_PASS}"
            }
        }
    }

#### Send email notification in case of pipeline failure 
    post {  
        failure {
            script {               
                // Send an email if the pipeline fails
                env.DATE = new Date().format('yyyy-MM-dd')            
                emailext (
                    subject: "Pipeline Failed: ${JOB_NAME}",
                    to: "slide.nfc22@gmail.com",
                    from: "webserver@jenkins.com", 
                    replyTo: "webserver@jenkins.com",               
                    body:  """<html>
                                <body> 
                                    <h2>${JOB_NAME} — Build ${BUILD_NUMBER}</h2>
                                    <div style="background-color: white; padding: 5px;"> 
                                        <h3 style="color: black;">Pipeline Status: FAILURE</h3> 
                                    </div> 
                                    <p> Check Pipeline Failed Reason <a href="${BUILD_URL}">console output</a>.</p>
                                    <p> Web Admins: ${MEMS}.</p>
                                    <p> Pipeline Execution Date: ${DATE}.</p>
                                </body> 
                            </html>""",
                    mimeType: 'text/html' 
                )
            }
        }
    }


