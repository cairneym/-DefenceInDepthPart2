# Check whether the user is already logged in - prompt if not
$context = Get-AzContext

if (!$context) 
{
    Connect-AzAccount 
} 

# Make sure you are in the correct Context - this should return your Azure Tenant
Get-AzContext

# Make sure the required modules are installed
$azInstalled = $(Get-InstalledModule | Where-Object {$_.name -eq 'Az'}).name
if (-not($azInstalled)) {
    Install-Module Az
}
Import-Module Az
$aadInstalled = $(Get-InstalledModule | Where-Object {$_.name -eq 'AzureAD'}).name
if (-not($aadInstalled)) {
    Install-Module AzureAd -Scope CurrentUser
}
Import-Module AzureAD

# Get the parameters needed to connect to AzureAD
$currContext = Get-AzContext
$tenantID = $CurrContext.Tenant.Id
$AccID = $currContext.Account.Id
$myAAD = Connect-AzureAD -TenantId $tenantID -AccountId $AccID

# Set the paths to the ARM Template and Parameter files - they will be relative to this script file
$thisPath = $PSScriptRoot
$infraFile = "$thisPath\InfraDeploy.json"
$VMFile = "$thisPath\VMDeploy.json"
$VMParams = "$thisPath\VMDeployParams.json"
$SQLFile = "$thisPath\SQLDeploy.json"
$SQLParams = "$thisPath\SQLDeployParams.json"

# Get the current Client IP Address
$myIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content

# Get the SQLAdmins Security Group ObjectId
$groupSID = $(Get-AzureADGroup -Filter "displayName eq 'SQLAdmins'").ObjectId

# Prompt for the parameters to use for the SQL Server and VMs
Write-Host " "
Write-Host " "
$randomiser = Read-Host -Prompt "Enter a 5 character string (lowercase letters and numbers) to ensure uniqueness of your SQL Server and VM "
Write-Host " "
Write-Host " "
$netRG = Read-Host -Prompt "Enter the Resource Group name for the Virtual Network (suggest NDC-NET) "
Write-Host " "
Write-Host " "
$vmRG = Read-Host -Prompt "Enter the Resource Group name for the Virtual Machine (suggest NDC-VM) "
$vmName = Read-Host -Prompt "Enter the name of the VM "
$vmAdminUser = Read-Host -Prompt "Enter the admin account name for the VM "
$vmAdminPwd = Read-Host -Prompt "Enter the password for the VM admin account " -AsSecureString
Write-Host " "
Write-Host " "
$sqlRG = Read-Host -Prompt "Enter the Resource Group name for the SQL Server (suggest NDC-DB) "
$sqlName = Read-Host -Prompt "Enter the name of the SQL Server "
$sqlAdminUser = Read-Host -Prompt "Enter the admin account name for the SQL Server "
$sqlAdminPwd = Read-Host -Prompt "Enter the password for the SQL Server admin account " -AsSecureString

# Set a value for use later
$storageAccountName = "sqldbstorage$randomiser"

# Run the deployments
## First get the current set of Resource Groups so we know what's already there
$rgs = Get-AzResourceGroup

## Now run the Virtual Network Dployment
Write-Host -ForegroundColor Yellow $(Get-Date)
Write-Host -ForegroundColor Yellow "******************************************************************************************"
Write-Host -ForegroundColor Yellow "Deploying the Virtual Network to $netRG"
if ($rgs.ResourceGroupName -notcontains $netRG) {
    Write-Host -ForegroundColor Yellow "Creating new Resource Group '$netRG'"
    $check1 = New-AzResourceGroup -Name $netRG -Location 'AustraliaEast'
    Write-Host -ForegroundColor Yellow "... $($check1.ProvisioningState)"
} 
$vnetDeploy = New-AzResourceGroupDeployment -ResourceGroupName  $netRG -TemplateFile $infraFile  -Mode Incremental
if ($vnetDeploy.Outputs.virtualNetworkName.value){
    # The Virtual Network has deployed, so let us continue with the VM
    Write-Host -ForegroundColor Yellow "Virtual Network resources deployed"
    Write-Host -ForegroundColor Yellow "******************************************************************************************"
    Write-Host -ForegroundColor Yellow "Deploying the Virtual Machine to $vmRG"
    if ($rgs.ResourceGroupName -notcontains $vmRG) {
        Write-Host -ForegroundColor Yellow "Creating new Resource Group '$vmRG'"
        $check2 = New-AzResourceGroup -Name $vmRG -Location 'AustraliaEast'
        Write-Host -ForegroundColor Yellow "... $($check2.ProvisioningState)"
    } 
    $vmDeploy = New-AzResourceGroupDeployment -ResourceGroupName  $vmRG -TemplateFile $VMFile -TemplateParameterFile $VMParams -vmName $vmName -vmAdminLogin $vmAdminUser -vmAdminPassword $vmAdminPwd -randomiser $randomiser -vnetResourceGroup $netRG -Mode Incremental

    if ($vmDeploy.Outputs.virtualMachineName.value) {
        # The Virtual Machine has deployed, so finally we do  the SQL Server
        Write-Host -ForegroundColor Yellow "Virtual Machine resources deployed"
        Write-Host -ForegroundColor Yellow "******************************************************************************************"
        Write-Host -ForegroundColor Yellow "Deploying SQL Server to $sqlRG "
        if ($rgs.ResourceGroupName -notcontains $sqlRG) {
            Write-Host -ForegroundColor Yellow "Creating new Resource Group '$sqlRG'"
            $check3 = New-AzResourceGroup -Name $sqlRG -Location 'AustraliaEast'
            Write-Host -ForegroundColor Yellow "... $($check3.ProvisioningState)"
        } 
        $sqlDeploy = New-AzResourceGroupDeployment -ResourceGroupName  $sqlRG -TemplateFile $SQLFile -TemplateParameterFile $SQLParams -sqlAdminLogin $sqlAdminUser -sqlAdminPassword $sqlAdminPwd -sqlServerName $sqlName -randomiser $randomiser -clientIP $myIP -adminGroupSID $groupSID -Mode Incremental
        if ($sqlDeploy.Outputs.sqlServerName.value) {
            Write-Host -ForegroundColor Yellow "SQL Server resources deployed"
            Write-Host -ForegroundColor Yellow "******************************************************************************************"
            Write-Host -ForegroundColor Yellow $(Get-Date)
        } else {
            Write-Host -ForegroundColor Red "Failed to deploy SQL Server resources - please check and redeploy as required"
            Write-Host -ForegroundColor Red "******************************************************************************************"
            Write-Host -ForegroundColor Red $(Get-Date)
        }
    } else {
        Write-Host -ForegroundColor Red "Failed to deploy Virtual Machine resources - please check and redeploy as required"
        Write-Host -ForegroundColor Red "******************************************************************************************"
        Write-Host -ForegroundColor Red $(Get-Date)
    }
} else {
    Write-Host -ForegroundColor Red "Failed to deploy Virtual Network resources - please check and redeploy as required"
    Write-Host -ForegroundColor Red "******************************************************************************************"
    Write-Host -ForegroundColor Red $(Get-Date)
}

