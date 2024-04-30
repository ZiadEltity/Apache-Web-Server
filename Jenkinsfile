pipeline {
    agent any
    stages {
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

        stage('Deploy Apache Web Server - Ansible playbook') {
            steps {
                // Use the withCredentials block to temporarily add the SSH private key to the environment
                withCredentials([sshUserPrivateKey(credentialsId: 'Apache_Credential', keyFileVariable: 'SSH_PRIVATE_KEY'),
                                 string(credentialsId: 'sudo_pass', variable: 'SUDO_PASS')]) {
                    // Run the ansible-playbook command
                    sh "ansible-playbook WebServerSetup.yml --private-key=${SSH_PRIVATE_KEY} --extra-vars ${SUDO_PASS}"
                }
            }
        }
    }
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
}

