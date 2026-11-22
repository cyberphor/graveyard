## Overview
**What will you learn?**  
* Discuss the security requirements for deploying applications in the cloud.
* Explain how a Defense-in-Depth strategy provides protection against potentially unrelated attack vectors.
* Implement identity-based access controls to protect a SQL service in Azure according to the Principle of Least Privilege.

## Task 01: Deploy a SQL Service in Azure
Before you get started with securing a SQL service in Azure, you need to deploy one. Let's do this using the Azure Cloud Shell and Terraform. A shell is an interface used to manage resources within a system (hence, the name). Graphical-based shells, such as the Azure Portal, are known as Graphical User Interfaces (GUIs). Text-based shells, such as the Azure Cloud Shell, are called Command Line Interfaces (CLIs). Terraform is an Infrastructure-as-Code (IaC) tool that allows you to deploy Information Technology (IT) infrastructure using a CLI instead of a GUI. Fortunately, Terraform comes pre-installed in the Azure Cloud Shell. 

### Subtask 01: Create and Apply a Terraform Execution Plan
**Step 1.** Login to the [Azure Portal](https://portal.azure.com/) and then, open the Azure Cloud Shell.

**Step 2.** Declare the environment variables you need to complete Task 1, Subtask 1 (replace `MySubscriptionId` with the correct name of your subscription). You can do this a few ways. For example, you could copy the code block below and just paste it into your shell session. Or, you could copy the code block, paste it to a file, and then run the `source` command (with the name of the file storing your variable declarations as an argumment). The `source` command reads and executes shell commands from the file you provide it. An example of using it is as follows (assuming you named your variable declarations file `.env`): `source .env`. 
```bash
export SUBSCRIPTION_ID="MySubscriptionId"
export TF_VAR_admin_username="andy"
export TF_VAR_admin_password="2InfinityAndBeyond!"
```

**Step 3.** Set your Azure subscription. 
```bash
az account set --subscription "${SUBSCRIPTION_ID}"
```

**Step 4.** Create a folder called `cloud-admin/unit-07` and then change directories to it. 
```bash
mkdir -p cloud-admin/unit-07
cd cloud-admin/unit-07/
```

**Step 5.** In the `cloud-admin/unit-07/` folder, create a folder called `task-01` with a child folder inside of it called `terraform`. Then, change directories to the `task-01/terraform/` folder. The sole purpose of this step and the previous one is to keep your workspace tidy. As a cloud administrator, you will find yourself working on various projects and/or tasks at the same time. Therefore, it's best practice to organize related files using folders. For example, a common pattern you will see in the wild is one folder per topic (e.g., source code, SQL queries, Dockerfiles, Terraform files, and Kubernetes manifests). 
```bash
mkdir -p task-01/terraform
cd task-01/terraform/
```

**Step 6.** Create and open a file called `providers.tf` in the `task-01/terraform/` directory using the Monaco Editor. The Monaco Editor is a browser-based code editor that comes pre-installed with Azure Cloud Shell. Although, you are free to use whatever code editor you're comfortable with (like `vim`) instead. 
```bash
code providers.tf
```

**Step 7.** Add the content below to the `providers.tf` file. If you're using Monaco Editor and need to close it, right-click in the Monaco window, click "Save" and then, "Quit." 
```hcl
terraform {
  required_version = ">=1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.100.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

**Step 8.** Create and open a file called `variables.tf` in the `task-01/terraform/` directory. 
```bash
code variables.tf
```

**Step 9.** Add the content below to the `variables.tf` file. 
```hcl
variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "cloud-security-task-01"
}

variable "db_name" {
  type    = string
  default = "vulnerable-db"
}

variable "admin_username" {
  type    = string
}

variable "admin_password" {
  type    = string
}
```

**Step 10.** Create and open a file called `main.tf` in the `task-01/terraform/` directory. 
```bash
code main.tf
```

**Step 11.** Add the content below to the `main.tf` file. 
```hcl
resource "random_pet" "main" {
  length     = 2
  separator  = ""
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_mssql_server" "main" {
  name                          = random_pet.main.id
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  administrator_login           = var.admin_username
  administrator_login_password  = var.admin_password
  version                       = "12.0"
  public_network_access_enabled = "true" 
  identity {
    type = "SystemAssigned" 
  }
}

