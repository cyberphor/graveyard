## Overview
**What will you learn?**  
* Discuss the security requirements for deploying applications in the cloud.
* Explain how a Defense-in-Depth strategy provides protection against potentially unrelated attack vectors.
* Implement network-based access controls to protect a SQL service in Azure using a Defense-in-Depth strategy.

## Task 02: Add Network-Based Access Controls
Now that we have a SQL service deployed in Azure, we can begin securing it *from the bottom up*. Our first order of business is network access. Your `main.tf` file has two network-related settings you need to change: network access from the public Internet and network access from within Azure. In the `azurerm_mssql_server` block, you have `public_network_access_enabled` set to `true`. This allows anyone on the public Internet to connect to your SQL service in Azure. In the `azurerm_mssql_firewall_rule` block, you have both the `start_ip_address` and `end_ip_address` field set to `0.0.0.0`. According to [Terraform's](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_firewall_rule) and [Microsoft's documentation](https://learn.microsoft.com/en-us/rest/api/sql/firewall-rules/create-or-update?), this allows any IP address internal to Azure to access it. The difference between these address spaces is one is *routable* on the Internet (i.e., public IP addresses) while the other is not (i.e., the private IP addresses used in Azure). To address your current network security posture, you are going to implement a "Deny All, Permit by Exception" (otherwise known as DAPE) network access strategy. 

### Subtask 01: Create and Apply a Second Terraform Execution Plan
**Step 1.** In the Information Security community, it's recommended to bake security into your the design of your information system versus bolting it on after the fact. At the end of the project, we also want you to have multiple Terraform configurations of increasingly more secure designs for you to use after you complete the Cloud Administrator course. For these reasons, destroy the infrastructure created in Task 1 before starting Task 2. Since you're in the `unit-07/` folder, you will need to tell Terraform where to find the files used to store information about your infrastructure in order for it to destroy it. This is done using the `-chdir` parameter. For example, if you stored your Terraform files in a folder called `zurg` the command you'd need to run would be `terraform -chdir=zurg destroy`. 
```bash
terraform -chdir=task-01/terraform destroy 
```

**Step 2.** Make a child folder called `task-02` and then, change directories to it. 
```bash
mkdir task-02
cd task-02/
```

**Step 3.**  Copy the `terraform/` and `sql/` folders from your `task-01/` folder to your `task-02/` folder. 
```bash
cp -r ../task-01/terraform/ .
cp -r ../task-01/sql/ .
```

**Step 4.** Change directories to the `terraform/` folder you just copied to the `task-02/` folder. 
```bash
cd terraform/
```

**Step 5.** Open the `variables.tf` file. 
```bash
code variables.tf
```

**Step 6.** In the `variables.tf` file, change the default value for `resource_group_name` to `cloud-security-task-02`. 

**Step 7.** Then, add the content below to the `variables.tf` file. 
```hcl
variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "vm_image_publisher" {
  type    = string
  default = "Canonical" 
}

variable "vm_image_offer" {
  type    = string
  default = "0001-com-ubuntu-server-jammy" 
}

variable "vm_image_sku" {
  type    = string
  default = "22_04-lts" 
}

variable "vm_image_version" {
  type    = string
  default = "latest" 
}

variable "vm_os_disk_storage_type" {
  type    = string
  default = "StandardSSD_LRS"
}
```

**Step 8.** Open the `main.tf` file. 
```bash
code main.tf
```

**Step 9.** Then, delete the `azurerm_mssql_firewall_rule` block from the `main.tf` file.

**Step 10.** Next, add the content below to the `main.tf` file. 
```hcl
resource "azurerm_virtual_network" "main" {
  depends_on          = [ azurerm_resource_group.main ]
  name                = random_pet.main.id
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  depends_on          = [ azurerm_resource_group.main ]
  name                 = random_pet.main.id
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "main" {
  depends_on          = [ azurerm_resource_group.main ]
  name                = random_pet.main.id
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "main" {
  name                            = random_pet.main.id
  location                        = var.location
  resource_group_name             = var.resource_group_name
  ip_configuration {
    name                          = random_pet.main.id
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_network_security_group" "main" {
  name                = random_pet.main.id
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = random_pet.main.id
  resource_group_name             = azurerm_resource_group.main.name
  location                        = var.location
  size                            = var.vm_size
  network_interface_ids           = [
    azurerm_network_interface.main.id
  ]
  disable_password_authentication = false
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  os_disk {
    caching                       = "ReadWrite"
    storage_account_type          = var.vm_os_disk_storage_type
    name                          = random_pet.main.id
  }
  source_image_reference {
    publisher                     = var.vm_image_publisher
    offer                         = var.vm_image_offer
    sku                           = var.vm_image_sku
    version                       = var.vm_image_version
  }
}

resource "azurerm_mssql_firewall_rule" "main" {
  name             = "AllowAccessFromPrivilegedAccessWorkstation"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = azurerm_public_ip.main.ip_address
  end_ip_address   = azurerm_public_ip.main.ip_address
}
```

**Step 11.** Create and open a file called `outputs.tf`. 
```bash
code outputs.tf
```

**Step 12.** Add the content below to the `outputs.tf` file.
```hcl
output "paw_ip_address" {
  value = azurerm_public_ip.main.ip_address
}
```

**Step 13.** Initialize your `task-02/terraform/` directory for Terraform-use. 
```bash
terraform init
``` 

**Step 14.** Create and apply a Terraform execution plan based on the `.tf` files you created in the `task-02/terraform/` directory. 
```bash
terraform apply
```

You should get output similar to below. 
```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

paw_ip_address = "52.168.108.235"
```

### Interim Validation
**Step 1.** Confirm the SQL service for Task 2 was created using the Azure CLI. 
```bash
az sql server list --resource-group "cloud-security-task-02"
```

**Step 2.** Confirm the SQL database was created (again, using the Azure CLI and the first text segment of the value in the `fullyQualifiedDomainName` field above). 
```bash
az sql db list --resource-group "cloud-security-task-02" --server "profoundalbacore" --output table
```

You should get output similar to below. 
```
Name           Tier    Family    Capacity    MaxSize    ElasticPool
-------------  ------  --------  ----------  ---------  -------------
master         System                        50GB
vulnerable-db  Basic             5           2GB
```

### Subtask 02: Load Data into the SQL Database
**Step 1.** Declare the environment variables you need to complete Task 2, Subtask 2. Again, use the *entire* value in the `fullyQualifiedDomainName` field for the `DB_SERVER` variable.
```bash
export DB_SERVER="profoundalbacore.database.windows.net"
export DB="vulnerable-db"
export PAW=$(terraform output -raw paw_ip_address)
```

**Step 2.** Right now, you should still be in the `task-02/terraform/` folder. Change directories to `task-02/`, make a child folder of `task-02/` called `sql`, and then change directories to it. 
```bash
cd ..
mkdir sql
cd sql/
```

**Step 3.** *Try* loading data into the SQL database using `sqlcmd` from your current Azure Cloud Shell session. Again, when prompted, enter the password you used to initialize the `TF_VAR_admin_password` variable.
```bash
sqlcmd -S "${DB_SERVICE}" -U "${TF_VAR_admin_username}" -d "${DB}" -i insert_data.sql 
```

You should get output similar to below. This is by design. 
```
Sqlcmd: Error: Microsoft ODBC Driver 18 for SQL Server : Cannot open server 'profoundalbacore' requested by the login. Client with IP address '20.253.55.85' is not allowed to access the server.  To enable access, use the Azure Management Portal or run sp_set_firewall_rule on the master database to create a firewall rule for this IP address or address range.  It may take up to five minutes for this change to take effect..
```

**Step 4.** Verify you can login to the PAW created in Task 2, Subtask 01. 
```bash
ssh $TF_VAR_admin_username@$PAW
```

You should get output similar to below. Enter `yes`. When prompted, enter the password used to initialize the `TF_VAR_admin_password` variable to authenticate. 
```
The authenticity of host '52.168.108.235 (52.168.108.235)' can't be established.
ED25519 key fingerprint is SHA256:hoc43uYV2WOgCKb32ffhetbJhKTh5dkoLQXAKubM9cY.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? 
```

After verifying you can access and authenticate with the PAW, logout of it.  
```bash
exit
```

**Step 5.** Copy the two SQL scripts in the `task-02/sql/` folder to the PAW using the `scp` program. 
```bash
scp insert_data.sql select_data.sql $TF_VAR_admin_username@$PAW:~
```

**Step 6.** Login to the PAW again. 
```bash
ssh $TF_VAR_admin_username@$PAW
```

**Step 7.** Now that your shell environment has changed, you will need to declare the Task 2, Subtask 2 environment variables again. 
```bash
export DB_SERVER="profoundalbacore.database.windows.net"
export DB="vulnerable-db"
export TF_VAR_admin_username="andy"
```

**Step 6.** Copy and paste the commands below into your shell environment on the PAW to install the `sqlcmd`.  
```bash
curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo apt-get install mssql-tools18 unixodbc-dev -y
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
```

**Step 7.** Load data into the SQL database using `sqlcmd` from your current Azure Cloud Shell session. Again, when prompted, enter the password you used to initialize the `TF_VAR_admin_password` variable. The output should be the same as before. 
```bash
sqlcmd -S "${DB_SERVER}" -U "${TF_VAR_admin_username}" -d "${DB}" -i insert_data.sql 
```

### Interim Validation
**Step 1.** Use `sqlcmd` and the `select_data.sql` script to confirm data was loaded into the SQL database. Once more, enter the password you used to initialize the `TF_VAR_admin_password` variable when prompted. The output should be the same as before. 
```bash
sqlcmd -S "${DB_SERVER}" -U "${TF_VAR_admin_username}" -d "${DB}" -i select_data.sql -W
```

**Step 2.** After you confirm data has been loaded into the new SQL database, logout of the PAW. 
```bash
exit
```

### How to Submit
**Step 1.** Right now, you should still be in the `task-02/sql/` folder in the Azure Cloud Shell. Change directories to `unit-07`. 
```bash
cd ../../
```

**Step 2.** Submit your work for Task 2.
```bash
./submitter task2
```