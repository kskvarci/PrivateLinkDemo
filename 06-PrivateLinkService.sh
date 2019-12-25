# !/bin/bash

#include parameters file
source ./params.sh

#TODO - add a public IP and rule for outgoing NAT.. Otherwise machines will not bootstrap.


# Deploy a standard Internal Load Balancer into Spoke 1
az network lb create --resource-group $resourceGroupName --name $ilbName --sku standard --vnet-name $spokeVnetName --subnet "workload-subnet" --frontend-ip-name $ilbFrontEnd --backend-pool-name $ilbBackEndPool 


# Create a health probe
az network lb probe create --resource-group $resourceGroupName --lb-name $ilbName --name $ilbHealthProbe --protocol tcp --port 80

# Create a load balancer rule
az network lb rule create --resource-group $resourceGroupName --lb-name $ilbName --name HTTPRule --protocol tcp --frontend-port 80 --backend-port 80 --frontend-ip-name $ilbFrontEnd --backend-pool-name $ilbBackEndPool --probe-name $ilbHealthProbe

# Create NICs for hte backend servers
for i in `seq 1 2`; do
  az network nic create --resource-group $resourceGroupName --name ServiceVMNic$i --vnet-name $spokeVnetName --subnet "workload-subnet" --lb-name $ilbName --lb-address-pools $ilbBackEndPool --network-security-group ""
done

# Create an availability set
az vm availability-set create --resource-group $resourceGroupName --name $availabilitySetName

# Create backend servers running NGINX
for i in `seq 1 2`; do
  az vm create --resource-group $resourceGroupName --name ServiceVM$i --availability-set $availabilitySetName --nics ServiceVMNic$i --image "Canonical:UbuntuServer:18.04-LTS:latest" --authentication-type "ssh" --admin-username $userName --boot-diagnostics-storage "" --location $location --size "Standard_DS2" --ssh-key-value "$sshKey" --custom-data configwebserver.sh
done

# Disable Privatelink service network policies
az network vnet subnet update --name "workload-subnet" --resource-group $resourceGroupName --vnet-name $spokeVnetName --disable-private-link-service-network-policies true

# Create a Private Link Service
az network private-link-service create --resource-group $resourceGroupName --name $custPrivateLinkServiceName --vnet-name $spokeVnetName --subnet "workload-subnet" --lb-name $ilbName --lb-frontend-ip-configs $ilbFrontEnd --location $location

# Create a private endpoint to the new service in the second spoke
serviceID=$(az network private-link-service show --resource-group $resourceGroupName --name $custPrivateLinkServiceName --query 'id' -o tsv)

az network private-endpoint create --resource-group $resourceGroupName --name "$custPrivateLinkServiceName-plink" --vnet-name $spoke2VnetName --subnet $subnetName --private-connection-resource-id $serviceID --connection-name "$custPrivateLinkServiceName-plink" --location $location