# Defence In Depth: Part2
Second Part of a Full day session on Securing your Azure SQL Database

## Pre-requisites

You need to have access to an Azure Subscription and a copy of the WideWorldImporters database created. You will also need Owner permissions within your subscription as we will be adding Groups and Users to the associated Azure Active Directory and also applying other RBAC permissions throughout the workshop, so you will need these elevated permissions.

The simplest approach is to create a new Free Trial subscription which is sufficient to run all the exercises without any cost to you.

Your computer will also need to have Azure Powershell's *Az* module and also the *AzureAD* module installed.

Your computer will also need to have a SQL Client tool such as Azure Data Studio or SQL Server Management Studio.


## Part 2 : Securing the Data

The second part of this workshop focusses on the Azure SQL Database, and the security mechanisms that exist at that level to keep our data safe. Our plan for the workshop is to start from a very vanilla implementation of Azure SQL Database and then progressively harden it through each of the exercises.

You will learn what components can make a difference and will develop scripts to help check and implement these solutions.

At any stage, if you get stuck, there is a suggested solution in the ***Solution*** folder for each exercise.  

Afterwards, take the templates/scripts away with you and practice / adapt to your own business rules to get the best solution for yourself.


### Exercise 00 - Deploy a baseline environment

Navigate to the **00_DeployBaseline** folder and folow the instructions in the file *Exercise0_Guidance.md*.


### Exercise 01 - Update the SQL Server specific configurations

Navigate to the **01_UpdateSQLConfigs** folder and folow the instructions in the file *Exercise1_Guidance.md*.

