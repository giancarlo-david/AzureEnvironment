# AzureEnvironment
Terraform and Powershell code that creates resources within Azure 

### Resources created:
- Resource Group
- Virtual Network
- Subnet
- Storage account
- Linux VM
- Network Security Group
- Network Interface Controller

## How to deploy Azure resources:
1. Prerequisites:
    - Create Azure account 
    - Install [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
    - Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
2. Clone this repo to retrieve all the necessary files or create files and copy and paste the code from this repo. File names are:
    - main.tf
    - outputs.tf
    - variables.tf
3. Using Azure CLI login to your Azure account with command `az login`
4. Create the resources defined in the Terraform code by using command `terraform apply -auto-approve`

## Connect to Virtual Machine and test Private Endpoint connection
1. SSH into the VM with the public IP that is in the output after running the Terraform code
    - `ssh testadmin@<publicip>`
    - Password is set to "Password123!" by default in the code
2. Use the following command to test connection to the Private Endpoint:
    - `nslookup <storage-account-name>.blob.core.windows.net`
    - Note: <storage-account-name> is "devstoragecodingcanal" by default

## Security policies applied
    - Private Endpoint Enabled: Brings in the service that you deploy into your virtual network by using a private IP address from your virtual network. Disabling public endpoints prevents users from outside the virtual network from accessing the service.
    - Role Based Access Control (RBAC): Limits accesss based on roles which enables fine grain control of which users have access to certain items within the subscription. Prevents users with malicious intent from having full control if they were to gain access.
    - Storage accounts should disable public network access (Policy): Prevents user error of creating a storage account with public network access which hardens the security of the environment by eliminating user error.
    - TLS 1.2+ for all resources (Policy): Enforces a minimum version of TLS (1.2) which prevents any outdated versions of TLS from being implemented, ensuring that TLS stays up to date.

## Assumptions Made
    - Pre-existing policy for storage accounts disabling public network access
    - User would like to SSH into VM without having to interact with Azure UI
    - Environment being created is for testing purposes only as the VM is not secure with an easily guessed username+password and open public port 22

## Items learned
    - Azure has built in roles and policies for users to utilize which decreases workload by not having to necessarily create them from scratch
    - Creating private endppoint helps secure resources by keeping them within the virtual network and restricting public access
    