# !/bin/bash

#include parameters file
source ./params.sh

# Deploy an Ubuntu VM and install test tools
az vm create --name "TestClient1" --resource-group $resourceGroupName --authentication-type "ssh" --admin-username $userName --boot-diagnostics-storage "" --location $location --nsg "" --image "Canonical:UbuntuServer:18.04-LTS:latest" --size "Standard_DS2" --ssh-key-value "$sshKey" --subnet "workload-subnet" --vnet-name $spokeVnetName --custom-data configclient.sh
az vm create --name "TestClient2" --resource-group $resourceGroupName --authentication-type "ssh" --admin-username $userName --boot-diagnostics-storage "" --location $location --nsg "" --image "Canonical:UbuntuServer:18.04-LTS:latest" --size "Standard_DS2" --ssh-key-value "$sshKey" --subnet "workload-subnet" --vnet-name $spoke2VnetName --custom-data configclient.sh
