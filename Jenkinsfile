pipeline {
    agent any
    environment {
        // Fetch credentials securely from Jenkins store
        ARM_SUBSCRIPTION_ID = credentials('subscription_id')
        ARM_CLIENT_ID       = credentials('client_id')
        ARM_CLIENT_SECRET   = credentials('client_secret')
        ARM_TENANT_ID       = credentials('tenant_id')
        SSH_PUBLIC_KEY      = credentials('ssh_public_key') // Fetch SSH key
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
                sh '''
                  ANSIBLE_HOST=$(terraform -chdir=terraform output -raw public_ip)
                  echo "[web]" > ansible/hosts
                  echo "$ANSIBLE_HOST ansible_user=azureuser" >> ansible/hosts
                  ansible-playbook -i ansible/hosts ansible/install_web.yml
                '''
            }
        }
        stage('Verify') {
            steps {
                script {
                    def ip = sh(script: "terraform -chdir=terraform output -raw public_ip", returnStdout: true).trim()
                    sh "curl http://${ip}"
                }
            }
        }
    }
}
