# Ansible playbook and Jenkins pipeline configuration

1. **Creating a Git repository on Gogs**:
    - Create a Git repository called "Apache Web Server" in GitLab.
    - Push all files (Ansible playbook, roles, Jenkinsfile) to that repository. 

2. **GitLab Integration with Jenkins**:
    #### In GitLab Instance
    - Generate Access Token called "Jenkins_GitLab_API_Access" from the account settings. 
    #### In Jenkins web console
    - Install (GitLab, GitLab API, GitLab Authentication) Plugins.
    - Add a credential of kind "GitLab API token" by using "Jenkins_GitLab_API_Access" from GitLab.

3. **Detect a code commit from GitLab repo to trigger the Jenkins pipeline**:

    #### In Jenkins web console
    - Generate API Token called "GitLab_Webhook" from "admin > Configure". 
    #### In GitLab Instance
    - Add a Webhook in the repo from the repo settings using "GitLab_Webhook" from Jenkins.

4. **Jenkins Configuration**:
    #### To access the private GitLab repository
    - Add a credential of kind "Username with password" include "Jenkins_GitLab_API_Access".

    #### To Make the ansible playbook reach VM3
    - Add a credential of kind "SSH Username with private key" include a private key which its public key is on VM3.
    - Add a credential of kind "Secret text" include the VM3 apache user sudo password.

    #### To send the email notification successfully
    - Install (Email Extension, Email Extension Template) Plugins.
    - Add a credential of kind "Username with password" include the app password which generated in email app (Gmail).
   
## Ansible Playbook to deploy Apache server

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
#### Run ansible playbook in the target machine (VM3) using "SSH_PRIVATE_KEY" & "SUDO_PASS" credentials
    stage('Run Ansible Playbook') {
        steps {
            // Use the withCredentials block to temporarily add the SSH private key to the environment
            withCredentials([sshUserPrivateKey(credentialsId: 'Apache_Credential', keyFileVariable: 'SSH_PRIVATE_KEY'),
                             string(credentialsId: 'sudo_pass', variable: 'SUDO_PASS')]) {
                // Run the ansible-playbook command
                sh 'ansible-playbook WebServerSetup.yml --private-key=${SSH_PRIVATE_KEY} --extra-vars ${SUDO_PASS}'
            }
        }
    }
#### Run GroupMembers script to fetch the admin members when the failure of the pipeline and save it in "MEMS" variable
    post {  
        failure {
            script {
                // Use the withCredentials block to temporarily add the SSH private key to the environment
                withCredentials([sshUserPrivateKey(credentialsId: 'Apache_Credential', keyFileVariable: 'SSH_PRIVATE_KEY'),
                                    string(credentialsId: 'sudo_pass', variable: 'SUDO_PASS')]) {
                    // Run bash-script
                    sh '''
                        scp -i ${SSH_PRIVATE_KEY} -r ./groupMemScript/ apache@192.168.44.140:/home/apache/Desktop/
                        ssh -i ${SSH_PRIVATE_KEY} apache@192.168.44.140 "echo ${SUDO_PASS} | sudo -S chmod a+x /home/apache/Desktop/groupMemScript/*"
                        '''
                    env.MEMS = sh( script: 'ssh -i ${SSH_PRIVATE_KEY} apache@192.168.44.140 "echo ${SUDO_PASS} | sudo -S /home/apache/Desktop/groupMemScript/GroupMembers.sh"',
                                    returnStdout: true).trim() 
                    echo "Members: ${MEMS}" 
                }
#### Send email notification in case of pipeline failure 
                // Send an email if the pipeline fails
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
                                    <p> Pipeline Execution Date: ${new Date()}.</p>
                                </body> 
                            </html>""",
                    mimeType: 'text/html' 
                )
            }
        }
    }


