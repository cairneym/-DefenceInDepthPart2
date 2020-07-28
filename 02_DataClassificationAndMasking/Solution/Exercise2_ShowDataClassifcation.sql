-- Create the classifications in the database
ADD SENSITIVITY CLASSIFICATION TO
[Application].[People].[FaxNumber], [Purchasing].[Suppliers].[FaxNumber], [Sales].[Customers].[FaxNumber]
WITH (LABEL='Confidential', INFORMATION_TYPE='Contact Info' );
GO

ADD SENSITIVITY CLASSIFICATION TO
[Purchasing].[Suppliers].[WebsiteURL], [Sales].[Customers].[WebsiteURL]
WITH (LABEL='Public', INFORMATION_TYPE='Other' );
GO

-- Show all of the classified columns in the database
SELECT
  SCHEMA_NAME(obj.schema_id) as [SchemaName],
  obj.name AS [TableName], 
  col.name As [ColumnName],
  [Label], 
  [Label_ID], 
  [Information_Type], 
  [Information_Type_ID]
FROM
  sys.sensitivity_classifications sc
     left join sys.all_objects obj on sc.major_id = obj.object_id
     left join sys.all_columns col on sc.major_id = col.object_id
                                  and sc.minor_id = col.column_id ;
GO


-- Extract the script to apply the Masking based on the Classifications
SELECT 
  'ALTER TABLE ' + SCHEMA_NAME(obj.schema_id) + '.' + obj.name
  + ' 
  ALTER COLUMN ' + col.name
  + ' ADD MASKED WITH (FUNCTION = ''partial(6, "XXX-XXXX", 0)'') ;
GO'
FROM
  sys.sensitivity_classifications sc
     left join sys.all_objects obj on sc.major_id = obj.object_id
     left join sys.all_columns col on sc.major_id = col.object_id
                                  and sc.minor_id = col.column_id
WHERE CAST([information_type] as VARCHAR(128)) = 'Contact Info' 
UNION ALL
SELECT 
  'ALTER TABLE ' + SCHEMA_NAME(obj.schema_id) + '.' + obj.name
  + ' 
  ALTER COLUMN ' + col.name
  + ' ADD MASKED WITH (FUNCTION = ''partial(10, "XXX.com", 0)'') ;
GO'
FROM
  sys.sensitivity_classifications sc
     left join sys.all_objects obj on sc.major_id = obj.object_id
     left join sys.all_columns col on sc.major_id = col.object_id
                                  and sc.minor_id = col.column_id
WHERE CAST([information_type] as VARCHAR(128)) = 'Other' 
UNION ALL
SELECT 
  'ALTER TABLE ' + SCHEMA_NAME(obj.schema_id) + '.' + obj.name
  + ' 
  ALTER COLUMN ' + col.name
  + ' ADD MASKED WITH (FUNCTION = ''default()'') ;
GO'
FROM
  sys.sensitivity_classifications sc
     left join sys.all_objects obj on sc.major_id = obj.object_id
     left join sys.all_columns col on sc.major_id = col.object_id
                                  and sc.minor_id = col.column_id
WHERE CAST([information_type] as VARCHAR(128)) = 'Populations' ;


-- Apply the script
ALTER TABLE Application.People     ALTER COLUMN PhoneNumber ADD MASKED WITH (FUNCTION = 'partial(6, "XXX-XXXX", 0)') ;  GO
ALTER TABLE Application.People     ALTER COLUMN FaxNumber ADD MASKED WITH (FUNCTION = 'partial(6, "XXX-XXXX", 0)') ;  GO
ALTER TABLE Purchasing.Suppliers     ALTER COLUMN PhoneNumber ADD MASKED WITH (FUNCTION = 'partial(6, "XXX-XXXX", 0)') ;  GO
ALTER TABLE Purchasing.Suppliers     ALTER COLUMN FaxNumber ADD MASKED WITH (FUNCTION = 'partial(6, "XXX-XXXX", 0)') ;  GO
ALTER TABLE Sales.Customers     ALTER COLUMN PhoneNumber ADD MASKED WITH (FUNCTION = 'partial(6, "XXX-XXXX", 0)') ;  GO
ALTER TABLE Sales.Customers     ALTER COLUMN FaxNumber ADD MASKED WITH (FUNCTION = 'partial(6, "XXX-XXXX", 0)') ;  GO
ALTER TABLE Purchasing.Suppliers     ALTER COLUMN WebsiteURL ADD MASKED WITH (FUNCTION = 'partial(10, "XXX.com", 0)') ;  GO
ALTER TABLE Sales.Customers     ALTER COLUMN WebsiteURL ADD MASKED WITH (FUNCTION = 'partial(10, "XXX.com", 0)') ;  GO
ALTER TABLE Application.Countries     ALTER COLUMN LatestRecordedPopulation ADD MASKED WITH (FUNCTION = 'default()') ;  GO
ALTER TABLE Application.StateProvinces     ALTER COLUMN LatestRecordedPopulation ADD MASKED WITH (FUNCTION = 'default()') ;  GO
ALTER TABLE Application.Cities     ALTER COLUMN LatestRecordedPopulation ADD MASKED WITH (FUNCTION = 'default()') ;  GO

