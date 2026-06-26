# Project of High-Availability Custom Three-Tier Network Architecture (AWS VPC From Scratch)

A production-grade, enterprise-ready AWS network infrastructure engineered entirely from scratch using Terraform. This architecture completely moves away from AWS default VPC settings to demonstrate a deep, hands-on understanding of advanced networking concepts, asymmetric routing, Layer-4 firewalls, and Layer-7 application load balancing.

---

## Core Architectural Schematic Diagram

The entire network fabric is deployed across multiple Availability Zones in the **ap-southeast-1 (Singapore)** region to ensure high availability and absolute fault tolerance.

```
                  [ PUBLIC INTERNET ]
                           │
                           ▼
                 [ Internet Gateway ]
                           │
 ┌─────────────────────────┴─────────────────────────┐
 │ VPC Network Space: 10.0.0.0/16                    │
 │                                                   │
 │ 🌐 PUBLIC TIER (ALB Ingress)                      │
 │ ┌──────────────────────┐ ┌──────────────────────┐ │
 │ │ Public Subnet 1a     │ │ Public Subnet 1b     │ │
 │ │ 10.0.1.0/24          │ │ 10.0.2.0/24          │ │
 │ │                      │ │                      │ │
 │ │  ┌────────────────┐  │ │                      │ │
 │ │  │  Public ALB    │◄─┼─┼──────────────────────┼─┼─► Public HTTP (Port 80)
 │ │  └───────┬────────┘  │ │                      │ │
 │ │          │           │ │                      │ │
 │ │    [ NAT Gateway ]   │ │                      │ │
 │ └──────────┼───────────┘ └──────────────────────┘ │
 │            │                                      │
 │ 🔒 PRIVATE APPLICATION TIER (Isolated Compute)    │
 │ ┌──────────▼───────────┐ ┌──────────────────────┐ │
 │ │ Private Subnet 1a    │ │ Private Subnet 1b    │ │
 │ │ 10.0.11.0/24         │ │ 10.0.12.0/24         │ │
 │ │                      │ │                      │ │
 │ │  ┌────────────────┐  │ │  ┌────────────────┐  │ │
 │ │  │ Flask App (AZ-A)│  │ │  │ Flask App (AZ-B)│  │ │
 │ │  │ Port 5000      │  │ │  │ Port 5000      │  │ │
 │ │  └────────────────┘  │ │  └────────────────┘  │ │
 │ └──────────────────────┘ └──────────────────────┘ │
 └───────────────────────────────────────────────────┘


---

## 🛠️ Deep-Dive Technical Implementation Matrix

This project directly maps implementation mechanics to core enterprise networking competencies required by modern DevOps and Cloud Infrastructure teams.

| Networking Concept | Implementation & Validation Engineering |
| :--- | :--- |
| **IP Subnetting & CIDR** | Designed and segmented a `/16` private network space into isolated, non-overlapping `/24` custom blocks across distinct Availability Zones (A/B) allowing up to 251 usable host IPs per subnet tier. |
| **Asymmetric Routing** | Configured decoupled route tables implementing stateful boundaries: Public subnets map out directly to the **Internet Gateway (IGW)**, whereas Private subnets route entirely through a high-throughput **NAT Gateway** to restrict inbound perimeter access. |
| **Layer-4 State Control (TCP/IP)** | Implemented strict, multi-layered security group firewalls enforcing security principles of least privilege. Inbound compute access is explicitly bound to **TCP Port 5000** and constrained strictly to packets originating from the ALB proxy boundary. |
| **Layer-7 Load Balancing** | Provisioned a public-facing **Application Load Balancer (ALB)** driving automated target group synchronization, active cross-zone round-robin proxy distribution, and Layer-7 HTTP status health probes. |

---

## Modular Repository Structured

The codebase is engineered around highly decoupled, modular declarative configuration scripts:

```
terraform-custom-vpc-lab/
├── .gitignore          # Active guardrail shielding local binary cache layers
├── providers.tf        # Cloud API version anchoring and provider block mappings
├── vpc.tf              # Base custom VPC fabric, subnets, IGW, NAT, and route matrices
├── alb.tf              # Layer-7 application routing gates and health check probes
└── compute.tf          # Isolated compute targets, security rules, and initialization logic
```

---

## Deployment & Operational Validation Workflow

Follow these instructions to spin up, verify, and dismantle the multi-tier infrastructure workspace:

### 1. Initialize the Workspace Boundary
Establish your workspace shield and download the pinned AWS provider core engine:
```powershell
-mkdir / cd (terraform-custom-vpc-lab)
# Verify your local tracking is clean and binary insulated
git status

