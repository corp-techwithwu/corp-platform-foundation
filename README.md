# corp-platform-foundation

Enterprise Azure Landing Zones (ALZ) Foundation infrastructure as code for **Corp Platform**, automated with Terraform and GitHub Actions.

---

## 1. Overview & Upstream Dependencies

This repository establishes the foundational governance, intermediate root management group, and Azure Landing Zone hierarchy according to Microsoft's Cloud Adoption Framework (CAF) using the Azure Verified Module pattern (`Azure/avm-ptn-alz/azurerm`).

> **Upstream Dependency:**
> Highly recommended to review the upstream management repository:
> 👉 [https://github.com/corp-techwithwu/corp-platform-github](https://github.com/corp-techwithwu/corp-platform-github)
> 
> This repository attaches to the pre-existing root management group:
> **`corp-platform-root-group`** (*Corp Platform Root Group*), configured and governed in `corp-platform-github`.

---

## 2. Azure Management Group & Subscription Directory Structure

Below is the complete architectural hierarchy reflecting the deployed management groups and associated subscriptions:

### 2.1 Visual Hierarchy Tree

```text
📁 Tenant Root Group (ID: da528e4a-a122-4392-b5c8-370e74e0236d)
│
└── 📁 [Management Group] Corp Platform Root Group (corp-platform-root-group)
    │
    ├── 💳 [Subscription] corp-platform-management-prod (6b80b8d5-aef4-4952-8558-1f1b168f47a6)
    │
    └── 📁 [Management Group] CORP-PLATFORM PROD Root (mg-corp-platform-prod-root)
        │
        └── 📁 [Management Group] Azure Landing Zones (alz)
            │
            ├── 📁 [Management Group] Platform (platform)
            │   ├── 📁 Connectivity (connectivity)   # Hub networks, ExpressRoute, VPN, Azure Firewall
            │   ├── 📁 Identity (identity)           # Domain controllers, Entra Connect, Key Vaults
            │   ├── 📁 Management (management)       # Central Log Analytics, automation, monitoring
            │   └── 📁 Security (security)           # Centralized Microsoft Defender & SOC tooling
            │
            ├── 📁 [Management Group] Landing zones (landingzones)
            │   ├── 📁 Corp (corp)                   # Corporate connected internal workloads
            │   ├── 📁 Local (local)                 # Regional / edge boundary workloads
            │   └── 📁 Online (online)               # Public-facing internet egress workloads
            │
            ├── 📁 [Management Group] Sandbox (sandbox)               # Isolated experimental developer environments
            └── 📁 [Management Group] Decommissioned (decommissioned) # Archived workloads scheduled for disposal
```

---

## 3. Codebase Directory Structure

```text
corp-platform-foundation/
├── .github/
│   ├── scripts/
│   │   └── create-terraform-storage.sh           # Script to bootstrap remote tfstate storage
│   └── workflows/
│       ├── create-terraform-storage-account.yml  # Manual workflow to provision state containers
│       ├── gac-terraform-unit-tests.yml          # Pull request linting and static analysis (Checkov)
│       └── gac-terraform-test-plan-apply-prod.yml# Production deployment pipeline (Plan & Apply)
├── infraascode/
│   ├── env/
│   │   ├── dev/
│   │   │   ├── backend.hcl                       # Dev backend remote state configuration
│   │   │   └── terraform.tfvars                  # Dev environment parameter values
│   │   └── prod/
│   │       ├── backend.hcl                       # Prod backend remote state configuration
│   │       └── terraform.tfvars                  # Prod environment parameter values
│   ├── data.tf                                   # Azure client & tenant data source lookups
│   ├── locals.tf                                 # Naming conventions, tags, and ALZ parent mappings
│   ├── main.tf                                   # Intermediate root MG & ALZ module invocation
│   ├── outputs.tf                                # Exported IDs, names, and policy assignments
│   ├── provider.tf                               # azurerm, azapi, and alz provider configurations
│   ├── variables.tf                              # Input variable declarations
│   └── version.tf                                # Minimum Terraform & provider version constraints
├── .checkov.yaml                                 # Security & compliance scan configuration
├── .gitignore                                    # Git exclusion rules for Terraform artifacts
└── README.md                                     # Foundation documentation (this file)
```

---

## 4. Key Architectural Design Decisions

1. **Intermediate Root Management Group (`mg-corp-platform-prod-root`)**:
   - Created with `prevent_destroy = true` lifecycle safeguards.
   - Prevents landing zone policies from polluting the Entra ID Tenant Root Group (`da528e4a-...`).
   - Allows multi-environment isolation (`prod`, `dev`, `sandbox`) beneath the central enterprise root.

2. **Azure Verified Module Pattern (`Azure/avm-ptn-alz/azurerm`)**:
   - Leverages community-vetted, Microsoft-maintained architecture templates (`version ~> 0.22.0`).
   - Does not overwrite library definitions; relies on deterministic ordering via `management_groups_dependencies`.

3. **Conservative Subscription Placement Destruction**:
   - If a landing zone management group is removed, child subscriptions fall back to the intermediate root management group rather than the Tenant Root Group, ensuring governance policies are never accidentally stripped.

---

## 5. Deployment Guide

### Prerequisites
- Azure CLI authenticated with permissions to create Management Groups under `corp-platform-root-group`.
- Terraform `v1.5.0` or higher.
- Remote state storage account provisioned via `.github/workflows/create-terraform-storage-account.yml`.

### Local Execution (Production Example)

```bash
cd infraascode

# 1. Initialize with production backend
terraform init -backend-config=env/prod/backend.hcl

# 2. Validate configuration
terraform validate

# 3. Plan deployment
terraform plan -var-file=env/prod/terraform.tfvars -out=tfplan

# 4. Apply changes (requires elevated platform credentials)
terraform apply tfplan
```

### CI/CD Deployment via GitHub Actions
- **Pull Requests**: Automatically triggers `gac-terraform-unit-tests.yml` (Terraform format check, validation, and Checkov security scan).
- **Merge to `main`**: Automatically triggers `gac-terraform-test-plan-apply-prod.yml` to generate a plan and execute deployment using OIDC federated credentials configured in `corp-platform-github`.
