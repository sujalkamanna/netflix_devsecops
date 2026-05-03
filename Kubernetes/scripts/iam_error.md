# 📄 `eks-iam-oidc-setup.md`

---

# 🚀 EKS IAM Role Binding + OIDC Setup Guide

---

## 🔐 1. Prerequisites (VERIFY FIRST)

Ensure the following tools are installed:

### ✔ Check AWS CLI

```bash
aws --version
```

### ✔ Check kubectl

```bash
kubectl version --client
```

### ✔ Check eksctl

```bash
eksctl version
```

👉 Required tools:

* AWS CLI (configured)
* kubectl connected to cluster
* eksctl installed
* IAM permissions enabled ([OneUptime][1])

---

## ⚙️ 2. Configure AWS Credentials

```bash
aws configure
```

Provide:

* Access Key
* Secret Key
* Region → `ap-south-1`

---

## 🔗 3. Connect kubectl to EKS Cluster

```bash
aws eks update-kubeconfig --region ap-south-1 --name EKS_CLUSTER
```

---

## 🔍 4. Verify Cluster Access

```bash
kubectl get nodes
```

👉 If nodes are visible → connection is working

---

## 🔐 5. Check Existing OIDC Provider

```bash
aws eks describe-cluster \
  --name EKS_CLUSTER \
  --query "cluster.identity.oidc.issuer" \
  --output text
```

👉 This returns OIDC URL

---

## 🔐 6. Enable OIDC Provider (MANDATORY)

```bash
eksctl utils associate-iam-oidc-provider \
  --cluster EKS_CLUSTER \
  --region ap-south-1 \
  --approve
```

👉 This creates IAM OIDC provider for cluster

---

## 🔍 7. Verify OIDC Provider

```bash
aws iam list-open-id-connect-providers
```

👉 You should see OIDC ARN

---

## 👤 8. Check Existing IAM Mappings

```bash
eksctl get iamidentitymapping \
  --cluster EKS_CLUSTER \
  --region ap-south-1
```

👉 This reads `aws-auth` ConfigMap

---

## ➕ 9. Create IAM ROLE Mapping

```bash
eksctl create iamidentitymapping \
  --cluster EKS_CLUSTER \
  --region ap-south-1 \
  --arn arn:aws:iam::ACCOUNT_ID:role/YOUR_ROLE \
  --username your-user \
  --group system:masters \
  --no-duplicate-arns
```

---

## ➕ 10. Create IAM USER Mapping (Optional)

```bash
eksctl create iamidentitymapping \
  --cluster EKS_CLUSTER \
  --region ap-south-1 \
  --arn arn:aws:iam::ACCOUNT_ID:user/YOUR_USER \
  --username your-user \
  --group system:masters \
  --no-duplicate-arns
```

---

## 🔍 11. Verify Mapping

```bash
eksctl get iamidentitymapping \
  --cluster EKS_CLUSTER \
  --region ap-south-1
```

---

# 🧠 Important Concepts

### 🔹 OIDC

* Enables IAM roles for Kubernetes service accounts
* Required for IRSA
* Not enabled by default ([AWS Documentation][5])

---

### 🔹 IAM Identity Mapping

* Maps IAM → Kubernetes RBAC
* Stored in `aws-auth` ConfigMap

---

# 🔥 Final Flow

```text
AWS IAM User/Role
        ↓
eksctl create iamidentitymapping
        ↓
aws-auth ConfigMap
        ↓
Kubernetes RBAC
        ↓
Cluster Access ✅
```

---

# ⚠️ Common Errors

### ❌ kubectl not working

👉 Run:

```bash
aws eks update-kubeconfig --region ap-south-1 --name EKS_CLUSTER
```

---

### ❌ OIDC error

👉 Run:

```bash
eksctl utils associate-iam-oidc-provider --cluster EKS_CLUSTER --approve
```

---

### ❌ Access denied

👉 Check:

* IAM permissions
* aws-auth mapping

---

# 💯 Final Verdict

This guide ensures:

* ✅ All prerequisites verified
* ✅ OIDC correctly enabled
* ✅ IAM mapped to Kubernetes
* ✅ Fully production-ready setup

---