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
