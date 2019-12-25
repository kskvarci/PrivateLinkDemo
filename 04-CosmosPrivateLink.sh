#!/bin/bash

#include parameters file
source ./params.sh

#_______________________________________________________________________________
# Create a Cosmos account in the resource group. Currently only available in West Central US, WestUS, North Central US
az cosmosdb create -n $cosmosAccountName -g $resourceGroupName --default-consistency-level Session --locations regionName="$cosmosLocation" isZoneRedundant=False
# Create a cosmos DB
az cosmosdb sql database create -a $cosmosAccountName -g $resourceGroupName -n $cosmosDatabaseName
# Create a container
az cosmosdb sql container create -a $cosmosAccountName -g $resourceGroupName -d $cosmosDatabaseName -n $containerName -p $partitionKey --throughput $throughput
# Enable access restrictions with no whitelisted IPs or networks. This will allow access only from the private endpoints.
az cosmosdb update --name $cosmosAccountName --resource-group $resourceGroupName --enable-virtual-network true

#_______________________________________________________________________________
# create private endpoints in the target subnets tied to the storage server resource
cosmosID=$(az cosmosdb show --resource-group $resourceGroupName --name $cosmosAccountName --query 'id' -o tsv)
az network private-endpoint create --name "$cosmosAccountName-plink" --resource-group $resourceGroupName --vnet-name $hubVnetName --subnet $subnetName --private-connection-resource-id $cosmosID --group-ids Sql --connection-name "$cosmosAccountName-plink"

#_______________________________________________________________________________
# DNS Setup (Optional)
# Create the zone. This zone name comes from a list of recommended names. The name of this zone matters! 
# See https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview#dns-configuration for details.
az network private-dns zone create --resource-group $resourceGroupName --name  "privatelink.documents.azure.com" 
# link to hub
az network private-dns link vnet create --resource-group $resourceGroupName --zone-name  "privatelink.documents.azure.com" --name "$hubVnetName-DNSLink" --virtual-network $hubVnetName --registration-enabled false 
# Query for the Private Endpoint network interface IDs
networkInterfaceId=$(az network private-endpoint show --name "$cosmosAccountName-plink" --resource-group $resourceGroupName --query 'networkInterfaces[0].id' -o tsv)
# Grab the private IPs
privateIp=$(az resource show --ids $networkInterfaceId --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
#Create DNS records 
az network private-dns record-set a create --name "$cosmosAccountName" --zone-name privatelink.documents.azure.com --resource-group $resourceGroupName  
az network private-dns record-set a add-record --record-set-name "$cosmosAccountName" --zone-name privatelink.documents.azure.com --resource-group $resourceGroupName -a $privateIp
