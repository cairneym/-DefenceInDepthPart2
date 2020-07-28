-- Explicitly DENY the SELECT permissions on the base table to both users
DENY SELECT ON SalesLT.ProductCategory TO [user1@<YOUR DOMAIN>.onmicrosoft.com];
DENY SELECT ON SalesLT.ProductCategory TO [user2@<YOUR DOMAIN>.onmicrosoft.com];
GO

-- Apply a GRANT permission on the View to User2
GRANT SELECT ON [SalesLT].[vGetAllCategories] TO [user2@<YOUR DOMAIN>.onmicrosoft.com];
GO