resource "azurerm_mssql_database" "main" {
  server_id                    = azurerm_mssql_server.main.id
  name                         = var.db_name
  max_size_gb                  = 2
  sku_name                     = "Basic"
}

resource "azurerm_mssql_firewall_rule" "main" {
  name             = "AllowAzureServicesAndResourcesAccessToThisServer"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
```

**Step 12.** Initialize your `task-01/terraform/` directory for Terraform-use. The purpose of this step is to (1) initialize your Terraform backend and (2) install the Terraform plugin providers you specified in the `providers.tf` file. 
```bash
terraform init
``` 

**Step 13.** Create and apply a Terraform execution plan based on the `.tf` files you created in the `task-01/terraform/` directory (when prompted, enter `yes`). 
```bash
terraform apply
```

You should get output similar to below. 
```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

### Interim Validation
**Step 1.** Confirm the SQL service was created using the Azure CLI. 
```bash
az sql server list --resource-group "cloud-security-task-01"
```

You should get output similar to below. 
```
[
  {
    "administratorLogin": "cloudadmin",
    "administratorLoginPassword": null,
    "administrators": null,
    "externalGovernanceStatus": "Disabled",
    "federatedClientId": null,
    "fullyQualifiedDomainName": "verifieddodo.database.windows.net",
    "id": "/subscriptions/449b777a-56a9-4ce8-853d-7cd824d7118f/resourceGroups/cloud-security-task-01/providers/Microsoft.Sql/servers/verifieddodo",
    "identity": {
      "principalId": "70d7df05-dec4-47b1-ac57-08f836802098",
      "tenantId": "da3cb2a3-95dd-4a37-b857-c1264e363deb",
      "type": "SystemAssigned",
      "userAssignedIdentities": null
    },
    "isIPv6Enabled": null,
    "keyId": null,
    "kind": "v12.0",
    "location": "eastus",
    "minimalTlsVersion": "1.2",
    "name": "verifieddodo",
    "primaryUserAssignedIdentityId": null,
    "privateEndpointConnections": [],
    "publicNetworkAccess": "Enabled",
    "resourceGroup": "cloud-security-task-01",
    "restrictOutboundNetworkAccess": "Disabled",
    "state": "Ready",
    "tags": {},
    "type": "Microsoft.Sql/servers",
    "version": "12.0",
    "workspaceFeature": null
  }
]
```

**Step 2.** Confirm the SQL database was created using the Azure CLI and the first text segment of the value in the `fullyQualifiedDomainName` field above as an argument for the `--server` parameter. 
```bash
az sql db list --resource-group "cloud-security-task-01" --server "verifieddodo" --output table
```

You should get output similar to below. 
```
Name           Tier    Family    Capacity    MaxSize    ElasticPool
-------------  ------  --------  ----------  ---------  -------------
master         System                        50GB
vulnerable-db  Basic             5           2GB
```

### Subtask 02: Load Data into the SQL Database
**Step 1.** Right now, you should still be in the `task-01/terraform/` folder. Change directories to `task-01/`, make a child folder of `task-01/` called `sql`, and then change directories to it. 
```bash
cd ..
mkdir sql
cd sql/
```

**Step 2.** Declare the environment variables you need to complete Task 1, Subtask 2. For the `DB_SERVER` variable, use the *entire* value in the `fullyQualifiedDomainName` field printed in Subtask 01. 
```bash
export DB_SERVER="verifieddodo.database.windows.net"
export DB="vulnerable-db"
```

**Step 3.** Create and open a script called `insert_data.sql` in the `task-01/sql/` directory. 
```bash
code insert_data.sql
```

**Step 4.** Add the content below to the `insert_data.sql` file. 
```sql
-- create ProductCategory table
CREATE TABLE ProductCategory (
    ProductCategoryID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(255) NOT NULL
);

-- create Product table
CREATE TABLE Product (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(255) NOT NULL,
    ProductCategoryID INT,
    FOREIGN KEY (ProductCategoryID) REFERENCES ProductCategory(ProductCategoryID)
);

-- insert data into ProductCategory table
INSERT INTO ProductCategory (Name)
VALUES 
('Road Frames'),
('Helmets'),
('Socks'),
('Caps'),
('Jerseys');

-- insert data into Product table
INSERT INTO Product (Name, ProductCategoryID)
VALUES
('HL Road Frame - Black, 58', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('HL Road Frame - Red, 58', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('Sport-100 Helmet, Red', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Helmets')),
('Sport-100 Helmet, Black', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Helmets')),
('Mountain Bike Socks, M', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Socks')),
('Mountain Bike Socks, L', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Socks')),
('Sport-100 Helmet, Blue', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Helmets')),
('AWC Logo Cap', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Caps')),
('Long-Sleeve Logo Jersey, S', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Jerseys')),
('Long-Sleeve Logo Jersey, M', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Jerseys')),
('Long-Sleeve Logo Jersey, L', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Jerseys')),
('Long-Sleeve Logo Jersey, XL', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Jerseys')),
('HL Road Frame - Red, 62', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('HL Road Frame - Red, 44', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('HL Road Frame - Red, 48', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('HL Road Frame - Red, 52', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('HL Road Frame - Red, 56', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('LL Road Frame - Black, 58', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('LL Road Frame - Black, 60', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('LL Road Frame - Black, 62', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames'));
```

**Step 5.** Load data into the SQL database using `sqlcmd`. `sqlcmd` is a program used to interact with SQL services. It works like this. You write SQL statements, `sqlcmd` sends them to a given SQL service. The SQL service returns data to `sqlcmd` who then renders it in your CLI. When prompted, enter the password you used to initialize the `TF_VAR_admin_password` variable.
```bash
sqlcmd -S "${DB_SERVER}" -U "${TF_VAR_admin_username}" -d "${DB}" -i insert_data.sql 
```

You should get output similar to below. 
```
(5 rows affected)

(20 rows affected)
```

### Interim Validation
**Step 1.** Create and open a script called `select_data.sql` in the `task-01/sql/` directory. 
```bash
code select_data.sql
```

**Step 2.** Add the content below to the `select_data.sql` script. 
```sql
SELECT TOP 20 ProductCategory.Name as CategoryName, Product.name as ProductName 
FROM ProductCategory
JOIN Product
ON ProductCategory.productcategoryid = Product.productcategoryid;
```

**Step 3.** Use `sqlcmd` and the `select_data.sql` script to confirm data was loaded into the SQL database. Again, enter the password you used to initialize the `TF_VAR_admin_password` variable when prompted. The `-W` parameter tells `sqlcmd` to trim whitespace from its output (which will improve readability of whats rendered in the CLI). 
```bash
sqlcmd -S "${DB_SERVER}" -U "${TF_VAR_admin_username}" -d "${DB}" -i select_data.sql -W
```

You should get output similar to below. 
```
CategoryName ProductName
------------ -----------
Road Frames HL Road Frame - Black, 58
Road Frames HL Road Frame - Red, 58
Helmets Sport-100 Helmet, Red
Helmets Sport-100 Helmet, Black
Socks Mountain Bike Socks, M
Socks Mountain Bike Socks, L
Helmets Sport-100 Helmet, Blue
Caps AWC Logo Cap
Jerseys Long-Sleeve Logo Jersey, S
Jerseys Long-Sleeve Logo Jersey, M
Jerseys Long-Sleeve Logo Jersey, L
Jerseys Long-Sleeve Logo Jersey, XL
Road Frames HL Road Frame - Red, 62
Road Frames HL Road Frame - Red, 44
Road Frames HL Road Frame - Red, 48
Road Frames HL Road Frame - Red, 52
Road Frames HL Road Frame - Red, 56
Road Frames LL Road Frame - Black, 58
Road Frames LL Road Frame - Black, 60
Road Frames LL Road Frame - Black, 62

(20 rows affected)
```

### How to Submit
**Step 1.** Right now, you should still be in the `task-01/sql/` folder. Change directories to `unit-07/`. 
```bash
cd ../../
```

**Step 2.** Declare and intialize the remaining environment variables you need to submit your work. 
```bash
export SUBMISSION_USERNAME=""
export SUBMISSION_PASSWORD=""
```

**Step 3.** Download the `submitter` program for this project to the `task-01/` folder. 
```bash
wget https://cloudadministratorcourse.blob.core.windows.net/security/submitter/sail2/v4/submitter -O submitter
```

**Step 4.** Change the access mode for the `submitter` program so you're allowed to can execute it. 
```bash
chmod u+x submitter
```

**Step 5.** Submit your work for Task 1.
```bash
./submitter task1
```