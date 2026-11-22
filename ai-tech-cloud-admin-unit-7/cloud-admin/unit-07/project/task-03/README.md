## Overview
**What will you learn?**  
* Discuss the security requirements for deploying applications in the cloud.
* Explain how a Defense-in-Depth strategy provides protection against potentially unrelated attack vectors.
* Implement identity-based access controls to protect a SQL service in Azure according to the Principle of Least Privilege.

## Task 03: Add Identity-Based Access Controls
Text goes here.

### Subtask 01: Create and Apply a Third Terraform Execution Plan
**Step 1.** Before starting Task 3, destroy the infrastructure created in Task 2. 
```bash
terraform -chdir=task-02/terraform destroy 
```

**Step 2.** Make a child folder called `task-03` and then, change directories to it. 
```bash
mkdir task-03
cd task-03/
```

**Step 3.** Copy the `terraform/` and `sql/` folders from your `task-02/` folder to your `task-03/` folder. 
```bash
cp -r ../task-02/terraform/ .
cp -r ../task-02/sql/ .
```

**Step 4.** Change directories to the `terraform/` folder you just copied to the `task-03/` folder. 
```bash
cd terraform/
```

**Step 5.** Open the `variables.tf` file. 
```bash
code variables.tf
```

**Step 6.** In the `variables.tf` file, (1) change the default value for `resource_group_name` to `cloud-security-task-03`, (2) rename the `admin_username` variable to `vm_admin_username`, (3) rename the `admin_password` variable to `vm_admin_password`, and (4) add the two variable blocks below. 
```hcl
variable "db_admin_username" {
  type    = string
}

variable "db_admin_password" {
  type   = string
}
``` 

**Step 7.** Open the `main.tf` file. 
```bash
code main.tf
```

**Step 8.** After the `azurerm_resource_group` block, add the two blocks below. 
```hcl
data "azuread_domains" "default" {
  only_initial = true
}

resource "azuread_user" "main" {
  user_principal_name = "${var.db_admin_username}@${data.azuread_domains.default.domains.0.domain_name}"
  display_name        = var.db_admin_username
  password            = var.db_admin_password
}
```

**Step 9.** Replace the `azurerm_mssql_server` block with the one below. 
```hcl
resource "azurerm_mssql_server" "main" {
  name                          = random_pet.main.id
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  azuread_administrator {
    azuread_authentication_only = true
    login_username              = azuread_user.main.display_name
    object_id                   = azuread_user.main.object_id
  }
  version                       = "12.0"
  public_network_access_enabled = "true" 
  identity {
    type = "SystemAssigned" 
  }
}
```

**Step 10.** In the `azurerm_linux_virtual_machine` block, update the `admin_username` and `admin_password` fields to use the new variable names declared in the `variables.tf` file.

**Step 11.** Declare the environment variables you need to complete Task 3, Subtask 1.
```bash
export TF_VAR_vm_admin_username="andy"
export TF_VAR_vm_admin_password="2InfinityAndBeyond!"
export TF_VAR_db_admin_username="bonnie"
export TF_VAR_db_admin_password="TheresASnakeInMyB00t!"
```

**Step 12.** Initialize your `task-03/terraform/` directory for Terraform-use. 
```bash
terraform init
``` 

**Step 13.** Create and apply a Terraform execution plan based on the `.tf` files you created in the `task-03/terraform/` directory. 
```bash
terraform apply
```

You should get output similar to below. 
```
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

db_admin_username = "bonnie@vicfernandezyahoo.onmicrosoft.com"
paw_ip_address = "172.191.237.130"
```

### Interim Validation
**Step 1.** Confirm the SQL service for Task 2 was created using the Azure CLI. 
```bash
az sql server list --resource-group "cloud-security-task-03"
```

