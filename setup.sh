sudo apt update
sudo apt --yes install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt --yes install docker-ce
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo docker-compose –version

echo "Docker done" >> /local/mertlogs

### create extrafs
## stop docker to update work dir
sudo systemctl stop docker.service
sudo systemctl stop docker.socket

## bash users
for user in $(ls /users)
do
	sudo chsh $user --shell /bin/bash
done

echo "Checkpoint" >> /local/mertlogs

## create extrafs
sudo mkdir /mydata
sudo /usr/local/etc/emulab/mkextrafs.pl /mydata
sudo chmod ugo+rwx /mydata
SEARCH_STRING="ExecStart=/usr/bin/dockerd -H fd://"
REPLACE_STRING="ExecStart=/usr/bin/dockerd -g /mydata -H fd://"
sudo sed -i "s#$SEARCH_STRING#$REPLACE_STRING#" /lib/systemd/system/docker.service
sudo rsync -aqxP /var/lib/docker/ /mydata
sudo systemctl daemon-reload
sudo systemctl start docker
ps aux | grep -i docker | grep -v grep >> /local/mertlogs
echo "Check above for directory on where docker works" >> /local/mertlogs


cd /local
git clone https://github.com/mtoslalibu/astraea-scripts.git
cd /local

## isntall requirements
sudo apt-get --yes install luarocks
sudo luarocks install luasocket
sudo apt --yes install python3.8
sudo apt-get --yes install libssl-dev
sudo apt-get --yes install libz-dev
sudo apt-get --yes install python3-pip
pip3 install aiohttp

echo "Requirements installed" >> /local/mertlogs

## install social network 
cd /local
git clone https://github.com/mtoslalibu/DeathStarBench.git

## build your own version
cd /local/DeathStarBench/socialNetwork/docker/thrift-microservice-deps/cpp
sudo docker build -t mert/thrift-microservice-deps:xenial .
cd /local/DeathStarBench/socialNetwork
sudo docker build -t mert/social-network-microservices:latest .

echo "Built social network from source" >> /local/mertlogs

#python3 scripts/init_social_graph.py --graph=socfb-Reed98
#echo "Initialized social graph" >> /local/mertlogs

## build workload
cd wrk2
make

echo "Built wrk2, so now go ahead and boot instances with sudo docker-compose up -d" >> /local/mertlogs

## send email
mail -s "Deathstar instance finished setting up, hooray!" $(geni-get slice_email)
