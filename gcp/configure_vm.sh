# Define variables
PROJECT_ID="id"
ZONE="us-central1-a"
REGION="us-central1"
DOCKER_IMAGE_NAME="gcp-petclinic"

gcloud compute scp ~/gcp/run_docker.sh my-vm:~/run_docker.sh

gcloud compute ssh my-vm --project=$PROJECT_ID --zone=$ZONE << EOF
chmod +x ~/run_docker.sh
./run_docker.sh
EOF

sleep 30

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
