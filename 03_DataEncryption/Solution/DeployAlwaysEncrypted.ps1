#########################################################################################
#########################################################################################
##################                     PLEASE NOTE                     ##################
##################                                                     ##################
##################                                                     ##################
##################  THIS SCRIPT MUST BE RUN WITH ELEVATION OTHERWISE   ##################
##################   Add-SqlAzureAuthenticationContext COMMAND FAILS   ##################
##################                                                     ##################
#########################################################################################
#########################################################################################


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
$sqlInstalled = $(Get-InstalledModule | Where-Object {$_.Name -eq 'SqlServer'}).Name
if (-not($sqlInstalled)){
    Install-Module SqlServer -Scope CurrentUser
}
Import-Module "SqlServer" 

# Get the parameters needed to connect to AzureAD
$currContext = Get-AzContext
$tenantID = $CurrContext.Tenant.Id
$AccID = $currContext.Account.Id
$myAAD = Connect-AzureAD -TenantId $tenantID -AccountId $AccID

# Set the paths to the ARM Template and Parameter files - they will be relative to this script file
$thisPath = $PSScriptRoot

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
$sqlRG = Read-Host -Prompt "Enter the Resource Group name for the SQL Server (suggest NDC-DB) "
$sqlName = Read-Host -Prompt "Enter the name of the SQL Server "
$sqlAdminUser = Read-Host -Prompt "Enter the admin account name for the SQL Server "
$sqlAdminPwd = Read-Host -Prompt "Enter the password for the SQL Server admin account " -AsSecureString
Write-Host " "
Write-Host " "
$akvName = Read-Host -Prompt "Enter the name for your Azure Key Vault "
$akvKeyName = 'CMKAuto1'
$azureCtx = Get-AzContext 
Write-Host " "
Write-Host " "

# Create a column master key in Azure Key Vault.
Write-Host -ForegroundColor Yellow "Creating Azure Key Vault '$akvName' if it doesn't exist yet ... "
$hasAKV = Get-AzKeyVault -VaultName $akvName -ResourceGroupName $sqlRG
if (-not($hasAKV)) {
    Write-Host -ForegroundColor Yellow "... no Key Vault exists, creating ... "
    $hasAKV = New-AzKeyVault -ResourceGroupName $sqlRG -VaultName $akvName -Location AustraliaEast -Sku Standard -DisableSoftDelete
    Set-AzKeyVaultAccessPolicy -VaultName $akvName -ResourceGroupName $sqlRG -PermissionsToKeys get, create, delete, list, update, import, backup, restore, wrapKey, unwrapKey, sign, verify -UserPrincipalName $((Get-AzureAdUser -Filter "startswith(UserPrincipalName, '$($azureCtx.Account.Id.Split('@')[0])')").UserPrincipalName)
    $akvKey = Add-AzKeyVaultKey -VaultName $akvName -Name $akvKeyName -Destination Software
    Write-Host -ForegroundColor Yellow "... complete "
} else {
    Write-Host -ForegroundColor Yellow "... Key Vault exists, checking for key ... "
    Set-AzKeyVaultAccessPolicy -VaultName $akvName -ResourceGroupName $sqlRG -PermissionsToKeys get, create, delete, list, update, import, backup, restore, wrapKey, unwrapKey, sign, verify -UserPrincipalName $((Get-AzureAdUser -Filter "startswith(UserPrincipalName, '$($azureCtx.Account.Id.Split('@')[0])')").UserPrincipalName)
    $akvKey = Get-AzKeyVaultKey -VaultName $akvName -Name $akvKeyName -ErrorAction SilentlyContinue
    if (-not($akvKey)) {
        Write-Host -ForegroundColor Yellow " ... Key not found, creating ..."
        $akvKey = Add-AzKeyVaultKey -VaultName $akvName -Name $akvKeyName -Destination Software
        Write-Host -ForegroundColor Yellow "... complete "
    } else {
        Write-Host -ForegroundColor Yellow "... complete "
    }
}

# grant user1 permissions to the keys:
Set-AzKeyVaultAccessPolicy -VaultName $akvName -ResourceGroupName $sqlRG -PermissionsToKeys create,get,wrapKey,unwrapKey,sign,verify,list -UserPrincipalName $((Get-AzureADUser -Filter "displayName eq 'NDC User1'").UserPrincipalName)

# Connect to your database
$serverName = "$sqlName-$randomiser.database.windows.net"
$databaseName = "WideWorldImporters"
$adminCred = Get-Credential -Message 'Enter the full username and password for the adminuser account (adminuser@<YOURDOMAIN>.onmicrosoft.com)'
$connStr = "Server = $serverName; Database = $databaseName; Authentication = Active Directory Password; UID=$($adminCred.UserName); PWD=$($adminCred.GetNetworkCredential().password)"
$database = Get-SqlDatabase -ConnectionString $connStr 

# Get the Column Master Key settings
$CMKSettings = New-SqlAzureKeyVaultColumnMasterKeySettings -KeyUrl $($akvKey.Id)

# Create Column Master Key metadata in the database
$cmkName = 'WWICMK'
New-SqlColumnMasterKey -ColumnMasterKeySettings $CMKSettings -Name $cmkName -InputObject $database

# Allow Azure SQL Database to authenticate to Key Vault as you
Add-SqlAzureAuthenticationContext -Interactive

# Generate a column encryption key, encrypt it with the column master key and create column encryption key metadata in the database. 
$cekName = "WWICEK"
New-SqlColumnEncryptionKey -Name $cekName -InputObject $database -ColumnMasterKey $cmkName

# Change encryption schema

$encryptionChanges = @()

# Add changes for table [Purchasing].[Suppliers]
$encryptionChanges += New-SqlColumnEncryptionSettings -ColumnName Purchasing.Suppliers.BankAccountName -EncryptionType Deterministic -EncryptionKey "WWICEK"
$encryptionChanges += New-SqlColumnEncryptionSettings -ColumnName Purchasing.Suppliers.BankAccountBranch -EncryptionType Deterministic -EncryptionKey "WWICEK"
$encryptionChanges += New-SqlColumnEncryptionSettings -ColumnName Purchasing.Suppliers.BankAccountCode -EncryptionType Randomized -EncryptionKey "WWICEK"
$encryptionChanges += New-SqlColumnEncryptionSettings -ColumnName Purchasing.Suppliers.BankAccountNumber -EncryptionType Randomized -EncryptionKey "WWICEK"

Set-SqlColumnEncryption -ColumnEncryptionSettings $encryptionChanges -InputObject $database

