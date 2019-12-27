# !/bin/bash

# include parameters file
source ./params.sh

#_______________________________________________________________________________
# Internal ILB
# Deploy a standard Internal Load Balancer into Spoke 1
az network lb create --resource-group $resourceGroupName --name $ilbName --sku standard --vnet-name $spokeVnetName --subnet "workload-subnet" --frontend-ip-name $ilbFrontEnd --backend-pool-name $ilbBackEndPool

# Create a health probe for port 80
az network lb probe create --resource-group $resourceGroupName --lb-name $ilbName --name $ilbHealthProbe --protocol tcp --port 80

# Create a load balancer rule mapping 80 on the front-end to 80 on the back-end pool
az network lb rule create --resource-group $resourceGroupName --lb-name $ilbName --name HTTPRule --protocol tcp --frontend-port 80 --backend-port 80 --frontend-ip-name $ilbFrontEnd --backend-pool-name $ilbBackEndPool --probe-name $ilbHealthProbe

# By default, VMs w/out pubilc IP's cannot establish outbound connections to the internet when in a backend pool on a standard load balancer.
# Create public IPs on the VM NICs for outbound access so machines can properly bootstrap
for i in `seq 1 2`; do
  az network public-ip create -g $resourceGroupName -n servicevmPublicIP$i --sku Standard
done

# Create NICs for the backend servers. Reference the public IPs and add them to the ILB backend pool.
for i in `seq 1 2`; do
  az network nic create --resource-group $resourceGroupName --name ServiceVMNic$i --vnet-name $spokeVnetName --subnet "workload-subnet" --lb-name $ilbName --lb-address-pools $ilbBackEndPool --network-security-group "" --public-ip-address servicevmPublicIP$i
done

# Create an availability set for the VMs
az vm availability-set create --resource-group $resourceGroupName --name $availabilitySetName

# Create backend servers running NGINX
for i in `seq 1 2`; do
  az vm create --resource-group $resourceGroupName --name ServiceVM$i --availability-set $availabilitySetName --nics ServiceVMNic$i --image "Canonical:UbuntuServer:18.04-LTS:latest" --authentication-type "ssh" --admin-username $userName --boot-diagnostics-storage "" --location $location --size "Standard_DS2" --ssh-key-value "$sshKey" --custom-data configwebserver.sh
done

# Disable Privatelink service network policies for the workload subnet in Spoke 2
# Note: this is different then then the policy change we made for service endoints in 01-DeployVnets.sh
az network vnet subnet update --name "workload-subnet" --resource-group $resourceGroupName --vnet-name $spokeVnetName --disable-private-link-service-network-policies true

# Create a Private Link Service
az network private-link-service create --resource-group $resourceGroupName --name $custPrivateLinkServiceName --vnet-name $spokeVnetName --subnet "workload-subnet" --lb-name $ilbName --lb-frontend-ip-configs $ilbFrontEnd --location $location

# Grab the ID of the Private Link Service
serviceID=$(az network private-link-service show --resource-group $resourceGroupName --name $custPrivateLinkServiceName --query 'id' -o tsv)
# Create a private endpoint to the new service in spoke 2
az network private-endpoint create --resource-group $resourceGroupName --name "$custPrivateLinkServiceName-plink" --vnet-name $spoke2VnetName --subnet $subnetName --private-connection-resource-id $serviceID --connection-name "$custPrivateLinkServiceName-plink" --location $location