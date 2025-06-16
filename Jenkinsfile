pipeline {
    agent any
    environment {
        // Fetch credentials securely from Jenkins store
        ARM_SUBSCRIPTION_ID = credentials('subscription_id')
        ARM_CLIENT_ID       = credentials('client_id')
        ARM_CLIENT_SECRET   = credentials('client_secret')
        ARM_TENANT_ID       = credentials('tenant_id')
        SSH_PUBLIC_KEY      = credentials('ssh_public_key')
        
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
                        echo "${public_ip} ansible_user=azureuser ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30'" >> ansible/hosts
                    """
                    
                    // Simple wait approach - give VM time to fully boot
                    sh """
                        echo "Waiting 2 minutes for VM to be fully ready..."
                        sleep 120
                        echo "Proceeding with Ansible configuration..."
                    """
                    
                    // Run Ansible playbook with retry
                    sh '''
                        for i in {1..3}; do
                            echo "Ansible attempt $i/3"
                            if ansible-playbook -i ansible/hosts ansible/install_web.yml -v --timeout=60; then
                                echo "Ansible completed successfully!"
                                break
                            else
                                if [ $i -eq 3 ]; then
                                    echo "Ansible failed after 3 attempts"
                                    exit 1
                                fi
                                echo "Retrying in 30 seconds..."
                                sleep 30
                            fi
                        done
                    '''
                }
            }
        }
        stage('Verify') {
            steps {
                script {
                    def ip = sh(script: "terraform -chdir=terraform output -raw public_ip", returnStdout: true).trim()
                    echo "Verifying deployment at http://${ip}"
                    
                    // Simple retry with curl
                    sh """
                        for i in {1..10}; do
                            echo "Verification attempt \$i/10"
                            if curl -f --connect-timeout 15 --max-time 30 http://${ip}; then
                                echo "Verification successful!"
                                break
                            else
                                if [ \$i -eq 10 ]; then
                                    echo "Verification failed"
                                    exit 1
                                fi
                                echo "Retrying in 15 seconds..."
                                sleep 15
                            fi
                        done
                    """
                }
            }
        }
    }
    
    post {
        always {
            sh 'rm -f /tmp/id_rsa.pub'
        }
        success {
            script {
                def ip = sh(script: "terraform -chdir=terraform output -raw public_ip", returnStdout: true).trim()
                echo "✅ Pipeline completed successfully! Web server is running at: http://${ip}"
            }
        }
        failure {
            echo "❌ Pipeline failed. Check the logs above for details."
        }
    }
}