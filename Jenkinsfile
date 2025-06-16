pipeline {
    agent any
    environment {
        // Fetch credentials securely from Jenkins store
        ARM_SUBSCRIPTION_ID = credentials('subscription_id')
        ARM_CLIENT_ID       = credentials('client_id')
        ARM_CLIENT_SECRET   = credentials('client_secret')
        ARM_TENANT_ID       = credentials('tenant_id')
        SSH_PUBLIC_KEY      = credentials('ssh_public_key') // Fetch SSH key
        
        // Disable Ansible host key checking for automation
        ANSIBLE_HOST_KEY_CHECKING = "False"
    }
    stages {
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh '''
                    echo "$SSH_PUBLIC_KEY" > /tmp/id_rsa.pub
                    terraform apply -auto-approve \
                    -var "subscription_id=${ARM_SUBSCRIPTION_ID}" \
                    -var "client_id=${ARM_CLIENT_ID}" \
                    -var "client_secret=${ARM_CLIENT_SECRET}" \
                    -var "tenant_id=${ARM_TENANT_ID}" \
                    -var "public_key_path=/tmp/id_rsa.pub"
                    '''
                }
            }
        }
        stage('Configure with Ansible') {
            steps {
                script {
                    // Get the public IP from Terraform output
                    def public_ip = sh(
                        script: 'terraform -chdir=terraform output -raw public_ip',
                        returnStdout: true
                    ).trim()
                    
                    echo "Configuring server at IP: ${public_ip}"
                    
                    // Create Ansible inventory with SSH options
                    sh """
                        echo "[web]" > ansible/hosts
                        echo "${public_ip} ansible_user=azureuser ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'" >> ansible/hosts
                    """
                    
                    // Wait for SSH to be available (VM might still be booting)
                    sh """
                        echo "Waiting for SSH to be available on ${public_ip}..."
                        timeout 300 bash -c 'while ! nc -z ${public_ip} 22; do echo "Waiting for SSH..."; sleep 10; done'
                        echo "SSH is now available!"
                    """
                    
                    // Run Ansible playbook
                    sh '''
                        ansible-playbook -i ansible/hosts ansible/install_web.yml -v
                    '''
                }
            }
        }
        stage('Verify') {
            steps {
                script {
                    def ip = sh(script: "terraform -chdir=terraform output -raw public_ip", returnStdout: true).trim()
                    echo "Verifying deployment at http://${ip}"
                    
                    // Add retry logic for verification
                    retry(3) {
                        sh """
                            echo "Testing web server response..."
                            curl -f --connect-timeout 10 --max-time 30 http://${ip}
                        """
                    }
                    echo "Deployment verification successful!"
                }
            }
        }
    }
    
    post {
        always {
            // Clean up temporary files
            sh 'rm -f /tmp/id_rsa.pub'
        }
        success {
            script {
                def ip = sh(script: "terraform -chdir=terraform output -raw public_ip", returnStdout: true).trim()
                echo "Pipeline completed successfully! Web server is running at: http://${ip}"
            }
        }
        failure {
            echo "Pipeline failed. Check the logs above for details."
        }
    }
}