# Defence In Depth: Part2
Full day session on Securing your Azure SQL Database


## Exercise 1 : Logins, Users, and Permissions

Your intially deployed SQL Server has an Active Directory admin set so that we can make use of the Azure AD Users that we created. Having multiple users and multiple databases allows us to easily see the differences that the security settings can make to the access.

In this exercise, we will investigate the various combinations of Logins and Users that can access our databases. We will then look at some basics around the permission structure within SQL Server to better understand what the default built-in roles allow the principal to do. 

### Tasks

Update your current deployment using T-SQL to do the following tasks:

**1.**  Attempt to connect to each database individually for each of your three users. You will need to set the connection type to *Azure Directory - Password* and use the fully qualified name of the user, e.g. *user1@\<yourdomain\>.onmicrosoft.com*. Recall that at creation, *NDC Admin** was added to the *SQLAdmins* Azure AD security group and the others weren't. Note the combinations that work and those that don't.  
**2.**  Connect to the SQL Server using the *SQL admin* user (the initial admin login and password). Create a *User* for one of your Azure AD users using the `CREATE USER [] FROM EXTERNAL PROVIDER` syntax.  
**3.**  Change your connection to the SQL Server to use the *NDC Admin* user and using the `CREATE USER [] FROM EXTERNAL PROVIDER` syntax, create a user for each of the Azure AD users in each of the databases.  
**4.**  Make additional Query window connections to AdventureWorksLT for each User so that you can run the same query as each and compare the differences. Attempt to run `SELECT FirstName, LastName, EmailAddress, PasswordHash, PasswordSalt FROM SalesLT.Customer` from each window and note the differences. Now, from the *NDC Admin* query window, run `ALTER ROLE [db_datareader] ADD MEMBER [user1@\<your domain\>.onmicrosoft.com];`. Repeat the query for each of the Users.  
**5.**  Next, run the query `SELECT * FROM SalesLT.vGetAllCategories` for each user.  
**6.**  Open the file ***Exercise1_NewProc.sql*** in the *NDC Admin* query window and examine the contents. Pay attention to the permission related statments. What do you think should be the outcome of executing this Stored Procedure for each user?  
**7.**  In Object Explorer for the *NDC Admin* connection, expand the Views node. Right-click on *SalesLT.vGetAllCategories* and select *Script View as - Create To - New Query Editor Window*. Note that it only accesses *SalesLT.ProductCategory* In the *NDC Admin* query window, open ***Exercise1_ViewPermissions.sql*** and run this query. In each of the users query windows, re-run `SELECT * FROM SalesLT.vGetAllCategories`.  
**8.**  Based on the observations above, update the database permissions so that neither of *user1* or *user2* are able to `SELECT` from ***any*** of the tables in the database, but are still able to execute the Stored Procedure and select from the Views.  
**9.**  Then, as the *NDC Admin* user, open ***Exercise1_OwnershipChaining.sql*** and follow the steps. What has happened to cause this?  
**10.** Ceate 2 new users in the database using the *WITHOUT LOGIN* option. This creates a user that cannot be logged in with and only exists inside the database. Make a copy of the `dbo.BuildVersion` table and make the first user the owner of the table. Create a Stored Procedure using the *EXECUTE AS* option set to *OWNER* that selects from the new table. Make the second user the owner of the Stored Procedure. `GRANT EXECUTE` on the Stored Procedure to the regular users and try to excute it. Change the ownership of either the Table or the Stored Procedure to match and retry.  

#### Commentary

Permissions in SQL Server ***are complex!*** There is no doubt about that, and that's why so often the Built-In roles are used rather than anything more granular.

However, as we saw, there could be unintended consequences from that approach. Although we didn't explicitly say that User1 was permitted to query the Table or View, they were automatically granted *SELECT* on all tables and views through the Role Membership. User2 on the other hand had nothing explicitly granted and so had no access by default.

When we created the Stored Procedure, we *only* allowed User2 to execute the procedure  - nothing to the underlying tables. So how did they manage to get access to those tables? This is as a result of Ownership Chaining and is something exceptionally useful but also something to be very wary of in the database. We see this when we change the owner of one of the tables at the end of the exercise and the consequences that it had. It is good practice ***NOT*** to mix ownership within a SCHEMA since these tend to be logical goupings of related objects it should make sense that they can be managed as a group for some of the permissions. If you do have different owners of different schemas then you need to ensure that the permission flows carry down appropriately when needed.

