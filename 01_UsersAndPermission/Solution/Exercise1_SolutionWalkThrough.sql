/***************************************************************************************************
****************************************************************************************************
***                                                                                              ***
***                       USE SQLCMD MODE OR THIS WILL NOT WORK                                  ***
***                                                                                              ***
***                   ALSO, SET THE OUTPUT TO TEXT RATHER THAN GRID                              ***
***                                                                                              ***
****************************************************************************************************
***************************************************************************************************/
:SetVar domain martinndcmelbourneoutlook

-- First we create the Users
PRINT 'Creating Users';
CREATE USER [user1@$(domain).onmicrosoft.com] FROM EXTERNAL PROVIDER ;
CREATE USER [user2@$(domain).onmicrosoft.com] FROM EXTERNAL PROVIDER ;

-- Then we run the first basic query as each user in turn
PRINT 'Running 1st Query as each user  - no permissions granted yet so both should fail';
EXECUTE AS USER = 'user1@$(domain).onmicrosoft.com'
SELECT TOP(5) 'USER1' as RunContext, FirstName, LastName, EmailAddress, PasswordHash, PasswordSalt FROM SalesLT.Customer;
REVERT

EXECUTE AS USER = 'user2@$(domain).onmicrosoft.com'
SELECT TOP(5) 'USER2' as RunContext, FirstName, LastName, EmailAddress, PasswordHash, PasswordSalt FROM SalesLT.Customer;
REVERT

-- Now we add User1 to the db_datareader role
PRINT 'Adding User1 to db_datareader';
ALTER ROLE [db_datareader] ADD MEMBER [user1@$(domain).onmicrosoft.com];

-- Repeat the queries
PRINT 'Re-running 1st Query as each user - User1 should now have permisison but not User2';
EXECUTE AS USER = 'user1@$(domain).onmicrosoft.com'
SELECT TOP(5) 'USER1' as RunContext, FirstName, LastName, EmailAddress, PasswordHash, PasswordSalt FROM SalesLT.Customer;
REVERT

EXECUTE AS USER = 'user2@$(domain).onmicrosoft.com'
SELECT TOP(5) 'USER2' as RunContext, FirstName, LastName, EmailAddress, PasswordHash, PasswordSalt FROM SalesLT.Customer;
REVERT

-- Next we select from the View for each user
PRINT 'Selecting from the View as each user - again User1 will have broad SELECT access while User2 has none';
EXECUTE AS USER = 'user1@$(domain).onmicrosoft.com'
SELECT TOP(5) 'USER1' as RunContext, * FROM SalesLT.vGetAllCategories;
REVERT

EXECUTE AS USER = 'user2@$(domain).onmicrosoft.com'
SELECT TOP(5) 'USER2' as RunContext, * FROM SalesLT.vGetAllCategories;
REVERT

-- Create the Stored Procedure.  We wrap this in an EXECUTE call as we have to be in the same batch for the scripting variable to work here
PRINT 'Creating Stored Procedure';
DECLARE @newProc NVARCHAR(MAX)
SELECT @newProc = N'
CREATE OR ALTER PROCEDURE SalesLT.MultiTableQuery
AS
BEGIN

	SELECT TOP(5) SUSER_SNAME() as RunContext,
	       sh.SalesOrderNumber,
	       sh.AccountNumber,
		   sh.TotalDue,
		   sd.ProductID,
		   sd.OrderQty
	FROM SalesLT.SalesOrderHeader sh
	JOIN SalesLT.SalesOrderDetail sd ON sh.SalesOrderID = sd.SalesOrderID ;

END'
EXEC (@newProc);

-- Update the permissions
PRINT 'Updating permissions on base table and Stored Procedure - what does an explicit DENY do for User2?';
DENY SELECT ON SalesLT.Customer TO [user2@$(domain).onmicrosoft.com];
GRANT EXECUTE ON SalesLT.MultiTableQuery TO [user1@$(domain).onmicrosoft.com];
GRANT EXECUTE ON SalesLT.MultiTableQuery TO [user2@$(domain).onmicrosoft.com];

-- Next we select from the View for each user
PRINT 'Running the Stored Procedure for each user';
EXECUTE AS USER = 'user1@$(domain).onmicrosoft.com'
EXEC SalesLT.MultiTableQuery;
REVERT

EXECUTE AS USER = 'user2@$(domain).onmicrosoft.com'
EXEC SalesLT.MultiTableQuery;
REVERT

