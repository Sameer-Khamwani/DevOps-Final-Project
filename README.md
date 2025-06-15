# 🚀 DevOps Final Project: One-Click Jenkins Pipeline Deployment

This project demonstrates a fully automated CI/CD pipeline using Jenkins, Docker, Terraform, and Ansible to provision and configure infrastructure on Azure and deploy a web application — all triggered by a single Jenkins build.

---

## 📌 Objective

> Automate the provisioning and deployment of a web application on an Azure virtual machine using Infrastructure as Code (IaC) and Configuration Management tools — all orchestrated via Jenkins.

---

## 🧰 Tech Stack

| Tool        | Purpose                                     |
|-------------|---------------------------------------------|
| **Docker**  | Host Jenkins inside a container             |
| **Jenkins** | Automate the full provisioning & deployment |
| **Terraform** | Provision infrastructure on Azure        |
| **Ansible** | Configure the server and deploy app         |
| **Azure**   | Cloud platform for hosting VM               |
| **GitHub**  | Source code and Jenkinsfile storage         |

---

## 📁 Project Structure

```
DevOps-Final-Project/
├── terraform/
│   ├── main.tf               # Resource definitions
│   ├── provider.tf           # Azure provider config
│   ├── variables.tf          # Terraform variables
│   └── terraform.tfvars      # Secret credentials (not committed)
├── ansible/
│   └── install_web.yml       # Ansible playbook
├── app/
│   └── index.html            # Sample web app
├── Jenkinsfile               # Pipeline definition
└── README.md                 # Project documentation
```

---

## ⚙️ How It Works

### 🔹 Jenkins Pipeline Stages

1. **Terraform Init** – Initializes Terraform and installs provider plugins.
2. **Terraform Apply** – Provisions an Azure Ubuntu VM with public IP.
3. **Ansible Configuration** – Installs Apache or Node.js, deploys web app.
4. **Deployment Verification** – Validates deployment via a `curl` request.

---

## 🚀 Deployment Instructions

### 1. 🛠 Pre-requisites
- Docker installed and running
- Azure CLI configured (`az login`)
- SSH key pair created (`~/.ssh/id_rsa`)
- Jenkins container up and configured

### 2. 🧪 Run Jenkins from Docker

```bash
docker run -d ^
  --name jenkins ^
  -p 8080:8080 -p 50000:50000 ^
  -v jenkins_home:/var/jenkins_home ^
  -v /var/run/docker.sock:/var/run/docker.sock ^
  -v C:\Users\wt\DevOps-Final-Project:/workspace ^
  jenkins/jenkins:lts
```

> On first login: install **Git**, **Pipeline**, **SSH Agent** plugins

---


---

### 4. ▶️ Run Pipeline in Jenkins
- Open Jenkins → Click on **DevOps-Pipeline**
- Click **Build Now**
- Monitor Console Output for success and deployment confirmation

---

## 🌐 Output

- A running Azure VM accessible via browser:
  ```
  http://<public-ip>
  ```

- Static web page (`index.html`) or MERN app running

---

## 👨‍💻 Author

**Sameer Khamwani**   
GitHub: [github.com/Sameer-Khamwani](https://github.com/Sameer-Khamwani)

---

## 📄 License

This project is for educational purposes only.