# Defence In Depth: Part2
Full day session on Securing your Azure SQL Database


## Exercise 2 : Data Classification and Masking

As part of Data Security, we need to understand what data that we have in our databases and what level of additional protection it should be afforded. SQL Server provides an inbuilt Classification Tool to achive this. The Taxonomy is initially locked down and requires elevated permissions at the highest level in Azure to add additional users with the rights to edit the Taxonomy. Once this is done though, the Classification Taxonomy is available to all SQL Databases in your tenant.  

The usage of the Data CLassification is surfaced in a few ways. The most prominant and useful are frstly in the Database Audit outputs. The audit schema now includes an additional XML column with details of any Classifications in use for the audit event. These could be further exposed by also sending audits to an Event Hub, from which a Streaming Analytics query could look for anomalous entries and push them to a Service Bus queue where notifications could be send to your administrators.

The other way they are exposed is through the metadata of the database where it becomes easier to identify columns that should be either masked or encrypted to protect the sensitive data. 

In this exercise, we will examine the non-classified audit outputs before we go ahead an apply some Data Classifications to our database. We will use some of our classifications to instantly apply an appropriate masking funtion to the related columns and show how that is presented back to users and the permission needed to *UNMASK* the data. Finally we'll see how the audit output is modified and time dependent look at how we can hook up some Event Processing to identify incorrect usage of the Classified data. 

Before proceeding with the tasks, you will need to have followed the steps to grant [Permissions to Define Taxonomy](https://docs.microsoft.com/en-us/azure/security-center/security-center-management-groups) as mentioned in the ReadMe file. 

### Tasks

Update your current deployment using T-SQL to do the following tasks:

**1.**  Create a *USER WITHOUT LOGIN* named **MaskedUser**. Give this use *SELECT* permissions on the *Purchasing.Suppliers* table.
**2.**  Create a Stored Procedure *Application.GetCustomerInfo* that accepts a parameter named *BypassMasking* which is used to decide whether to use an *EXECUTE AS* caluse to run as the *MaskedUser* or as the calling user. Both options do the same SELECT from the *Purchasing.Suppliers* table 
**3.**  Configure ***Auditing*** for WideWorldImporters to a new Storage Account. Once configured, execute the query `EXEC Application.GetCustomerInfo 0`. Check the Audit Log using the query 
``` 
WITH QueryWithXML
AS
(
	SELECT session_server_principal_name, 
		   server_principal_name,
		   database_principal_name,
		   client_ip,
		   classification = CONVERT(xml, data_sensitivity_information )
	FROM sys.fn_get_audit_file ('https://<USE YOUR STORAGE ACCOUNT NAME HERE>.blob.core.windows.net/sqldbauditlogs/<USE YOUR SERVER NAME HERE>/WideWorldImporters/',default,default) aud
	WHERE event_time > DATEADD(MINUTE, -5, GETUTCDATE())
		  AND action_id IN (N'BCM', N'RCM')
)
SELECT q1.session_server_principal_name, 
	   q1.server_principal_name,
	   q1.database_principal_name,
	   q1.client_ip,
	   c.value('@label[1]', 'varchar(20)') as ClassificationLabel,
	   c.value('@information_type[1]', 'varchar(20)') as InformationType
FROM QueryWithXML q1
OUTER APPLY q1.classification.nodes('/sensitivity_attributes/sensitivity_attribute') AS T(c)
```  
In this case, the Classification columns should all return NULL.  
**4.**  From the **SQL Information Protection (preview)** blade, define a new Sensitivity Label named *Custom*. Attached to this, define a new Information Type for *Population* which uses *population* as the search term.
**5.**  Review the Data Classification for the WideWorldImporters database and confirm that there are a number of columns with the new classification.    
**6.**  Accept the recommendations for the *Custom* Sensitivity Label, all columns with a Phone Number and the **BankAccountName**, **BankAccountCode** and **BankAccountNumber** columns from the *Purchasing.Suppliers* table.  
**7**  Create a T-SQL query that will show all the accepted Data Classification settings in the *WideWorldImporters* database.  
**8.**  Use the T-SQL *ADD SENSITIVITY CLASSIFICATION* command to add a classification for columns with a *Fax Number* to be the same as the *Phone Number* classification from the Portal. Also classify those with the column *WebsiteURL* to have a label of *Public* with an information type of *Other*.    
**9.**  Use the *sensitivity classification* to produce a T-SQL query that will output a script to configure the classified columns with an appropriate Data Mask. Use a *Partial* function to mask the **Phone Number** and **Fax Number** columns, a different *Partial* function for the **WebsiteURL** columns and a *Default* function for the **Population** columns. Do not include the **BankAccount** related columns at this time.  
**10.**  Create Users for your Azure AD users in the WideWorldImporters database. Give one of these users *UNMASK* permission and create a script which shows the different query outputs per user.  
**11.**  Re-run the queries using the Stored Procedure *Application.GetCustomerInfo* and follow up by checking the Audit Log query output.  


#### Outcomes

From these exercises, we should see that there are no values appearing in the audit output before we have undertaken any Data Classifications. The move to Azure Security Center is very recent and has added a great deal of complexity in producing a custom Taxonomy. These steps need to be followed very carefully - and not that after applying the Security RBAC role you need to log out of the Portal and back in again.

The use of Data Classification does immediately help in identifying where we might have exposed data. Where the classification has identified *Highly Classified* for example, then what protection is there on those columns? Are they Masked as a minimum - but preferably encrypted (which we will cover in the next exercise). Being able to query the Classification Metadata mkes it tivial to apply the required security to each of these columns.

Now that we have Classified data, we should be making use of this. We will get addtional benefit by holding an additional source of the permitted usage of the classified columns - for example, is there a list of approved IP Addresses or Applications or even users? Anything that appears in the Audit trace can be mapped to the columns and anything where these do not match can give us immediate notification of activity worth investigating further - perhaps sealing off a potential Data Breach.


#### References

[Data Discovery & Classification in Azure SQL Database](https://docs.microsoft.com/en-us/azure/azure-sql/database/data-discovery-and-classification-overview)  
[Define Custom Taxonomy for Classification](https://docs.microsoft.com/en-us/azure/security-center/security-center-info-protection-policy)  
[Permissions to Define Taxonomy](https://docs.microsoft.com/en-us/azure/security-center/security-center-management-groups)  


#### Sample Solution

Sample T-SQL query scripts to demonstrate the tasks are included in the **Solution** subdirectory of this section.

