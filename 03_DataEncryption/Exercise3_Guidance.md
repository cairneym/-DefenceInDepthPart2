# Defence In Depth: Part2
Full day session on Securing your Azure SQL Database


## Exercise 3 : Data Encryption

At the highest levels of Data Security, we need to keep the data secure from all prying eyes and only allow those with the correct authority see the data. ***Always Encrypted*** is the technology that provdes this. With Always Encrypted, the data is encrypted at rest in the database, it is encrypted in transit, and, if the user does not have access to the correct key, remains encrypted in the client. Encyption is applied at the column level, so we would use this to protect our most sensitive data. It also implies that any attempt to access the data by side doors such as SQL Server Management Studio will still only show encrypted data unless that user also has access to the decryption key.

There is also a requirement for the client application to have an appropriate client driver. The additional level of security is that query parameters are also encrypted (where they reference encrypted columns) and so even the query predicates are protected in transit. 

To implement Always Encrypted, we need a secure Key Store for the *Column Master Key*. This key is used to encrypt and secure the *Column Encryption Key*, which is the actual key used to encrypt the data in the column. In Azure, we will store the *Culumn Master Key* in a Key Vault and restrict access to the key to only those users that should be permitted to decrypt the data.

In this exercise, we will create an Azure Key Vault. We then create the required keys to enable Always Encrypted and store the Column Master Key in the Key Vault. Our application then needs to be updated to retrive the Key from Azure Key Vault and decrypt the columns that we have encrypted.

### Tasks

Update your current deployment using PowerShell and T-SQL to do the following tasks:

**1.**  Create an Azure Key Vault. Limit the Access Policies to give yourself full control and the *NDC User1* the ***user get,wrapKey,unwrapKey,sign,verify*** permissions.  
**2.**  Create a new Key in the Key Vault to be used as the *Column Master Key*  
**3.**  Assign the *Column Master Key* to the WideWorldImporters database to create the *Column Encryption Key* encrypted by the *Column Master Key*.  
**4.**  Remove the Data Masking functions from the Banking related columns that we Classified in the previous exercise. Write a T-SQL query to apply Encryption to these columns using *Random* and *Deterministic* encryption as appropriate.  
**5.**  Open the **BaselineSample** project in Visual Studio. Run it as the *NDC User1* user. Update the code to connect to your SQL Server instance and run the application. Switch the *Data Masking* option to see how the permission works when the user does or doesn't have *UNMASK* permissions.       
**6.**  Update the Application to use *Always Encrypted* and get the *Column Master Key* from your Azure Key Vault. Plumb the switch for *Encryption* into the code so that the application either does or doesn't obtain the key from Key Vault and observe the impact on the returned dataset.  
**7.**  Connect to SQL Server using SQL Server Management Studio with your administrator account and run the same Stored Procedure.  

#### Outcomes and Validation

From these exercises, you will observe that the encryption protection works at two levels. If the user is unable to get the *Column Master Key* from Azure Key Vault, then the user will never be able to see the unencrypted data. Being an administrator for the database does not allow any increased access to the data and ensures a proper separation of duties for the DBAs who now no longer have unfettered access to all of the data.

The Data Masking switch should work for all users of the application. Note that this is not how it should be implemented in an actual application but should instead be based upon the user that is connecting. This is another factor when considering the authentication from your application to the database - when using a single SQL Login or a single MSI for the application then this fine-grained access for individual users becomes much harder to implement. Some aspects may be possible using the ***SESSION_CONTEXT()*** functionality.



#### References

[Provision Always Encrypted](https://docs.microsoft.com/en-us/sql/relational-databases/security/encryption/configure-always-encrypted-keys-using-powershell?view=sql-server-ver15)  
[Choosing an Encryption Algorithm](https://docs.microsoft.com/en-us/sql/relational-databases/security/encryption/choose-an-encryption-algorithm?view=sql-server-ver15)  
[Deterministic and Random Encryption](https://docs.microsoft.com/en-us/sql/relational-databases/security/encryption/always-encrypted-database-engine?view=sql-server-ver15#selecting--deterministic-or-randomized-encryption)  
[Developing with Always Encrypted](https://docs.microsoft.com/en-us/sql/relational-databases/security/encryption/always-encrypted-client-development?view=sql-server-ver15)


#### Sample Solution

Sample T-SQL query scripts to demonstrate the tasks are included in the **Solution** subdirectory of this section.

