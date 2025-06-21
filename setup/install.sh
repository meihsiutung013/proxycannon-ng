#! /bin/sh
set -e  # Detiene el script si algo falla

# proxycannon-ng

###################
# install software
###################
apt update
apt -y upgrade
apt -y install unzip git openvpn easy-rsa

# install terraform
wget https://releases.hashicorp.com/terraform/1.12.2/terraform_1.12.2_linux_amd64.zip
unzip terraform_1.12.2_linux_amd64.zip
cp terraform /usr/bin/
rm -f terraform_1.12.2_linux_amd64.zip
rm -rf terraform

# crea directorio para AWS credentials sólo si no existe
[ -d ~/.aws ] || mkdir ~/.aws
[ -f ~/.aws/credentials ] || touch ~/.aws/credentials

################
# setup openvpn
################
# cp configs
cp configs/node-server.conf /etc/openvpn/node-server.conf
cp configs/client-server.conf /etc/openvpn/client-server.conf
cp configs/proxycannon-client.conf ~/proxycannon-client.conf

# setup ca and certs - updated for Easy-RSA 3.x
mkdir -p /etc/openvpn/ccd

make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa

# Inicializar estructura PKI
./easyrsa init-pki

# Construir la CA (te pedirá info, responde según lo necesario)
echo -e "\n" | ./easyrsa build-ca nopass

# Generar y firmar request para el servidor (Common Name = "server")
printf "server\n" | ./easyrsa gen-req server nopass
yes yes | ./easyrsa sign-req server server

# Generar y firmar para los clientes (Common Name = "client0X")
for x in $(seq -f "%02g" 1 10); do
  printf "client${x}\n" | ./easyrsa gen-req client${x} nopass
  yes yes | ./easyrsa sign-req client client${x}
done

# Node01 (Common Name = "node01")
printf "node01\n" | ./easyrsa gen-req node01 nopass
yes yes | ./easyrsa sign-req client node01

# Generar parámetros DH
./easyrsa gen-dh

# Generar ta.key
openvpn --genkey secret /etc/openvpn/easy-rsa/ta.key

echo "Certificados y claves generados en /etc/openvpn/easy-rsa/pki/"

####################
# start services
####################
systemctl start openvpn@node-server.service
systemctl start openvpn@client-server.service

EIP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
sed -i "s/REMOTE_PUB_IP/$EIP/" ~/proxycannon-client.conf

###################
# setup networking
###################
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.fib_multipath_hash_policy=1

echo "50        loadb" | tee -a /etc/iproute2/rt_tables

ip rule add from 10.10.10.0/24 table loadb
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

############################
# post install instructions
############################

echo
echo "=============================================="
echo "COPIA ESTOS ARCHIVOS A TU WORKSTATION:"
echo "  /etc/openvpn/easy-rsa/ta.key"
echo "  /etc/openvpn/easy-rsa/pki/ca.crt"
echo "  /etc/openvpn/easy-rsa/pki/issued/client01.crt"
echo "  /etc/openvpn/easy-rsa/pki/private/client01.key"
echo "  ~/proxycannon-client.conf"
echo "=============================================="

echo "####################### OpenVPN client config [proxycannon-client.conf] ################################"
cat ~/proxycannon-client.conf

echo "####################### AGREGA tus AWS API keys y SSH keys en las siguientes rutas ###################"
echo "Copia tu llave SSH privada de AWS a ~/.ssh/proxycannon.pem y chmod 600 ~/.ssh/proxycannon.pem"
echo "Coloca tu aws api id y key en ~/.aws/credentials"

echo "[!] Recuerda ejecutar 'terraform init' en nodes/aws la primera vez."