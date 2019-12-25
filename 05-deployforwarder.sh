# !/bin/bash

#include parameters file
source ./params.sh

#_______________________________________________________________________________
# Deploy an Ubuntu VM and install Squid Proxy
az vm create --name "BindForwarder" --resource-group $resourceGroupName --authentication-type "ssh" --admin-username $userName --boot-diagnostics-storage "" --location $location --nsg "" --image "Canonical:UbuntuServer:18.04-LTS:latest" --size "Standard_DS2" --ssh-key-value "$sshKey" --subnet "dns-subnet" --vnet-name $hubVnetName --custom-data configforwarder.sh
interface=$(az vm show --resource-group $resourceGroupName --name "BindForwarder" --query 'networkProfile.networkInterfaces[0].id' -o tsv)
privateIP=$(az resource show --ids $interface --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)

#_______________________________________________________________________________
# Update the spoke networks to reference the private IP of the bind server.
az network vnet update --resource-group $resourceGroupName --name $spokeVnetName --dns-servers $privateIP
az network vnet update --resource-group $resourceGroupName --name $spoke2VnetName --dns-servers $privateIP