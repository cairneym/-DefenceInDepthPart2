# Defence In Depth: Part2
Second Part of a Full day session on Securing your Azure SQL Database

## Pre-requisites

You need to have access to an Azure Subscription and a copy of the WideWorldImporters database created. You will also need Owner permissions within your subscription as we will be adding Groups and Users to the associated Azure Active Directory and also applying other RBAC permissions throughout the workshop, so you will need these elevated permissions.

The simplest approach is to create a new Free Trial subscription which is sufficient to run all the exercises without any cost to you.

You will need a suitable development and querying environment. This can either be your own computer if you have the appropriate software, or you can customise the Virtual Machine created in the ***00_BaselineConfig*** folder to increase the specification of the Virtual Machine to be a bit beefier.

The specific tools needed include:  
* A SQL Client tool such as Azure Data Studio or SQL Server Management Studio.  
* VSCode or another suitable PowerShell IDE  
* Visual Studio 2019 (Community Edition is fine) configured for C# development.  

For this Part of the Workshop, you will need to have a Management Group for your Azure tenant. Follow the process to ensure that you will have [Permissions to Define a Taxonomy](https://docs.microsoft.com/en-us/azure/security-center/security-center-management-groups) in Exercise2.

## Part 2 : Securing the Data

The second part of this workshop focusses on the Azure SQL Database, and the security mechanisms that exist at that level to keep our data safe. Our plan for the workshop is to start from a very vanilla implementation of Azure SQL Database and then progressively harden it through each of the exercises.

You will learn what components can make a difference and will develop scripts to help check and implement these solutions.

At any stage, if you get stuck, there is a suggested solution in the ***Solution*** folder for each exercise.  

Afterwards, take the templates/scripts away with you and practice / adapt to your own business rules to get the best solution for yourself.


### Exercise 00 - Deploy a baseline environment

Navigate to the **00_DeployBaseline** folder and folow the instructions in the file *Exercise0_Guidance.md*.


### Exercise 01 - Update the SQL Server specific configurations

Navigate to the **01_UpdateSQLConfigs** folder and folow the instructions in the file *Exercise1_Guidance.md*.


### Exercise 02 - Investigate Data Classification and Masking

Navigate to the **02_DataClassificationAndMasking** folder and folow the instructions in the file *Exercise2_Guidance.md*.


### Exercise 03 - Data Encryption

Navigate to the **03_DataEncryption** folder and folow the instructions in the file *Exercise3_Guidance.md*.

