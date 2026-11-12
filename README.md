# 🔨 AWS EC2 Provisioning with Terraform Cloud & GitHub Actions

This repository automates the provisioning, updating, and destruction of AWS EC2 infrastructure using **Terraform (`v1.17.1`)**, **Terraform Cloud Workspaces**, and a manual **GitHub Actions** (`workflow_dispatch`) pipeline.

## 🏗️ Repository Structure

```text
.
├── .github/
│   └── workflows/          # GitHub Actions workflow ('🔨 Infrastructure Configuring using Terraform on AWS')
├── Terraform/              # Terraform configuration files (working directory for CI/CD)
├── .gitignore              # Git ignore rules for Terraform files
├── LICENSE                 # MIT License
└── README.md               # Project documentation
```

## ✅ Prerequisites & Configuration

Before triggering the workflow, ensure your Terraform Cloud and GitHub repository settings are configured:

### 1. Terraform Cloud Setup
* Create a **Terraform Cloud Organization** and a target **Workspace**.
* Configure your **AWS Credentials** (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`) as environment variables directly inside your Terraform Cloud Workspace so Terraform Cloud can provision EC2 resources on AWS.

### 2. GitHub Environment & Secrets
This pipeline targets the `production` GitHub environment. Add the following secrets under **Settings > Secrets and variables > Actions** (or inside the `production` environment):

| Secret Name | Description |
| :--- | :--- |
| `TF_API_TOKEN` | Terraform Cloud API token for CLI authentication |
| `TF_CLOUD_ORGANIZATION` | Name of your Terraform Cloud organization |
| `TF_WORKSPACE` | Target Terraform Cloud workspace name |

## ⚙️ GitHub Actions Pipeline

The workflow (**`🔨 Infrastructure Configuring using Terraform on AWS`**) is triggered manually via **`workflow_dispatch`** and runs inside the `Terraform/` directory on `ubuntu-24.04`.

### Workflow Inputs
When running the workflow from the **Actions** tab, select one of the following actions:
* **`plan`** *(Default)* – Previews infrastructure changes without modifying AWS resources.
* **`apply`** – Provisions or updates AWS EC2 resources (`terraform apply -auto-approve`).
* **`destroy`** – Tears down all managed AWS resources (`terraform destroy -auto-approve`).

### Pipeline Stages
1. **Checkout Repository:** Clones the repository (`actions/checkout@v5`).
2. **Setup Terraform:** Installs Terraform `1.17.1` and configures Terraform Cloud credentials (`hashicorp/setup-terraform@v3`).
3. **Cache Plugins:** Caches `.terraform` and `~/.terraform.d/plugin-cache` (`actions/cache@v4`) to speed up runs.
4. **Initialize (`terraform init`):** Connects to Terraform Cloud using `TF_CLOUD_ORGANIZATION` and `TF_WORKSPACE`.
5. **Format & Validate:** Enforces code formatting (`terraform fmt -check --diff`) and validates syntax (`terraform validate`).
6. **Execute Action:** Runs `plan`, `apply`, or `destroy` based on your selected workflow input.

## 🚀 Local Execution

To run Terraform commands locally against your Terraform Cloud workspace:

```bash
# 1. Clone the repository and enter the Terraform directory
git clone https://github.com
cd forkity-project/Terraform

# 2. Authenticate with Terraform Cloud
terraform login

# 3. Export your organization and workspace
export TF_CLOUD_ORGANIZATION="your-org-name"
export TF_WORKSPACE="your-workspace-name"

# 4. Initialize, validate, and plan
terraform init
terraform fmt -check --diff
terraform validate
terraform plan
```

## 💡 Quick Workflow Note
In your GitHub Actions YAML, there are two minor typos you may want to fix so the job name and token authentication render properly:
1. Line 28: Change `${{ github.event.input.actions }}` to `${{ github.event.inputs.action }}` so the job name displays the chosen action (`plan`, `apply`, or `destroy`).
2. Line 43: Remove the space in `${{ secrets. TF_API_TOKEN }}` so it reads `${{ secrets.TF_API_TOKEN }}`.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
