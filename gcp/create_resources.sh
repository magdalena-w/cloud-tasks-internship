PROJECT_ID="id"
REGION="us-central1"
ZONE="us-central1-a"
DOCKER_IMAGE_NAME="gcp-petclinic"

# Create a VPC network and subnet
gcloud compute networks create my-vpc --project=$PROJECT_ID --subnet-mode=custom --bgp-routing-mode=regional
gcloud compute networks subnets create my-subnet --network=my-vpc --project=$PROJECT_ID --region=$REGION --range=192.168.0.0/24

# Create a GCR repository
gcloud artifacts repositories create my-gcr-repo --repository-format=docker --location=$REGION --project=$PROJECT_ID

# Create a VM with a public IP
gcloud compute instances create my-vm --project=$PROJECT_ID --zone=$ZONE --image-family=ubuntu-minimal-2004-lts --image-project=ubuntu-os-cloud --machine-type=n1-standard-1 --subnet=my-subnet --create-disk size=10GB
gcloud compute instances add-tags my-vm --tags=http-server,https-server

# Create a firewall rule to allow traffic on port 80
gcloud compute firewall-rules create allow-http --project=$PROJECT_ID --direction=INGRESS --priority=1000 --network=my-vpc --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create allow-ssh --project=$PROJECT_ID --direction=INGRESS --priority=1000 --network=my-vpc --action=ALLOW --rules=tcp:22 --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create allow-docker --project=$PROJECT_ID --direction=INGRESS --priority=1000 --network=my-vpc --action=ALLOW --rules=tcp:8080 --source-ranges=0.0.0.0/0

# Tag your Docker image with the GCR URL
docker tag petclinic gcr.io/$PROJECT_ID/my-gcr-repo/$DOCKER_IMAGE_NAME

# Authenticate Docker with GCR
gcloud auth configure-docker

# Push the image to GCR
docker push gcr.io/$PROJECT_ID/my-gcr-repo/$DOCKER_IMAGE_NAME
