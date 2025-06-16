pipeline {
    agent any
    environment {
        // Fetch credentials from Jenkins secret store
        ARM_SUBSCRIPTION_ID = credentials('subscription_id')
        ARM_CLIENT_ID       = credentials('client_id')
        ARM_CLIENT_SECRET   = credentials('client_secret')
        ARM_TENANT_ID       = credentials('tenant_id')
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
                    terraform apply -auto-approve \
                    -var "subscription_id=${ARM_SUBSCRIPTION_ID}" \
                    -var "client_id=${ARM_CLIENT_ID}" \
                    -var "client_secret=${ARM_CLIENT_SECRET}" \
                    -var "tenant_id=${ARM_TENANT_ID}"
                    '''
                }
            }
        }
        stage('Configure with Ansible') {
            steps {
                sh '''
                  # Fetch public IP from Terraform output
                  ANSIBLE_HOST=$(terraform -chdir=terraform output -raw public_ip)
                  
                  # Create Ansible inventory file
                  echo "[web]" > ansible/hosts
                  echo "$ANSIBLE_HOST ansible_user=azureuser" >> ansible/hosts
                  
                  # Run Ansible playbook to configure the VM
                  ansible-playbook -i ansible/hosts ansible/install_web.yml
                '''
            }
        }
        stage('Verify') {
            steps {
                script {
                    // Get the public IP from Terraform output
                    def ip = sh(script: "terraform -chdir=terraform output -raw public_ip", returnStdout: true).trim()
                    
                    // Verify the deployment by hitting the public IP
                    sh "curl http://${ip}"
                }
            }
        }
    }
}
