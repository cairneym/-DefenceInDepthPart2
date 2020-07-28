CREATE OR ALTER PROCEDURE SalesLT.MultiTableQuery
AS
BEGIN

	SELECT sh.SalesOrderNumber,
	       sh.AccountNumber,
		   sh.TotalDue,
		   sd.ProductID,
		   sd.OrderQty
	FROM SalesLT.SalesOrderHeader sh
	JOIN SalesLT.SalesOrderDetail sd ON sh.SalesOrderID = sd.SalesOrderID ;

END
GO

REVOKE SELECT ON SalesLT.Customer TO [user2@<YOUR DOMAIN>.onmicrosoft.com];
GO

GRANT EXECUTE ON SalesLT.MultiTableQuery TO [user1@<YOUR DOMAIN>.onmicrosoft.com];
GRANT EXECUTE ON SalesLT.MultiTableQuery TO [user2@<YOUR DOMAIN>.onmicrosoft.com];
GO
