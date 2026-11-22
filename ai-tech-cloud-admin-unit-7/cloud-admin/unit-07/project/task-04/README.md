## Objectives
**After completing this project module, you will be able to:**  
* Discuss the security requirements for deploying applications in the cloud.
* Explain how a Defense-in-Depth strategy provides protection against potentially unrelated attack vectors.
* Implement detection controls to monitor a SQL service in Azure for security events in support of a Defense-in-Depth strategy. 

## Task 04: Add Detection Controls
### Subtask 01: Create and Apply a Fourth Terraform Execution Plan
**Step 1.** Before starting Task 4, destroy the infrastructure created in Task 3. 
```bash
terraform -chdir=task-03/terraform destroy 
```

**Step 2.** Make a child folder called `task-04` and then, change directories to it. 
```bash
mkdir task-04
cd task-04/
```

**Step 3.** Copy the `terraform/` and `sql/` folders from your `task-02/` folder to your `task-04/` folder. 
```bash
cp -r ../task-03/terraform/ .
cp -r ../task-03/sql/ .
```

**Step 4.** Change directories to the `terraform/` folder you just copied to the `task-04/` folder. 
```bash
cd terraform/
```

**Step 5.** Open the `variables.tf` file and change the default value for `resource_group_name` to `cloud-security-task-04`. 
```bash
code variables.tf
```

**Step 7.** Open the `main.tf` file.  
```bash
code main.tf
```

**Step 8.** Add the five blocks below. 
```hcl
resource "azurerm_log_analytics_workspace" "main" {
  name                = random_pet.main.id
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Free"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                       = random_pet.main.id
  target_resource_id         = "${azurerm_mssql_server.main.id}/databases/master"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  enabled_log {
    category = "SQLSecurityAuditEvents"
  }
}

resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  server_id              = azurerm_mssql_server.main.id
  log_monitoring_enabled = true
}

resource "azurerm_mssql_database_extended_auditing_policy" "main" {
  database_id            = "${azurerm_mssql_server.main.id}/databases/master"
  log_monitoring_enabled = true
}

resource "azurerm_mssql_database_extended_auditing_policy" "main" {
  database_id            = "${azurerm_mssql_server.main.id}/databases/${var.db_name}"
  log_monitoring_enabled = true
}
```

**Step 11.** Declare the environment variables you need to complete Task 3, Subtask 1.
```bash
export TF_VAR_vm_admin_username="andy"
export TF_VAR_vm_admin_password="2InfinityAndBeyond!"
export TF_VAR_db_admin_username="bonnie"
export TF_VAR_db_admin_password="TheresASnakeInMyB00t!"
```

**Step 9.** Initialize your `task-03/terraform/` directory for Terraform-use. 
```bash
terraform init
``` 

**Step 10.** Create and apply a Terraform execution plan based on the `.tf` files you created in the `task-04/terraform/` directory. 
```bash
terraform apply
```

You should get output similar to below. 
```
```

### Interim Validation
**Step 1.** Confirm the SQL service for Task 4 was created using the Azure CLI. 
```bash
az sql server list --resource-group "cloud-security-task-04"
```

You should get output similar to below.
```json

```

**Step 2.** Confirm the SQL database was created (again, using the Azure CLI and the first text segment of the value in the `fullyQualifiedDomainName` field above). 
```bash
az sql db list --resource-group "cloud-security-task-04" --server "generousseagull" --output table
```

You should get output similar to below. 
```
Name           Tier    Family    Capacity    MaxSize    ElasticPool
-------------  ------  --------  ----------  ---------  -------------
master         System                        50GB
vulnerable-db  Basic             5           2GB
```

### Subtask 02: Load Data into the SQL Database
**Step 1.** Declare the environment variables you need to complete Task 4, Subtask 2. Again, use the *entire* value in the `fullyQualifiedDomainName` field for the `DB_SERVER` variable.
```bash
export DB_SERVER=""
export DB="vulnerable-db"
export PAW=$(terraform output -raw paw_ip_address)
```

**Step 2.** Change directories to the `task-04/sql/` folder. 
```bash
cd ../sql/
```

**Step 3.** Verify you can login to the PAW created in Task 4, Subtask 01. 
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

**Step 4.** Copy the two SQL scripts in the `task-04/sql/` folder to the PAW using the `scp` program. 
```bash
scp insert_data.sql select_data.sql $TF_VAR_vm_admin_username@$PAW:~
```

**Step 5.** Login to the PAW again. 
```bash
ssh $TF_VAR_admin_username@$PAW
```

**Step 6.** Now that your shell environment has changed, you will need to declare the Task 4, Subtask 2 environment variables again. 
```bash
export DB_SERVER=""
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

**Step 8.** Load data into the SQL database using the credentials you declared for the `bonnie` user (username: `bonnie@vicfernandezyahoo.onmicrosoft.com`; password: `TheresASnakeInMyB00t!`). 
```bash
sqlcmd -S "${DB_SERVER}" -d "${DB}" -U bonnie@vicfernandezyahoo.onmicrosoft.com -G -i insert_data.sql 
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
**Step 1.** Right now, you should still be in the `task-04/sql/` folder in the Azure Cloud Shell. Change directories to `unit-07`. 
```bash
cd ../../
```

**Step 2.** Submit your work for Task 4.
```bash
./submitter task3
```