#!/bin/bash

#include parameters file
source ./params.sh

#_______________________________________________________________________________
# SQL Setup
# Create a logical SQL server in the resource group 
az sql server create --name $sqlServerServerName --resource-group $resourceGroupName --location $location --admin-user $sqlServerAdminUname --admin-password $sqlServerAdminPword
 
# Create a database in the server with zone redundancy as false 
az sql db create --resource-group $resourceGroupName --server $sqlServerServerName --name $sqlServerDBName --sample-name AdventureWorksLT --edition GeneralPurpose --family Gen4 --capacity 1

#_______________________________________________________________________________
# create private endpoint tied to the SQL server resource
sqlServerID=$(az sql server show --resource-group $resourceGroupName --name $sqlServerServerName --query 'id' -o tsv)
az network private-endpoint create --name "$sqlServerServerName-plink" --resource-group $resourceGroupName --vnet-name $hubVnetName --subnet $subnetName --private-connection-resource-id $sqlServerID --group-ids sqlServer --connection-name "$sqlServerServerName-plink"

#_______________________________________________________________________________
# DNS Setup (Optional)
# Create the zone. This zone name comes from a list of recommended names. The name of this zone matters! 
# See https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview#dns-configuration for details.
az network private-dns zone create --resource-group $resourceGroupName --name  "privatelink.database.windows.net" 
# link to hub
az network private-dns link vnet create --resource-group $resourceGroupName --zone-name  "privatelink.database.windows.net" --name "$hubVnetName-DNSLink" --virtual-network $hubVnetName --registration-enabled false 
# Query for the Private Endpoint network interface IDs
networkInterfaceId=$(az network private-endpoint show --name "$sqlServerServerName-plink" --resource-group $resourceGroupName --query 'networkInterfaces[0].id' -o tsv)
# Grab the private IPs
privateIp=$(az resource show --ids $networkInterfaceId --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
#Create DNS records 
az network private-dns record-set a create --name "$sqlServerServerName" --zone-name privatelink.database.windows.net --resource-group $resourceGroupName  
az network private-dns record-set a add-record --record-set-name "$sqlServerServerName" --zone-name privatelink.database.windows.net --resource-group $resourceGroupName -a $privateIp
