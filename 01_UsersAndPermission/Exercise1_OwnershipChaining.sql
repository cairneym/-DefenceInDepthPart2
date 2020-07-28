-- Ensure that both users do not have explicit SELECT permission on the undelying objects
REVOKE SELECT ON [SalesLT].[SalesOrderHeader] TO [user1@<YOUR DOMAIN>.onmicrosoft.com];
REVOKE SELECT ON [SalesLT].[SalesOrderHeader] TO [user2@<YOUR DOMAIN>.onmicrosoft.com];
REVOKE SELECT ON [SalesLT].[SalesOrderDetail] TO [user1@<YOUR DOMAIN>.onmicrosoft.com];
REVOKE SELECT ON [SalesLT].[SalesOrderDetail] TO [user2@<YOUR DOMAIN>.onmicrosoft.com];

-- Ensure explicit EXECUTE permissions on the Sored Procedure
GRANT EXECUTE ON SalesLT.MultiTableQuery TO [user1@<YOUR DOMAIN>.onmicrosoft.com];
GRANT EXECUTE ON SalesLT.MultiTableQuery TO [user2@<YOUR DOMAIN>.onmicrosoft.com];

-- At this stage, go and EXECUTE the stored procedure as each user
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------

-- Now let's change it about. We will change one of the tables
ALTER AUTHORIZATION ON [SalesLT].[SalesOrderDetail] TO [user1@<YOUR DOMAIN>.onmicrosoft.com];
GO

-- EXECUTE the Stored Procedures again as each user
------------------------------------------------------------------


-- Change the permission back for now
ALTER AUTHORIZATION ON [SalesLT].[SalesOrderDetail] TO [dbo];
GO