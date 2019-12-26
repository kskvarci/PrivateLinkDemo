# Private Link Demo

The scripts in this repository will build out an environment in which you can explore Azure's Private Link Service in the context of a hub and spoke network.

There are two options for deploying the environment.

**Options 1** - *recommended*:\
( Step through each deployment phase )
* Rename params.sh.example to params.sh
* Update values for variables in params.sh that require unique values. 
* Run each script in order starting with 01-deployvnets.sh and ending with 07-deploytestclients.sh

**Option 2:**\
( Deploy everything in one shot )
1. Rename params.sh.example to params.sh
2. Update values for variables in params.sh that require unique values. 
3. Deploy all resources by running 00-RunAll.sh

The scripts are well commented. Make sure to read through them before running!

## Script Descriptions

### 01-deployvnets.sh
Lorem ipsom

### 02-sqlPrivateLink.sh
Lorem Ipsum

### 03-StoragePrivateLink.sh
Lorem Ipsum

### 04-CosmosPrivateLink.sh
Lorem Ipsum

### 05-deployforwarder.sh
Lorem Ipsum

### 06-ProvateLinkService.sh
Lorem Ipsum

### 07-deploytestclients.sh
Lorem Ipsum

## Built With

* [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) - Azure Command Line Interface
* [Visual Studio Code](https://code.visualstudio.com/) - The best code editor out there... Seriously.
* [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) - Linux on Windows

## Contributing

Pull Requests Welcome

## Authors

* **Ken Skvarcius**