# Last step is to deploy a copy of WideWorldImporters to our new SQL DB
# check that the storage account exists - create if not
Write-Host -ForegroundColor Yellow "Checking for Storage Account ..."
$storage = Get-AzStorageAccount -ResourceGroupName $sqlRG -Name $storageAccountName -ErrorAction SilentlyContinue
if(!$storage) {
    Write-Host -ForegroundColor Yellow " ... not found. Creating new Storage Account '$storageAccountName' in '$sqlRG'"
    $storage = New-AzStorageAccount -ResourceGroupName $sqlRG -Name $storageAccountName -Location AustraliaEast -SkuName Standard_LRS
}
Write-Host -ForegroundColor Yellow "Complete"

# set the storage context
Set-AzCurrentStorageAccount -ResourceGroupName $sqlRG -Name $storage.StorageAccountName | Out-Null

# check that the container exists - create if not
Write-Host -ForegroundColor Yellow "Checking for Blob Container in Storage Account '$storageAccountName' ..."
$cxtStorage = Get-AzStorageContainer -Name 'sqlbacpac' -ErrorAction SilentlyContinue
if(!$cxtStorage) {
    Write-Host -ForegroundColor Yellow " ... not found. Creating new Blob Container 'sqlbacpac' in '$storageAccountName'"
    $cxtStorage = New-AzStorageContainer -Name 'sqlbacpac' | Out-Null
}
Write-Host -ForegroundColor Yellow "Complete"

# upload the BACPAC
Write-Host -ForegroundColor Yellow "Uploading WideWorldImporters BACPAC file to 'sqlbacpac' in '$storageAccountName' ... "
Set-AzStorageBlobContent -Container $cxtStorage.Name -File Resources\WideWorldImporters-Basic.bacpac | Out-Null
Write-Host -ForegroundColor Yellow "Complete"

# import the bacpac
Write-Host -ForegroundColor Yellow "Restoring WideWorldImporters from BACPAC file ... "
$importRequest = New-AzSqlDatabaseImport -ResourceGroupName $sqlRG `
   -ServerName "$sqlName-$randomiser" `
   -DatabaseName 'WideWorldImporters' `
   -DatabaseMaxSizeBytes 50000 `
   -StorageKeyType "StorageAccessKey" `
   -StorageKey $(Get-AzStorageAccountKey -ResourceGroupName $sqlRG -StorageAccountName $storage.StorageAccountName).Value[0] `
   -StorageUri $(Get-AzStorageBlob -Blob 'WideWorldImporters-Basic.bacpac' -Container $cxtStorage.Name).ICloudBlob.Uri.AbsoluteUri `
   -Edition "Standard" `
   -ServiceObjectiveName "S1" `
   -AdministratorLogin $sqlAdminUser `
   -AdministratorLoginPassword $sqlAdminPwd


$importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
[Console]::Write("Importing")
while ($importStatus.Status -eq "InProgress") {
    $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    [Console]::Write(".")
    Start-Sleep -s 10
}
[Console]::WriteLine("")
Write-Host -ForegroundColor Yellow "Restore of WideWorldImporters:  $($importStatus.Status)" 
Write-Host ""
Write-Host -ForegroundColor Yellow "SQL Server resources deployed"
Write-Host -ForegroundColor Yellow "******************************************************************************************"
Write-Host -ForegroundColor Yellow $(Get-Date)