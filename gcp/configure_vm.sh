# Define variables
PROJECT_ID="id"
ZONE="us-central1-a"
REGION="us-central1"
DOCKER_IMAGE_NAME="gcp-petclinic"
ACCOUNT="accesstogcr@$PROJECT_ID.iam.gserviceaccount.com"

# Copy files
gcloud compute scp ~/cloud-tasks-internship/gcp/key-file.json my-vm:~/key-file.json
gcloud compute scp ~/cloud-tasks-internship/gcp/run_docker.sh my-vm:~/run_docker.sh

# Authenticate with Docker
gcloud auth activate-service-account $ACCOUNT --key-file=key-file.json
gcloud auth print-access-token | docker login -u oauth2accesstoken \
    --password-stdin https://$REGION-docker.pkg.dev

gcloud compute ssh my-vm --project=$PROJECT_ID --zone=$ZONE << EOF
chmod +x ~/run_docker.sh
./run_docker.sh
EOF

sleep 15

# Verify accessibility
VM_IP=$(gcloud compute instances describe my-vm --project=$PROJECT_ID --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "Your application is accessible at: http://$VM_IP:8080"

# When you're done with the application, you can remove the resources
read -p "Press Enter to delete resources..."

# Delete the VM instance
gcloud compute instances delete my-vm --project=$PROJECT_ID --zone=$ZONE --delete-disks=all

# Delete the GCR repository
gcloud artifacts repositories delete my-gcr-repo --location=$REGION --project=$PROJECT_ID --force

# Delete the VPC and subnet (use with caution, as this can remove all associated resources)
gcloud compute networks subnets delete my-subnet --network=my-vpc --project=$PROJECT_ID --region=$REGION
gcloud compute networks delete my-vpc --project=$PROJECT_ID