-- Change the permissions on the tables underneath the View
PRINT 'Adding DENY permission to the View''s base tables';
DENY SELECT ON SalesLT.ProductCategory TO [user1@$(domain).onmicrosoft.com];
DENY SELECT ON SalesLT.ProductCategory TO [user2@$(domain).onmicrosoft.com];
-- Apply a GRANT permission on the View to User2
PRINT 'Adding explicit GRANT permission to the View for User2 as they have no read access anywhere yet';
GRANT SELECT ON [SalesLT].[vGetAllCategories] TO [user2@$(domain).onmicrosoft.com];

-- Re run the View queries
PRINT 'Repeating the Select from the View as each user';
EXECUTE AS USER = 'user1@$(domain).onmicrosoft.com'
SELECT TOP(5) 'USER1' as RunContext, * FROM SalesLT.vGetAllCategories;
REVERT

EXECUTE AS USER = 'user2@$(domain).onmicrosoft.com'
SELECT TOP(5) 'USER2' as RunContext, * FROM SalesLT.vGetAllCategories;
REVERT

-- Remove any SELECT access on the tables
ALTER ROLE [db_datareader] DROP MEMBER [user1@$(domain).onmicrosoft.com];

REVOKE SELECT ON SalesLT.ProductCategory TO [user1@$(domain).onmicrosoft.com];
REVOKE SELECT ON SalesLT.ProductCategory TO [user2@$(domain).onmicrosoft.com];
REVOKE SELECT ON SalesLT.Customer TO [user1@$(domain).onmicrosoft.com];
REVOKE SELECT ON SalesLT.Customer TO [user2@$(domain).onmicrosoft.com];
REVOKE SELECT ON SalesLT.vGetAllCategories TO [user1@$(domain).onmicrosoft.com];
REVOKE SELECT ON SalesLT.vGetAllCategories TO [user2@$(domain).onmicrosoft.com];

DENY SELECT ON SCHEMA::SalesLT TO [user1@$(domain).onmicrosoft.com];
DENY SELECT ON SCHEMA::SalesLT TO [user2@$(domain).onmicrosoft.com];

GRANT EXECUTE ON SalesLT.MultiTableQuery TO [user1@$(domain).onmicrosoft.com];
GRANT EXECUTE ON SalesLT.MultiTableQuery TO [user2@$(domain).onmicrosoft.com];

GRANT SELECT ON SalesLT.vGetAllCategories TO [user1@$(domain).onmicrosoft.com];
GRANT SELECT ON SalesLT.vGetAllCategories TO [user2@$(domain).onmicrosoft.com];

-- Test we can still select from the View and Execute the Procedure
PRINT 'After DENY ALL - Check View access.  DENY at Schema level trumps the explicit GRANT, but Proc is OK';
EXECUTE AS USER = 'user1@$(domain).onmicrosoft.com'
SELECT TOP(5) 'USER1' as RunContext, * FROM SalesLT.vGetAllCategories;
REVERT

EXECUTE AS USER = 'user2@$(domain).onmicrosoft.com'
SELECT TOP(5) 'USER2' as RunContext, * FROM SalesLT.vGetAllCategories;
REVERT

PRINT 'After DENY ALL - Check Procedure access';
EXECUTE AS USER = 'user1@$(domain).onmicrosoft.com'
EXEC SalesLT.MultiTableQuery;
REVERT

EXECUTE AS USER = 'user2@$(domain).onmicrosoft.com'
EXEC SalesLT.MultiTableQuery;
REVERT

-- Apply the Ownership Chaining changes
REVOKE SELECT ON SCHEMA::SalesLT TO [user1@$(domain).onmicrosoft.com];
REVOKE SELECT ON SCHEMA::SalesLT TO [user2@$(domain).onmicrosoft.com];
GRANT SELECT ON SalesLT.vGetAllCategories TO [user1@$(domain).onmicrosoft.com];
GRANT SELECT ON SalesLT.vGetAllCategories TO [user2@$(domain).onmicrosoft.com];
ALTER AUTHORIZATION ON [SalesLT].[SalesOrderDetail] TO [user1@$(domain).onmicrosoft.com];

PRINT 'After OWNER CHANGE - Check Procedure access';
EXECUTE AS USER = 'user1@$(domain).onmicrosoft.com'
EXEC SalesLT.MultiTableQuery;
REVERT

EXECUTE AS USER = 'user2@$(domain).onmicrosoft.com'
EXEC SalesLT.MultiTableQuery;
REVERT

-- Revert the ownership
ALTER AUTHORIZATION ON [SalesLT].[SalesOrderDetail] TO [dbo];

-- Clean up the users
DROP USER [user1@martinndcmelbourneoutlook.onmicrosoft.com]
DROP USER [user2@martinndcmelbourneoutlook.onmicrosoft.com]
