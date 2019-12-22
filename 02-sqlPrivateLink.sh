#!/bin/bash

#include parameters file
source ./params.sh

# disable private endpoint network policies on the privatelink subnet
# --------------------------------------------------------
# Network policies like network security groups (NSG) are not supported for private endpoints. In order to deploy a Private Endpoint on a given subnet,
# an explicit disable setting is required on that subnet. This setting is only applicable for the Private Endpoint. For other resources in the subnet,
# access is controlled based on Network Security Groups (NSG) security rules definition.
# When using the portal to create a private endpoint, this setting is automatically disabled as part of the create process. Deployment using other clients requires an additional step to change this setting.
az network vnet subnet update --name $subnetName --resource-group $resourceGroupName --vnet-name $spokeVnetName --disable-private-endpoint-network-policies true
az network vnet subnet update --name $subnetName --resource-group $resourceGroupName --vnet-name $spoke2VnetName --disable-private-endpoint-network-policies true

# Create a logical SQL server in the resource group 
az sql server create --name $sqlServerServerName --resource-group $resourceGroupName --location $location --admin-user $sqlServerAdminUname --admin-password $sqlServerAdminPword
 
# Create a database in the server with zone redundancy as false 
az sql db create --resource-group $resourceGroupName --server $sqlServerServerName --name $sqlServerDBName --sample-name AdventureWorksLT --edition GeneralPurpose --family Gen4 --capacity 1

# create private endpoints in the target subnets tied to the SQL server resource
sqlServerID=$(az sql server show --resource-group $resourceGroupName --name $sqlServerServerName --query 'id' -o tsv)
az network private-endpoint create --name "$sqlServerServerName-plink" --resource-group $resourceGroupName --vnet-name $spokeVnetName --subnet $subnetName --private-connection-resource-id $sqlServerID --group-ids sqlServer --connection-name "$sqlServerServerName-plink"
az network private-endpoint create --name "$sqlServerServerName-plink2" --resource-group $resourceGroupName --vnet-name $spoke2VnetName --subnet $subnetName --private-connection-resource-id $sqlServerID --group-ids sqlServer --connection-name "$sqlServerServerName-plink2"

# DNS Setup (Optional)
# Create the zone
az network private-dns zone create --resource-group $resourceGroupName --name  "privatelink.database.windows.net" 
# link to spokes
az network private-dns link vnet create --resource-group $resourceGroupName --zone-name  "privatelink.database.windows.net" --name "$spokeVnetName-DNSLink" --virtual-network $spokeVnetName --registration-enabled false
az network private-dns link vnet create --resource-group $resourceGroupName --zone-name  "privatelink.database.windows.net" --name "$spokeVnetName-DNSLink2" --virtual-network $spoke2VnetName --registration-enabled false 
# link to hub
az network private-dns link vnet create --resource-group $resourceGroupName --zone-name  "privatelink.database.windows.net" --name "$hubVnetName-DNSLink" --virtual-network $hubVnetName --registration-enabled false 

# Query for the PrivateLink network interface IDs
networkInterfaceId=$(az network private-endpoint show --name "$sqlServerServerName-plink" --resource-group $resourceGroupName --query 'networkInterfaces[0].id' -o tsv)
networkInterfaceId2=$(az network private-endpoint show --name "$sqlServerServerName-plink2" --resource-group $resourceGroupName --query 'networkInterfaces[0].id' -o tsv)
# Grab the private IPs
privateIp=$(az resource show --ids $networkInterfaceId --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
privateIp2=$(az resource show --ids $networkInterfaceId2 --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
#Create DNS records 
az network private-dns record-set a create --name $sqlServerServerName --zone-name privatelink.database.windows.net --resource-group $resourceGroupName  
az network private-dns record-set a add-record --record-set-name $sqlServerServerName --zone-name privatelink.database.windows.net --resource-group $resourceGroupName -a $privateIp
az network private-dns record-set a create --name "$sqlServerServerName-2" --zone-name privatelink.database.windows.net --resource-group $resourceGroupName  
az network private-dns record-set a add-record --record-set-name "$sqlServerServerName-2" --zone-name privatelink.database.windows.net --resource-group $resourceGroupName -a $privateIp2