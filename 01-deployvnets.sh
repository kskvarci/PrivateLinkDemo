#!/bin/bash

#include parameters file
source ./params.sh

# Create a resource group
az group create --location $location --name $resourceGroupName

#_______________________________________________________________________________
# Create a Hub VNet
az network vnet create --resource-group $resourceGroupName --name $hubVnetName --address-prefixes "10.0.0.0/16"

# Create a subnet for a DNS
az network vnet subnet create --resource-group $resourceGroupName --name "dns-subnet" --vnet-name $hubVnetName --address-prefixes "10.0.3.0/24"

#________________________________________________________________________________
# Create Spoke VNets
az network vnet create --resource-group $resourceGroupName --name $spokeVnetName --address-prefixes "10.1.0.0/16"
az network vnet create --resource-group $resourceGroupName --name $spoke2VnetName --address-prefixes "10.2.0.0/16"

# Create subnets for our test workloads
az network vnet subnet create --resource-group $resourceGroupName --name "workload-subnet" --vnet-name $spokeVnetName --address-prefixes "10.1.0.0/24"
az network vnet subnet create --resource-group $resourceGroupName --name "workload-subnet" --vnet-name $spoke2VnetName --address-prefixes "10.2.0.0/24"

# Create the PrivateLink Subnets
az network vnet subnet create --resource-group $resourceGroupName --name "privatelink-subnet" --vnet-name $spokeVnetName --address-prefixes "10.1.2.0/24"
az network vnet subnet create --resource-group $resourceGroupName --name "privatelink-subnet" --vnet-name $spoke2VnetName --address-prefixes "10.2.2.0/24"

#_________________________________________________________________________________
# Create NSGs for each subnet
az network nsg create --resource-group $resourceGroupName --name "dns-nsg"
az network nsg create --resource-group $resourceGroupName --name "workload-nsg"
az network nsg create --resource-group $resourceGroupName --name "workload2-nsg"

# Configure a rule on the workload subnets to allow inbound SSH. This is for testing.
az network nsg rule create --resource-group $resourceGroupName --name "ssh-inbound" --priority 110 --direction "Inbound" --protocol "*" --source-address-prefixes $sourceIP --source-port-ranges "*" --destination-address-prefixes "VirtualNetwork" --destination-port-ranges "22" --access "Allow" --nsg-name "workload-nsg"
az network nsg rule create --resource-group $resourceGroupName --name "ssh-inbound" --priority 110 --direction "Inbound" --protocol "*" --source-address-prefixes $sourceIP --source-port-ranges "*" --destination-address-prefixes "VirtualNetwork" --destination-port-ranges "22" --access "Allow" --nsg-name "workload2-nsg"

# assign the NSGs to the appropriate subnets
az network vnet subnet update --resource-group $resourceGroupName --name "workload-subnet" --vnet-name $spokeVnetName --network-security-group "workload-nsg"
az network vnet subnet update --resource-group $resourceGroupName --name "workload-subnet" --vnet-name $spoke2VnetName --network-security-group "workload2-nsg"
az network vnet subnet update --resource-group $resourceGroupName --name "dns-subnet" --vnet-name $hubVnetName --network-security-group "dns-nsg"

# Peer Hub and Spoke Networks
az network vnet peering create --resource-group $resourceGroupName --name hubtospoke --vnet-name $hubVnetName --remote-vnet $spokeVnetName --allow-vnet-access
az network vnet peering create --resource-group $resourceGroupName --name hubtospoke2 --vnet-name $hubVnetName --remote-vnet $spoke2VnetName --allow-vnet-access
az network vnet peering create --resource-group $resourceGroupName --name spoketohub --vnet-name $spokeVnetName --remote-vnet $hubVnetName --allow-vnet-access
az network vnet peering create --resource-group $resourceGroupName --name spoketohub2 --vnet-name $spoke2VnetName --remote-vnet $hubVnetName --allow-vnet-access