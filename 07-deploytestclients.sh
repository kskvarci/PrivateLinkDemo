# !/bin/bash

# include parameters file
source ./params.sh

# Deploy Windows test VMs
# You will need to log into these VMs and install any test tools required.
az vm create --name "TestClient1" --resource-group $resourceGroupName --authentication-type "Password" --admin-username $userName  --admin-password $rdpPass --boot-diagnostics-storage "" --location $location --nsg "" --image "MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest" --size "Standard_DS4" --subnet "workload-subnet" --vnet-name $spokeVnetName
az vm create --name "TestClient2" --resource-group $resourceGroupName --authentication-type "Password" --admin-username $userName  --admin-password $rdpPass --boot-diagnostics-storage "" --location $location --nsg "" --image "MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest" --size "Standard_DS4" --subnet "workload-subnet" --vnet-name $spoke2VnetName