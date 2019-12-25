# Header 1

Lorem Ipsum

## Header 2

Lorem Ipsum

## Header 2

### Header 3

Lorem Ipsum

```
#!/bin/bash -e

# Parameters
# -----------------------------------------------------------
# Resource Group & Location
resourceRootName="kthw"
location="centralus"

# Network Info
vNetCIDR="10.240.0.0/24"
podCIDRStart="10.200.0.0/24"
adminUserName="ken"
SSHPublicKey=''
```

## Built With

* [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) - Azure Command Line Interface
* [Visual Studio Code](https://code.visualstudio.com/) - The best code editor out there... Seriously.
* [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) - Linux on Windows

## Contributing

Pull Requests Welcome

## Authors

* **Ken Skvarcius**

## Acknowledgments

* [Kubernetes The Hard Way](https://github.com/lostintangent/kubernetes-the-hard-way)
* Many of the Azure CLI patterns are based on work from [Jonathan Carter's fork](https://github.com/lostintangent/kubernetes-the-hard-way) of Kelsey's original work.