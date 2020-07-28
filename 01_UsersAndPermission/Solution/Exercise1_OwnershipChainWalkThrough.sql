-- Create two new users without logins
CREATE USER privateaccess WITHOUT LOGIN;
CREATE USER storedprocuser WITHOUT LOGIN;
GO

-- Make a cpy of the dbo.BuildVersion table
SELECT * 
INTO SalesLT.BuildVersion 
FROM dbo.BuildVersion ;
GO

-- Now change the ownership of this table to [privateaccess]
ALTER AUTHORIZATION ON SalesLT.BuildVersion TO [privateaccess];
GO

-- Create a Stored Procedure to read from the table
CREATE OR ALTER PROCEDURE SalesLT.GetBuildVersion
WITH EXECUTE AS OWNER
AS
BEGIN
	SELECT * FROM SalesLT.BuildVersion;
END
GO
GRANT EXECUTE ON SalesLT.GetBuildVersion TO [user1@<YOUR DOMAIN>.onmicrosoft.com];
GO

-- Initially this table will be owned by [dbo] so should be able to read the table
EXECUTE AS N'user1@<YOUR DOMAIN>.onmicrosoft.com'
EXECUTE SalesLT.GetBuildVersion ;
REVERT
GO

-- So now let's change the ownership of the Stored Procedure. We need to reset permissions afterwards as well
ALTER AUTHORIZATION ON SalesLT.GetBuildVersion TO [storedprocuser];
GO
GRANT EXECUTE ON SalesLT.GetBuildVersion TO [user1@<YOUR DOMAIN>.onmicrosoft.com];
GO

-- Now if we execute it we get a permissions failure on the table
EXECUTE AS N'user1@<YOUR DOMAIN>.onmicrosoft.com'
EXECUTE SalesLT.GetBuildVersion ;
REVERT
GO

-- So, if we change the table to have the same owner
ALTER AUTHORIZATION ON SalesLT.BuildVersion TO [storedprocuser];
GO

-- Now the Stored Procedure returns data
EXECUTE AS N'user1@<YOUR DOMAIN>.onmicrosoft.com'
EXECUTE SalesLT.GetBuildVersion ;
REVERT
GO

-- Set everything back to default
ALTER AUTHORIZATION ON SalesLT.BuildVersion TO SCHEMA OWNER;
ALTER AUTHORIZATION ON SalesLT.GetBuildVersion TO SCHEMA OWNER;
GO

DROP USER [storedprocuser];
DROP USER [privateaccess];
GO