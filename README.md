# Private Link Demo Environment

The scripts in this repository will build out an environment in which you can explore Azure's Private Link Service in the context of a hub and spoke network architecture.

There are two options for deploying the environment:

**Option 1** - *recommended*:\
( Step through each deployment phase. )
* Rename params.sh.example to params.sh
* Update values for variables in params.sh that start with "your-".
* Run each script in order starting with 01-deployvnets.sh and ending with 07-deploytestclients.sh.
* Explore resources deployed after each step.

**Option 2:**\
( In a hurry? Deploy everything in one shot. )
1. Rename params.sh.example to params.sh
* Update values for variables in params.sh that start with "your-".
3. Deploy all resources in one shot by running 00-RunAll.sh

The scripts are well commented. Make sure to read through them before running!

## Script Descriptions

### 01-deployvnets.sh
This script deploys three VNets; One hub and two spokes.\
Within the hub VNet two subnets are created. A subnet to host a Bind DNS forwarder and a subnet for hosting private endpoints.\
Within the first spoke VNet and single subnet is created to host workload resources.\
Within the second spoke VMet two subnets are created; one for workload resources and one for private endpoints.

### 02-sqlPrivateLink.sh
This script deploys an Azure SQL server and a single database with AdventureWorks test data. It then create a private endpoint in the hub VNet that can be used to access the database privately.
Lastly, a private zone is created so that the private endpoint can be referenced on the private network via the Bind fowarder.

### 03-StoragePrivateLink.sh
This script is almost identical to the above noted script. Instead of deploying a SQL DB this script deploys a storage account with a private endpoint in the hub along with a private zone.

### 04-CosmosPrivateLink.sh
This script is almost identical to the above noted script. Instead of deploying a storage account this script deploys a Cosmos account with a private endpoint in the hub along with a private zone.

### 05-deployforwarder.sh
This script deploys a Bind forwarder (Ubuntu) into the DNS subnet in the hub. This forwarder is set up to forward requests to Azure's internal resolver. See configforwarder.sh for details.\
Both spoke VNets are then configured to reference the Bind server for all lookups.\
In a typical scneario this forwarder would be configured to conditionally forward requests to on-premises resolvers and Azure.

### 06-PrivateLinkService.sh
This script deploys a custom Private Link Service. The service is cconfigured to reference a standard load balancer that balances traffic between two simple NGINX servers. A service endpoint is then created in the second spoke referencing this custom Private Link Service such that resources in the second spoke can access the service through the endpoint.

### 07-deploytestclients.sh
This script deploys a Windows Server VM into each spokes workload subnet. These VM's can be used to test the various Private Link Services and Endpoints that we've deployed.\
These are basic VM's. You'll have to deploy test apps like SSMS, etc. to conduct whatever tests you'd like to conduct.

## Some Ideas for Testing
1. Install SSMS on the test client VM's in each spoke and connect to the SQL server through the service endpoint in the Hub.
2. Try connecting to the SQL server from the internet or another network through the public IP. This shouldnt work. 
3. Try the same with the storage and Cosmos account using Azure Storage Explorer (You'll have to install this on the test clients)
4. Try connecting to the resources from the test clients with both with the original resource FQDNs and the custom private zone FQDNs. Both should work due to the CName chains.
5. Try connecting directly to the private front-end IP of the standard load balancer for the custom Private Link Service from both spokes. You should be able to access it only from Spoke one due to non-transitive routing.
6. Connect to the custom Private Link Service frome Spoke 2 using the via the private endpoint in Spoke 2. This allows resources in Spoke 2 to reach the custom service without peering through the endpoint.

## Built With

* [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) - Azure Command Line Interface
* [Visual Studio Code](https://code.visualstudio.com/) - The best code editor out there... Seriously.
* [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) - Linux on Windows

## Contributing

Pull Requests Welcome

## Authors

**Ken Skvarcius**
