systemctl stop docker
cp /$FOLDER/docker.service /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker

# Check the status of the Docker service
STATUS=$(systemctl is-active docker)

# Get the count of running containers
CONTAINER_COUNT=$(docker ps -q | wc -l)

# Display the status and container count
echo "Docker service status: $STATUS"
echo "Number of running containers: $CONTAINER_COUNT"
