# GOJEK SSH MONITORING
A client and server program to aggregate and monitor the number of ssh logins on a different remote machines.

## Prerequisites
1. Have latest terraform version installed.
2. A ec2 key-pair is required which you have available with you locally. Add it to the ssh.
```
# e.g. Say, you have gojek_monitoring.pem file in your aws account and in local machine.
ssh-add gojek_monitoring.pem
```
3. Have a pair of AWS credentials and set them as environment variables.
```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```
## Getting Started
### CLONING REPO
- Clone the repo from github.
```
git clone git@github.com:tremendoustj/gojek_ssh_monitoring.git
```
### INITIALIZE TERRAFORM
- Perform the terraform initialization in both client and server. The directory change path are not absolute. Ensure to update the path as per your local checkout.
```
cd gojek_ssh_monitoring/client/deployment
terraform init
cd gojek_ssh_monitoring/client/deployment
terraform init
```
### DEPLOY SERVER AND CLIENT
- Deploy Server. Directory path is only for reference. Please change it as per the local checkout.
```
cd gojek_ssh_monitoring/client/deployment
terraform apply
```
- Server Deploy will ask for 1 parameters i.e. the private key pair name to use to associate with EC2 instance.
```
var.key_pair_name
The EC2 Key Pair to associate with the EC2 Instance for SSH access.
Enter a value: gojek_monitoring.pem`
```
- Deploy Client.  Directory path is only for reference. Please change it as per the local checkout.
```
cd gojek_ssh_monitoring/client/deployment
terraform apply
```
- Client Deploy will ask for 2 parameters i.e. number of instances to launch and the private key pair name to use to associate with EC2 instances.
```
var.instance_count
Number of instances to launch.
Enter a value: 1

var.key_pair_name
The EC2 Key Pair to associate with the EC2 Instance for SSH access.
Enter a value: gojek_monitoring
  ```

### TEST SERVER AND CLIENT
- Test the server by either running below command or open the ip address in browser. You can get the IP address in public-ip file inside server/deployment directory. It should output the dummy data stored on the server in html format.
```
curl http://<SERVER_IP>
```
- Test the client by ssh to the instance and checking if the count has been updated or not for this instance.
```
ssh ubuntu@<CLIENT_IP>
```
### DESTROY SERVER AND CLIENT
```
cd gojek_ssh_monitoring/client/deployment
terraform destroy
cd gojek_ssh_monitoring/client/deployment
terraform destroy
```
