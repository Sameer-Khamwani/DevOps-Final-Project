pipeline {
    agent any
    environment {
        // Fetch credentials securely from Jenkins store
        ARM_SUBSCRIPTION_ID = credentials('subscription_id')
        ARM_CLIENT_ID       = credentials('client_id')
        ARM_CLIENT_SECRET   = credentials('client_secret')
        ARM_TENANT_ID       = credentials('tenant_id')
        SSH_PUBLIC_KEY      = credentials('ssh_public_key')
        SSH_PRIVATE_KEY     = credentials('ssh_private_key') // Add this credential in Jenkins
        
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
                    
                    // Setup SSH private key for Ansible
                    sh '''
                        echo "$SSH_PRIVATE_KEY" > /tmp/id_rsa
                        chmod 600 /tmp/id_rsa
                        eval $(ssh-agent -s)
                        ssh-add /tmp/id_rsa 2>/dev/null || true
                    '''
                    
                    // Create Ansible inventory with SSH options
                    sh """
                        mkdir -p ansible
                        cat > ansible/hosts << EOF
[web]
${public_ip} ansible_user=azureuser ansible_ssh_private_key_file=/tmp/id_rsa

[web:vars]
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30
EOF
                    """
                    
                    // Wait for SSH to be available with multiple methods
                    sh """
                        echo "Waiting for SSH to be available on ${public_ip}..."
                        SSH_READY=false
                        
                        for i in \$(seq 1 30); do
                            echo "Attempt \$i/30: Testing SSH connectivity..."
                            
                            # Method 1: Try direct SSH connection
                            if timeout 10 ssh -i /tmp/id_rsa -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes azureuser@${public_ip} echo "SSH Ready" 2>/dev/null; then
                                echo "SSH is now available!"
                                SSH_READY=true
                                break
                            fi
                            
                            # Method 2: Try using /dev/tcp if available
                            if timeout 5 bash -c "echo >/dev/tcp/${public_ip}/22" 2>/dev/null; then
                                echo "Port 22 is open, trying SSH again in 5 seconds..."
                                sleep 5
                                continue
                            fi
                            
                            echo "SSH not ready yet, waiting 15 seconds..."
                            sleep 15
                        done
                        
                        if [ "\$SSH_READY" != "true" ]; then
                            echo "SSH connection failed after 30 attempts"
                            exit 1
                        fi
                    """
                    
                    // Run Ansible playbook with retry
                    sh '''
                        echo "Running Ansible playbook..."
                        ANSIBLE_RETRIES=3
                        for i in $(seq 1 $ANSIBLE_RETRIES); do
                            echo "Ansible attempt $i/$ANSIBLE_RETRIES"
                            if ansible-playbook -i ansible/hosts ansible/install_web.yml -v; then
                                echo "Ansible playbook completed successfully!"
                                break
                            else
                                if [ $i -eq $ANSIBLE_RETRIES ]; then
                                    echo "Ansible failed after $ANSIBLE_RETRIES attempts"
                                    exit 1
                                fi
                                echo "Ansible attempt $i failed, retrying in 30 seconds..."
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
                    
                    // Add retry logic for verification with longer timeout
                    sh """
                        echo "Waiting for web service to be ready..."
                        for i in \$(seq 1 20); do
                            echo "Verification attempt \$i/20"
                            if timeout 15 curl -f --connect-timeout 10 --max-time 30 -s http://${ip}; then
                                echo "Web service is responding!"
                                break
                            else
                                if [ \$i -eq 20 ]; then
                                    echo "Web service verification failed after 20 attempts"
                                    exit 1
                                fi
                                echo "Web service not ready, waiting 15 seconds..."
                                sleep 15
                            fi
                        done
                    """
                    echo "Deployment verification successful!"
                }
            }
        }
    }
    
    post {
        always {
            // Clean up temporary files
            sh '''
                rm -f /tmp/id_rsa.pub /tmp/id_rsa
                ssh-agent -k 2>/dev/null || true
            '''
        }
        success {
            script {
                def ip = sh(script: "terraform -chdir=terraform output -raw public_ip", returnStdout: true).trim()
                echo "Pipeline completed successfully! Web server is running at: http://${ip}"
            }
        }
        failure {
            echo "Pipeline failed. Check the logs above for details."
            // Optional: Add Terraform destroy on failure
            // sh 'terraform -chdir=terraform destroy -auto-approve'
        }
    }
}