The permissions terminology can also be confusing. The main permissions do make sense - ***GRANT*** and ***DENY*** are obvious in what they are doing, but what actually does ***REVOKE*** do? *REVOKE* does *NOT* in fact remove a *GRANT* permission (as you might logically think from the name) - what it actually does is remove *ANY* explicitly applied security permission on the object. That means it will remove either a *GRANT* or a *DENY*, whatever was applied on the object for the principal. Therefore use it with great care - the best way to check what the applied permissions are is to run the query:
```
--List all access provisioned to a sql user or windows user/group directly 
SELECT  
    [UserName] = CASE princ.[type] 
                    WHEN 'S' THEN princ.[name]
                    WHEN 'U' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
					WHEN 'E' THEN princ.[name] COLLATE Latin1_General_CI_AI
                 END,
    [UserType] = CASE princ.[type]
                    WHEN 'S' THEN 'SQL User'
                    WHEN 'U' THEN 'Windows User'
					WHEN 'E' THEN 'Azure AD User'
                 END,  
    [DatabaseUserName] = princ.[name],       
    [Role] = null,      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc,--perm.[class_desc],       
    [ObjectName] = OBJECT_NAME(perm.major_id),
    [ColumnName] = col.[name]
FROM    
    --database user
    sys.database_principals princ  
LEFT JOIN
    --Login accounts
    sys.user_token ulogin on princ.[sid] = ulogin.[sid]
LEFT JOIN        
    --Permissions
    sys.database_permissions perm ON perm.[grantee_principal_id] = princ.[principal_id]
LEFT JOIN
    --Table columns
    sys.columns col ON col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]
LEFT JOIN
    sys.objects obj ON perm.[major_id] = obj.[object_id]
WHERE 
    princ.[type] in ('S','U', 'E')
UNION
--List all access provisioned to a sql user or windows user/group through a database or application role
SELECT  
    [UserName] = CASE memberprinc.[type] 
                    WHEN 'S' THEN memberprinc.[name]
                    WHEN 'U' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
					WHEN 'E' THEN memberprinc.[name] COLLATE Latin1_General_CI_AI 
                 END,
    [UserType] = CASE memberprinc.[type]
                    WHEN 'S' THEN 'SQL User'
                    WHEN 'U' THEN 'Windows User'
					WHEN 'E' THEN 'Azure AD User'
                 END, 
    [DatabaseUserName] = memberprinc.[name],   
    [Role] = roleprinc.[name],      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc,--perm.[class_desc],   
    [ObjectName] = OBJECT_NAME(perm.major_id),
    [ColumnName] = col.[name]
FROM    
    --Role/member associations
    sys.database_role_members members
JOIN
    --Roles
    sys.database_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
JOIN
    --Role members (database users)
    sys.database_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]
LEFT JOIN
    --Login accounts
    sys.user_token ulogin on memberprinc.[sid] = ulogin.[sid]
LEFT JOIN        
    --Permissions
    sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
LEFT JOIN
    --Table columns
    sys.columns col on col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]
LEFT JOIN
    sys.objects obj ON perm.[major_id] = obj.[object_id]
UNION
--List all access provisioned to the public role, which everyone gets by default
SELECT  
    [UserName] = '{All Users}',
    [UserType] = '{All Users}', 
    [DatabaseUserName] = '{All Users}',       
    [Role] = roleprinc.[name],      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc,--perm.[class_desc],  
    [ObjectName] = OBJECT_NAME(perm.major_id),
    [ColumnName] = col.[name]
FROM    
    --Roles
    sys.database_principals roleprinc
LEFT JOIN        
    --Role permissions
    sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
LEFT JOIN
    --Table columns
    sys.columns col on col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]                   
JOIN 
    --All objects   
    sys.objects obj ON obj.[object_id] = perm.[major_id]
WHERE
    --Only roles
    roleprinc.[type] = 'R' AND
    --Only public role
    roleprinc.[name] = 'public' AND
    --Only objects of ours, not the MS objects
    obj.is_ms_shipped = 0
ORDER BY
    princ.[Name],
    OBJECT_NAME(perm.major_id),
    col.[name],
    perm.[permission_name],
    perm.[state_desc],
    obj.type_desc
```

Permissions can be further controlled by using the *EXECUTE AS* statement within a Stored Procedure. Again this should be used with caution, but is often a good way to keep access to sensitive resources available to only a restricted audience. Something to consider is creating *USERS without LOGIN* to be the Schema Owners to allow you to be more explicit about your permission defintions.

The use of the Built-In Database Roles is in almost all scenarios enabling a higher level of permissions than what the users actually should have. A solution for this could be to define your own Database Roles to have very specific permissions and add the users to these custom Database Roles.

One final thing to remember is that Database Permissions are **for the entire Database**. What does this mean? I find that it is very often forgotten that it is possible to connect to a database WITHOUT the application it was designed for. Many Developers will claim that they have the tightest security in their application and that additional effort at the Database is unnecessary. However, to properly defend your data, be aware that not every attack will come via the application and you should therefore design your security based on a User having direct access via domething like SQL Server Management Studio and design permissions accordingly.

#### References

[SQL Server Fixed Roles](https://docs.microsoft.com/en-us/dotnet/framework/data/adonet/sql/server-and-database-roles-in-sql-server#:~:text=Fixed%20database%20roles%20have%20a%20pre%2Ddefined%20set%20of%20permissions,maintenance%20activities%20on%20the%20database.)  
[Database Ownership Chains](https://docs.microsoft.com/en-us/dotnet/framework/data/adonet/sql/authorization-and-permissions-in-sql-server#ownership-chains)  
[Access Control Using Schemas](https://www.red-gate.com/simple-talk/sql/sql-training/schema-based-access-control-for-sql-server-databases/)  
[SQL Server Permissions Hierarchy](https://docs.microsoft.com/en-us/sql/relational-databases/security/permissions-hierarchy-database-engine?view=sql-server-ver15)  
  

#### Sample Solution

Sample T-SQL query scripts to demonstrate the tasks are included in the **Solution** subdirectory of this section.

