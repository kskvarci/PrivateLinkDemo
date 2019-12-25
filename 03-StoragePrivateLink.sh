#!/bin/bash

#include parameters file
source ./params.sh

#_______________________________________________________________________________
# Create a storage account in the resource group 
az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_RAGRS --kind StorageV2
# Enable access restrictions with no whitelisted IPs or networks. This will allow access only from the private endpoints.
az storage account update --name $storageAccountName --resource-group $resourceGroupName --default-action Deny

#_______________________________________________________________________________
# create private endpoints in the target subnets tied to the storage server resource
storageID=$(az storage account show --resource-group $resourceGroupName --name $storageAccountName --query 'id' -o tsv)
az network private-endpoint create --name "$storageAccountName-plink" --resource-group $resourceGroupName --vnet-name $hubVnetName --subnet $subnetName --private-connection-resource-id $storageID --group-ids blob --connection-name "$storageAccountName-plink"

#_______________________________________________________________________________
# DNS Setup (Optional)
# Create the zone. This zone name comes from a list of recommended names. The name of this zone matters! 
# See https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview#dns-configuration for details.
# TODO explain chained CNAME records and split horizon DNS
az network private-dns zone create --resource-group $resourceGroupName --name  "privatelink.blob.core.windows.net" 
# link to hub
az network private-dns link vnet create --resource-group $resourceGroupName --zone-name  "privatelink.blob.core.windows.net" --name "$hubVnetName-DNSLink" --virtual-network $hubVnetName --registration-enabled false 
# Query for the Private Endpoint network interface IDs
networkInterfaceId=$(az network private-endpoint show --name "$storageAccountName-plink" --resource-group $resourceGroupName --query 'networkInterfaces[0].id' -o tsv)
# Grab the private IPs
privateIp=$(az resource show --ids $networkInterfaceId --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
#Create DNS records 
az network private-dns record-set a create --name "$storageAccountName" --zone-name privatelink.blob.core.windows.net --resource-group $resourceGroupName  
az network private-dns record-set a add-record --record-set-name "$storageAccountName" --zone-name privatelink.blob.core.windows.net --resource-group $resourceGroupName -a $privateIp
