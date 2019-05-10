### Install Pre-reqs.
yum install epel-release jq curl -y

### Add sensu Repo
echo '[sensu]
name=sensu
baseurl=https://sensu.global.ssl.fastly.net/yum/$releasever/$basearch/
gpgkey=https://repositories.sensuapp.org/yum/pubkey.gpg
gpgcheck=1
enabled=1' | sudo tee /etc/yum.repos.d/sensu.repo

### Install Redis
yum install redis -y

### Change Redis Protected Mode
sed -i 's/protected-mode yes/protected-mode no/' /etc/redis.conf

### Enable & Start Redis
sudo systemctl enable redis
sudo systemctl start redis

### Install Erlang
yum install https://github.com/rabbitmq/erlang-rpm/releases/download/v20.1.7.1/erlang-20.1.7.1-1.el7.centos.x86_64.rpm -y

### Install RabbitMq-Server
yum install https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.12/rabbitmq-server-3.6.12-1.el7.noarch.rpm -y

### Create Sensu folder structure
cd /etc/
mkdir sensu
cd sensu
mkdir conf.d
cd conf.d/

### Create RabbitMQ config file
echo '{
  "rabbitmq": {
    "host": "127.0.0.1",
    "port": 5672,
    "vhost": "/sensu",
    "user": "sensu",
    "password": "secret",
    "heartbeat": 30,
    "prefetch": 50
  }
}' | sudo tee /etc/sensu/conf.d/rabbitmq.json

### Enable & Start RabbitMQ
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server

### Create RabbitMQ user permissions
sudo rabbitmqctl add_vhost /sensu
sudo rabbitmqctl add_user sensu secret
sudo rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"

### Install Dashboard (uchiwa)
sudo yum install sensu uchiwa -y

### Create Client config file
echo '{
  "client": {
    "environment": "development",
    "subscriptions": [
      "vm"
    ]
  }
}'|sudo tee /etc/sensu/conf.d/client.json

### Create Dashboard (uchiwa) config file.
echo '{
   "sensu": [
     {
       "name": "NoelTest",
       "host": "127.0.0.1",
       "port": 4567
     }
   ],
   "uchiwa": {
     "host": "0.0.0.0",
     "port": 3000
   }
 }'|sudo tee /etc/sensu/uchiwa.json

### Make sure that the sensu user owns all of the Sensu configuration files
sudo chown -R sensu:sensu /etc/sensu

### Enable & Start sensu-server, sensu-api & sensu-client
sudo systemctl enable sensu-{server,api,client}
sudo systemctl start sensu-{server,api,client}

### Enable & Start Dashboard (uchiwa)
sudo systemctl enable uchiwa
sudo systemctl start uchiwa

### Get System IP address
IP=$(ifconfig |grep inet |awk '{print $2}' |grep -v 127)

### Installation Complete.
clear
echo "Sensu Install Complete"
echo -ne "Please wait 2 minutes... Then visit: "
echo  $IP":3000"

sleep 5
#to check if its working correctly
curl -s http://127.0.0.1:4567/clients | jq .

#to check status of all
#systemctl status sensu-{server,api,client} uchiwa redis rabbitmq-server
