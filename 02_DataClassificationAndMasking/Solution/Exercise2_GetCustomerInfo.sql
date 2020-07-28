-- Do the Procedure defintion first so the batch won't complain
CREATE OR ALTER PROCEDURE [Application].[GetCustomerInfo]
	@BypassMasking BIT
AS
BEGIN

IF @BypassMasking = 0
BEGIN
	EXECUTE AS USER = 'MaskedUser'

	SELECT SupplierName,
	       SupplierReference,
		   BankAccountName,
		   BankAccountCode,
		   BankAccountNumber,
		   PhoneNumber,
		   FaxNumber, 
		   WebsiteURL,
		   PostalAddressLine2,
		   PostalPostalCode
	FROM Purchasing.Suppliers ;

	REVERT
END
ELSE
BEGIN
	SELECT SupplierName,
	       SupplierReference,
		   BankAccountName,
		   BankAccountCode,
		   BankAccountNumber,
		   PhoneNumber,
		   FaxNumber, 
		   WebsiteURL,
		   PostalAddressLine2,
		   PostalPostalCode
	FROM Purchasing.Suppliers ;
END

END
GO

-- Create the user
CREATE USER [MaskedUser] WITHOUT LOGIN ;
GO

-- Add the permissions
GRANT SELECT ON Purchasing.Suppliers TO MaskedUser ;
GO
