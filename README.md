# ProxyCannon-NG

## Setup
The control-server is a OpenVPN server that your workstation will connect to. This server always remains up. Exit-nodes are systems connected to the control-server that provides load balancing and multiple source IP addresses. Exit-nodes can scale up and down to suite your needs.

### AWS (setup the control-server)
#### 1. Create a separate SSH key pair
1. In the AWS console, go to **services** (upper left)
2. Select **EC2** under the Compute section.
3. Select **Key Pairs** in the nav on the left.
4. Select **Create Key Pair** and name it 'proxycannon'.
5. Download and save the key to **~/.ssh/proxycannon.pem**

#### 2. Launch the control-server instance
1. Launch (1) Ubuntu Server t2-micro instance and use the "proxycannon" keypair.
2. Login to the control-server and download proxycannon-ng: 

    ```
    git clone https://github.com/meihsiutung013/proxycannon-ng.git
    cd proxycannon-ng/setup
    chmod +x ./install.sh
    sudo ./install.sh
    chmod +x proxycannon-ng/nodes/aws/add_route.bash
    chmod +x proxycannon-ng/nodes/aws/del_route.bash
    ```

#### 3. Create a new IAM user, set the needed permissions, and copy over your keys. It's quick:
1. In the AWS console, go to **services** (upper left)
2. Select **IAM** under the Security, Identity & Compliance section
3. In IAM, select **Users** in the nav on the left.
4. Select **Add user**
5. Fill out a User name, and for access type, select programmatic access. Click **Next**.
6. Select the tab/box that's labeled **Attach existing policies directly**. Add the following policy: AmazonEC2FullAccess. Click **Next**, than **Create user**
7. Copy the access key and secret for the control-server and paste it in ~/.aws/credentials ex:
    ```
    [default]
    aws_access_key_id = REPLACE_WITH_YOUR_OWN
    aws_secret_access_key = REPLACE_WITH_YOUR_OWN
    region = us-east-2
    ```
    ```
    scp -i "proxycannon.pem" "C:\Users\Tung\.aws\credentials" ubuntu@ec2-18-217-113-138.us-east-2.compute.amazonaws.com:/home/ubuntu/.aws/credentials
    ```

#### 4. Setup terraform
Perform the following on the control-server:
1. Copy your proxycannon.pem SSH key into `~/.ssh/proxycannon.pem`

    Copy proxycannon.pem SSH key from windows to proxycannon control server:

    ```
    scp -i "proxycannon.pem" "C:\Users\Tung\.ssh\proxycannon.pem" ubuntu@ec2-18-217-113-138.us-east-2.compute.amazonaws.com:/home/ubuntu/.ssh/proxycannon.pem
    ```
    In our SSH session on the Proxycannon Control Server:

    ```
    sudo cp -v /home/ubuntu/.ssh/proxycannon.pem /root/.ssh/
    sudo chown -R root:root /root/.ssh
    sudo chmod 600 /root/.ssh/proxycannon.pem
    ```

2. cd into `proxycannon-ng/nodes/aws` and edit the `variables.tf` file updating it with the **subnet_id**. This is the same subnet_id that your control server is using. You can get this value from the AWS console when viewing the details of the control-server instance. Defining this subnet_id makes sure all launched exit-nodes are in the same subnet as your control server.

    ```
    nano /proxycannon-ng/nodes/aws/variables.tf
    ```
    ![alt text](image.png)

3. Run `terraform init` to download the AWS modules. (you only need to do this once)

    ```
    cd /proxycannon-ng/nodes/aws/
    terraform init
    terraform apply --auto-approve
    ```

#### 5. Copy OpenVPN files to your workstation
Copy the following files from the control-server to the `/etc/openvpn` directory on your workstation:
- ~/proxycannon-client.conf
- /etc/openvpn/easy-rsa/ta.key
- /etc/openvpn/easy-rsa/pki/ca.crt
- /etc/openvpn/easy-rsa/pki/issued/client01.crt
- /etc/openvpn/easy-rsa/pki/private/client01.key  

    ```
    scp -i "proxycannon.pem" ubuntu@ec2-18-217-113-138.us-east-2.compute.amazonaws.com:~/ta.key C:\Users\Tung\OpenVPN\config\
    ```
    ```
    scp -i "proxycannon.pem" ubuntu@ec2-18-217-113-138.us-east-2.compute.amazonaws.com:~/ca.crt C:\Users\Tung\OpenVPN\config\
    ```
    ```
    scp -i "proxycannon.pem" ubuntu@ec2-18-217-113-138.us-east-2.compute.amazonaws.com:~/client01.crt C:\Users\OpenVPN\config\
    ```
    ```
    scp -i "proxycannon.pem" ubuntu@ec2-18-217-113-138.us-east-2.compute.amazonaws.com:~/client01.key C:\Users\OpenVPN\config\
    ```

Test OpenVPN connectivity from your workstation by running:
```
openvpn --config proxycannon-client.conf
```

**Setup Completed! yay!** From now on you'll only need to connect to the VPN to use proxycannon-ng. The next section details how to add and remove exit-nodes (source IPs):

## Managing exit-nodes
Scaling of exit-nodes is controlled on the control-server using terraform.
### Scale up exit-nodes
To create AWS exit-nodes, do the following:
1. cd into `proxycannon-ng/nodes/aws`
2. Edit the count value in `variables.tf` to the number of exit-nodes (source IPs) you'd like
3. run `terraform apply` to launch the instances.

### Scale down exit-nodes
If you want to stop all exit-nodes run `terraform destroy`.  
OR  
Scaling down exit-nodes can be done by reducing the count value in `variables.tf` and running `terraform apply` again. Terraform will automatically remove X number of exit-node instances.  

---

### Developers:  

[@jarsnah12](https://www.twitter.com/jarsnah12) - original proxycannon v1 author  
[@w9hax](https://www.twitter.com/w9hax) - mad openVPN skillz  
[@caseycammilleri](https://www.twitter.com/caseycammilleri) - Gets lost deep in iptables  
[@jaredhaight](https://twitter.com/jaredhaight) - Streamlining install and a ton of improvements

Special thanks to @i128 (@jarsnah12 on twitter) for developing the original proxycannon tool that is our inspirartion.

### Known Issues and Troublshooting
See [Wiki](https://github.com/proxycannon/proxycannon-ng/wiki)

