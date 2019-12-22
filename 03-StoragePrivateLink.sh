#!/bin/bash

#include parameters file
source ./params.sh

#_______________________________________________________________________________
# Create a storage account in the resource group 
az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_RAGRS --kind StorageV2

#_______________________________________________________________________________
# create private endpoints in the target subnets tied to the storage server resource
storageID=$(az storage account show --resource-group $resourceGroupName --name $storageAccountName --query 'id' -o tsv)
az network private-endpoint create --name "$storageAccountName-plink" --resource-group $resourceGroupName --vnet-name $spokeVnetName --subnet $subnetName --private-connection-resource-id $storageID --group-ids blob --connection-name "$storageAccountName-plink"
az network private-endpoint create --name "$storageAccountName-plink2" --resource-group $resourceGroupName --vnet-name $spoke2VnetName --subnet $subnetName --private-connection-resource-id $storageID --group-ids blob --connection-name "$storageAccountName-plink2"

#_______________________________________________________________________________
# DNS Setup (Optional)
# Create the zone
az network private-dns zone create --resource-group $resourceGroupName --name  "privatelink.storage.windows.net" 
# link to spokes
az network private-dns link vnet create --resource-group $resourceGroupName --zone-name  "privatelink.storage.windows.net" --name "$spokeVnetName-DNSLink" --virtual-network $spokeVnetName --registration-enabled false
az network private-dns link vnet create --resource-group $resourceGroupName --zone-name  "privatelink.storage.windows.net" --name "$spokeVnetName-DNSLink2" --virtual-network $spoke2VnetName --registration-enabled false 
# link to hub
az network private-dns link vnet create --resource-group $resourceGroupName --zone-name  "privatelink.storage.windows.net" --name "$hubVnetName-DNSLink" --virtual-network $hubVnetName --registration-enabled false 
# Query for the PrivateLink network interface IDs
networkInterfaceId=$(az network private-endpoint show --name "$storageAccountName-plink" --resource-group $resourceGroupName --query 'networkInterfaces[0].id' -o tsv)
networkInterfaceId2=$(az network private-endpoint show --name "$storageAccountName-plink2" --resource-group $resourceGroupName --query 'networkInterfaces[0].id' -o tsv)
# Grab the private IPs
privateIp=$(az resource show --ids $networkInterfaceId --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
privateIp2=$(az resource show --ids $networkInterfaceId2 --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
#Create DNS records 
az network private-dns record-set a create --name $storageAccountName --zone-name privatelink.storage.windows.net --resource-group $resourceGroupName  
az network private-dns record-set a add-record --record-set-name $storageAccountName --zone-name privatelink.storage.windows.net --resource-group $resourceGroupName -a $privateIp
az network private-dns record-set a create --name "$storageAccountName-2" --zone-name privatelink.storage.windows.net --resource-group $resourceGroupName  
az network private-dns record-set a add-record --record-set-name "$storageAccountName-2" --zone-name privatelink.storage.windows.net --resource-group $resourceGroupName -a $privateIp2