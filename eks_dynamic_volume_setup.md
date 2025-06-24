# EKS Dynamic Volume Setup - Complete Guide

This guide walks you through setting up dynamic volume provisioning for Amazon EKS clusters using the EBS CSI driver.

## Prerequisites

- EKS cluster running
- `kubectl` configured to access your cluster
- AWS CLI configured with appropriate permissions
- Access to AWS CloudShell or terminal with AWS CLI

## Step 1: Clean Start

```bash
CLUSTER_NAME=your-cluster-name-here
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Delete any existing PVCs
kubectl delete pvc --all 2>/dev/null || true

# Delete addon if exists
aws eks delete-addon --cluster-name $CLUSTER_NAME --addon-name aws-ebs-csi-driver 2>/dev/null || true

# Wait for deletion
sleep 60
```

## Step 2: Install eksctl (if not available)

```bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

## Step 3: Create EBS CSI Driver Add-on

```bash
# Create EBS CSI addon with automatic role creation
eksctl create addon --name aws-ebs-csi-driver --cluster $CLUSTER_NAME --force
```

## Step 4: Verify Installation

```bash
# Check addon status
kubectl get pods -n kube-system | grep ebs-csi

# Should see 2 controller pods and several node pods running
```

## Step 5: Create Storage Classes

### Default Storage Class (WaitForFirstConsumer)
```bash
kubectl apply -f - << 'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp2
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF
```

### Immediate Binding Storage Class
```bash
kubectl apply -f - << 'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2-immediate
provisioner: ebs.csi.aws.com
parameters:
  type: gp2
  fsType: ext4
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF
```

## Step 6: Test Dynamic Volume Creation

### Test with WaitForFirstConsumer (Default Behavior)

Create a PVC:
```bash
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: gp2
EOF
```

Create a pod to use the PVC:
```bash
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: test
    image: nginx
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: test-pvc
EOF
```

Check status:
```bash
kubectl get pvc
kubectl get pod test-pod
```

### Test with Immediate Binding

```bash
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: immediate-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: gp2-immediate
EOF

kubectl get pvc immediate-pvc
```

## Step 7: Verify Volumes

```bash
# Check PVCs
kubectl get pvc

# Check Persistent Volumes
kubectl get pv

# Check in AWS Console - EC2 > Elastic Block Store > Volumes
```

## Step 8: Clean Up Test Resources

```bash
kubectl delete pod test-pod
kubectl delete pvc test-pvc immediate-pvc
```

## Understanding Volume Binding Modes

### WaitForFirstConsumer
- **Behavior**: PVC stays in `Pending` status until a pod tries to use it
- **Advantage**: Volume is created in the same Availability Zone as the pod
- **Use Case**: Default behavior, best for most applications

### Immediate
- **Behavior**: Volume is provisioned immediately when PVC is created
- **Advantage**: Volume is ready before pod creation
- **Use Case**: When you need volumes to be pre-provisioned

## Troubleshooting

### PVC Stays Pending
1. Check events: `kubectl describe pvc <pvc-name>`
2. Check EBS CSI driver logs: `kubectl logs -n kube-system -l app=ebs-csi-controller`
3. Verify service account has IAM role: `kubectl describe sa ebs-csi-controller-sa -n kube-system`

### Common Issues
- **No IAM role**: The service account needs proper IAM permissions
- **OIDC not configured**: Cluster needs OIDC identity provider
- **Wrong storage class**: Ensure you're using the correct provisioner (`ebs.csi.aws.com`)

## Best Practices

1. **Use gp3 volumes** for better performance and cost:
   ```yaml
   parameters:
     type: gp3
   ```

2. **Enable volume expansion**:
   ```yaml
   allowVolumeExpansion: true
   ```

3. **Use WaitForFirstConsumer** for multi-AZ clusters to ensure proper placement

4. **Monitor EBS costs** - volumes persist even when pods are deleted

## Summary

You now have dynamic volume provisioning configured for your EKS cluster. Any PVC you create will automatically provision EBS volumes. The EBS CSI driver handles the lifecycle management of these volumes automatically.

**Remember to replace `your-cluster-name-here` with your actual cluster name!**