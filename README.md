# OOTB-DIH-k8s-Provisioning
*Out of the Box DIH Kubernetes Provisioning*


## Description and Concepts
This procedure is a step-by-step guide to install a DIG cluster on AWS EKS infrastructure.
* EKS: Amazon Elastic Kubernetes Service
* DIH Umbrella: A set of scripts that comprise a complete / partial suite of DIH services

<br>

## Prerequisties
* ssh key (OOTB-DIH-Provisioning.pem)
* AWS credentials

<br>


## Procedures
### Creating a Jumper machine

1. Login to AWS console
2. Select Ireland region (eu-west-1)
3. Select EC2 
4. Move to Instances page
5. On the top right corner click on the orange button (press the down arrow)
6. Click on 'Launch instance from template'
7. In Choose a launch template - search for 'CSM-LAB-EKS-JUMPER-template' (lt ID: lt-079d823907147c80b)
8. Scroll down to Key pair, choose key or create a new one.
9. Scroll down to 'Resource tags' and modify the 'Name' tag. It's high recommended to concatenate your name (i.e: CSM-LAB-Jumper-James)
10. Click on 'Launch instance' orange button.
11. You should see a note like 'Successfully initiated launch of instance (i-xxxxxxxxxx)', click the link to move to ec2 instance page
12. Wait a few minutes for the instance to be available, locate your instance public ip.
13. Use pem file (ssh private key) from step #8, make sure to grant this file the right permissions (chmod 400 file.pem).
14. Connect to your jumper machine via: `ssh -i "file.pem" centos@aws-instance-public-ip`
15. Run the command `./run.sh`

### Creating an EKS cluster on AWS

1. `cd OOTB-DIH-k8s-provisioning`
2. Run: `./initGS-Lab.sh` and follow the instructions

### Installing the DIH umbrella on EKS
**\* Note! - EKS must already be available to successfully deploy the umbrella\***

1. `cd OOTB-DIH-k8s-provisioning/scripts`
2. Run `./install-dih-umbrella.sh`

The umbrella will deploy the following:
1. An Ingress controller on EKS
2. A DIH cluster
3. A simple (single partition) space
4. A Data Gateway service
5. A simple space feeder.

### Uninstalling the DIH umbrella ONLY (does not destroy the EKS infrastructure)
1. `cd OOTB-DIH-k8s-provisioning/scripts`
2. Run `./uninstall-dih-umbrella.sh`

### Purge EVERYTHING! (the DIH umbrella components + the EKS itself)
1. `cd OOTB-DIH-k8s-provisioning/scripts`
2. run `./destroy-eks-lab.sh`