You should get output similar to below.
```json
[
  {
    "administratorLogin": "CloudSAcf607849",
    "administratorLoginPassword": null,
    "administrators": {
      "administratorType": "ActiveDirectory",
      "azureAdOnlyAuthentication": true,
      "login": "bonnie",
      "principalType": "Group",
      "sid": "157d0002-8169-472b-9f91-ceeb8e7466c5",
      "tenantId": "da3cb2a3-95dd-4a37-b857-c1264e363deb"
    },
    "externalGovernanceStatus": "Disabled",
    "federatedClientId": null,
    "fullyQualifiedDomainName": "generousseagull.database.windows.net",
    "id": "/subscriptions/c60c349f-4b5c-4e39-98cb-4fc2323804c5/resourceGroups/cloud-security-task-03/providers/Microsoft.Sql/servers/generousseagull",
    "identity": {
      "principalId": "17924156-1083-41ce-980e-d2407ce90e33",
      "tenantId": "da3cb2a3-95dd-4a37-b857-c1264e363deb",
      "type": "SystemAssigned",
      "userAssignedIdentities": null
    },
    "isIPv6Enabled": null,
    "keyId": null,
    "kind": "v12.0",
    "location": "eastus",
    "minimalTlsVersion": "1.2",
    "name": "generousseagull",
    "primaryUserAssignedIdentityId": null,
    "privateEndpointConnections": [],
    "publicNetworkAccess": "Enabled",
    "resourceGroup": "cloud-security-task-03",
    "restrictOutboundNetworkAccess": "Disabled",
    "state": "Ready",
    "tags": {},
    "type": "Microsoft.Sql/servers",
    "version": "12.0",
    "workspaceFeature": null
  }
]
```

**Step 2.** Confirm the SQL database was created (again, using the Azure CLI and the first text segment of the value in the `fullyQualifiedDomainName` field above). 
```bash
az sql db list --resource-group "cloud-security-task-03" --server "generousseagull" --output table
```

You should get output similar to below. 
```
Name           Tier    Family    Capacity    MaxSize    ElasticPool
-------------  ------  --------  ----------  ---------  -------------
master         System                        50GB
vulnerable-db  Basic             5           2GB
```

### Subtask 02: Load Data into the SQL Database
**Step 1.** Declare the environment variables you need to complete Task 3, Subtask 2. Again, use the *entire* value in the `fullyQualifiedDomainName` field for the `DB_SERVER` variable.
```bash
export DB_SERVER="generousseagull.database.windows.net"
export DB="vulnerable-db"
export PAW=$(terraform output -raw paw_ip_address)
```

**Step 2.** Change directories to the `task-03/sql/` folder. 
```bash
cd ../sql/
```

**Step 3.** Verify you can login to the PAW created in Task 3, Subtask 01. 
```bash
ssh $TF_VAR_vm_admin_username@$PAW
```

You should get output similar to below. Enter `yes`. When prompted, enter the password used to initialize the `TF_VAR_vm_admin_password` variable to authenticate. 
```
The authenticity of host '172.191.237.130 (172.191.237.130)' can't be established.
ED25519 key fingerprint is SHA256:7h1dCN0ZaALpMIdJPN0mJvYeE+bVrLznOqdjEvQGsA4.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

After verifying you can access and authenticate with the PAW, logout of it.  
```bash
exit
```

**Step 4.** Copy the two SQL scripts in the `task-03/sql/` folder to the PAW using the `scp` program. 
```bash
scp insert_data.sql select_data.sql $TF_VAR_vm_admin_username@$PAW:~
```

**Step 5.** Login to the PAW again. 
```bash
ssh $TF_VAR_admin_username@$PAW
```

**Step 6.** Now that your shell environment has changed, you will need to declare the Task 3, Subtask 2 environment variables again. 
```bash
export DB_SERVER="generousseagull.database.windows.net"
export DB="vulnerable-db"
```

**Step 7.** Copy and paste the commands below into your shell environment on the PAW to install the `sqlcmd`.  
```bash
curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo apt-get install mssql-tools18 unixodbc-dev -y
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
```

**Step 8.** *Try* to load data into the SQL database using the same credentials you used to login to the PAW (username: `andy`; password: `2InfinityAndBeyond!`). 
```bash
sqlcmd -S "${DB_SERVER}" -d "${DB}" -U andy -i insert_data.sql 
```

You should get output similar to below. 
```
Sqlcmd: Error: Microsoft ODBC Driver 18 for SQL Server : Login failed for user 'andy'. Reason: Azure Active Directory only authentication is enabled. Please contact your system administrator.
```

**Step 9.** Now, try and load data into the SQL database using the credentials you declared for the `bonnie` user (username: `bonnie@vicfernandezyahoo.onmicrosoft.com`; password: `TheresASnakeInMyB00t!`). 
```bash
sqlcmd -S "${DB_SERVER}" -d "${DB}" -U bonnie@vicfernandezyahoo.onmicrosoft.com -G -i insert_data.sql 
```

You should get output similar to below. 
```
(5 rows affected)

(20 rows affected)
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
**Step 1.** Right now, you should still be in the `task-03/sql/` folder in the Azure Cloud Shell. Change directories to `unit-07`. 
```bash
cd ../../
```

**Step 2.** Submit your work for Task 3.
```bash
./submitter task3
```