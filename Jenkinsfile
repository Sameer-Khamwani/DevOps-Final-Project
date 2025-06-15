pipeline {
    agent any
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
                    sh 'terraform apply -auto-approve -var-file="terraform.tfvars"'

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