# Initialize the HashiCorp plugin configuration
terraform init

# Check in any error the code format and once fully verified and validate it will trigger successfully notes
terraform fmt & terraform validate

```

### 2. Compile and Validate the Execution Plan
Before executing deployment mutations against your live account, confirm the layout mapping:
```powershell
terraform plan
```
*Expected output: `Plan: 14 to add`, `Plan: 4 to add`, and `Plan: 5 to add` sequentially across compilation steps.*

### 3. Provision the Full Cloud Fabric
Execute the structural configuration blocks directly to the Singapore region:
```powershell
terraform apply
```

---

## 📸 Deployment & Operational Verification

### Execution terraform apply Infrastructure Build Status
Below is the successful 14-resource custom network deployment terminal confirmation:
![VPC Apply Complete](terraform-apply-complete-vpclab.png)

Below is the successful 4-resource custom network deployment terminal confirmation:
![VPC Apply Complete](terraform-apply-complete-alb.png)

Below is the successful 5-resource custom network deployment terminal confirmation:
![VPC Apply Complete](terraform-apply-complete-compute.png)


### Live Architecture Routing Verification
Outputs alb public URL
![Live Architecture verification](architecture-live-verification.png)

The browser round-robin load distribution validation page:
![Live Architecture Verification](production-external-alb-live.png)

### Git Execution and Application into GitHub setup main branch
Infrastructure architected custom
![Git Apply Complete](git-add-git-commit.png)

Infrastructure push origin main lab custom setup main branch
![Git Apply Complete](git-push-success-lab.png)



---

## What I Learned From Building This Hands On Project

1) By building this project from scratch instead of just clicking buttons on a screen, I learned the core rules of how the modern internet works:

1.1) Building with Code (IaC): Instead of manually setting up servers by clicking around a website, I learned how to write down instructions in a text file like a recipe. Tools like Terraform read this recipe to build, double-check, and safely create a massive tech setup automatically with just a few typed commands.

1.2) Dividing Network Space (CIDR): Think of buying a giant piece of land. You can't just build houses anywhere; you have to draw borders and create organized neighborhoods. I learned how to slice a huge network space into smaller, neat blocks so that different parts of an application don't get mixed up or crash into each other.

1.3) One-Way vs Two-Way Doors (Gateways): I learned how to build smart boundaries. A public webpage needs a "two-way door" (Internet Gateway) so anyone on the street can walk in. But our secret backend servers only get a "one-way turnstile" (NAT Gateway). They can push through it to go out and download updates, but absolutely no one on the outside internet can use that door to pull their way in.

1.4) Security Guards vs Front Desk Clerks (OSI Layer 4 vs 7): I learned that internet traffic uses different levels of intelligence.

1.4.1)A basic firewall is like a building security guard who only looks at the ID card number on the box.

1.4.2)A Load Balancer is like a smart front desk concierge who actually opens the letter, reads the message, and directs the guest to the exact room they need.

1.5)Hiding the Core Assets (Blast-Radius Isolation): If a bank leaves all its money on tables in the front lobby, it will get robbed. I learned how to keep the most important parts of an application hidden deep inside a private vault. By removing public internet addresses from our app servers, hackers have absolutely nothing to target from the outside world.

---
*Project hands-on by Fadzlan bin Omar — Focused on Cloud Infrastructure, Systems Administration, and DevOps Engineering.*
