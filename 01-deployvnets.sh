#!/bin/bash

#NOTE:
# Make sure to modify params.sh, authenticate the CLI and select the correct subscription before running any of the scripts contained in this repo.

#include parameters file
source ./params.sh

# Create a resource group
az group create --location $location --name $resourceGroupName

#_______________________________________________________________________________
# Create a Hub VNet
az network vnet create --resource-group $resourceGroupName --name $hubVnetName --address-prefixes "10.0.0.0/16"

# Create a subnet for a DNS
az network vnet subnet create --resource-group $resourceGroupName --name "dns-subnet" --vnet-name $hubVnetName --address-prefixes "10.0.3.0/24"

# Create a subnet for a Private Endpoints
az network vnet subnet create --resource-group $resourceGroupName --name $subnetName --vnet-name $hubVnetName --address-prefixes "10.0.4.0/24"

#________________________________________________________________________________
# Create Spoke VNets
az network vnet create --resource-group $resourceGroupName --name $spokeVnetName --address-prefixes "10.1.0.0/16"
az network vnet create --resource-group $resourceGroupName --name $spoke2VnetName --address-prefixes "10.2.0.0/16"

# Create subnets for our test workloads
az network vnet subnet create --resource-group $resourceGroupName --name "workload-subnet" --vnet-name $spokeVnetName --address-prefixes "10.1.0.0/24"
az network vnet subnet create --resource-group $resourceGroupName --name "workload-subnet" --vnet-name $spoke2VnetName --address-prefixes "10.2.0.0/24"

# Create the Private Endpoint Subnets
az network vnet subnet create --resource-group $resourceGroupName --name $subnetName --vnet-name $spoke2VnetName --address-prefixes "10.2.2.0/24"

#_________________________________________________________________________________
# Create NSGs for each subnet
az network nsg create --resource-group $resourceGroupName --name "dns-nsg"
az network nsg create --resource-group $resourceGroupName --name "workload-nsg"
az network nsg create --resource-group $resourceGroupName --name "workload2-nsg"

# Configure a rule on the workload subnets to allow all connectivity from your source IP. This is for testing.
az network nsg rule create --resource-group $resourceGroupName --name "ssh-inbound" --priority 110 --direction "Inbound" --protocol "*" --source-address-prefixes $sourceIP --source-port-ranges "*" --destination-address-prefixes "VirtualNetwork" --destination-port-ranges "*" --access "Allow" --nsg-name "workload-nsg"
az network nsg rule create --resource-group $resourceGroupName --name "ssh-inbound" --priority 110 --direction "Inbound" --protocol "*" --source-address-prefixes $sourceIP --source-port-ranges "*" --destination-address-prefixes "VirtualNetwork" --destination-port-ranges "*" --access "Allow" --nsg-name "workload2-nsg"

# assign the NSGs to the appropriate subnets
az network vnet subnet update --resource-group $resourceGroupName --name "workload-subnet" --vnet-name $spokeVnetName --network-security-group "workload-nsg"
az network vnet subnet update --resource-group $resourceGroupName --name "workload-subnet" --vnet-name $spoke2VnetName --network-security-group "workload2-nsg"
az network vnet subnet update --resource-group $resourceGroupName --name "dns-subnet" --vnet-name $hubVnetName --network-security-group "dns-nsg"

# Peer Hub and Spoke Networks
az network vnet peering create --resource-group $resourceGroupName --name hubtospoke --vnet-name $hubVnetName --remote-vnet $spokeVnetName --allow-vnet-access
az network vnet peering create --resource-group $resourceGroupName --name hubtospoke2 --vnet-name $hubVnetName --remote-vnet $spoke2VnetName --allow-vnet-access
az network vnet peering create --resource-group $resourceGroupName --name spoketohub --vnet-name $spokeVnetName --remote-vnet $hubVnetName --allow-vnet-access
az network vnet peering create --resource-group $resourceGroupName --name spoketohub2 --vnet-name $spoke2VnetName --remote-vnet $hubVnetName --allow-vnet-access

# disable private endpoint network policies on the privatelink subnets
#_______________________________________________________________________________
# Network policies like network security groups (NSG) are not supported for private endpoints. In order to deploy a Private Endpoint on a given subnet,
# an explicit disable setting is required on that subnet. This setting is only applicable for the Private Endpoint. For other resources in the subnet,
# access is controlled based on Network Security Groups (NSG) security rules definition.
# When using the portal to create a private endpoint, this setting is automatically disabled as part of the create process. Deployment using other clients requires an additional step to change this setting.
az network vnet subnet update --name $subnetName --resource-group $resourceGroupName --vnet-name $hubVnetName --disable-private-endpoint-network-policies true
az network vnet subnet update --name $subnetName --resource-group $resourceGroupName --vnet-name $spoke2VnetName --disable-private-endpoint-network-policies true