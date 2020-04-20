USE [Viewpoint]
GO

/****** Object:  View [dbo].[mvwISDCustomerXref]    Script Date: 11/03/2014 14:34:58 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[mvwISDCustomerXref]'))
DROP VIEW [dbo].[mvwISDCustomerXref]
GO

USE [Viewpoint]
GO

/****** Object:  View [dbo].[mvwISDCustomerXref]    Script Date: 11/03/2014 14:34:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create VIEW [dbo].[mvwISDCustomerXref]
AS
SELECT DISTINCT
	arcm.CustGroup
,	arcm.Customer AS VPCustomer	
,	arcm.udCGCCustomer AS CGCCustomer
,	arcm.udASTCust AS AsteaCustomer
,	arcm.Name AS CustomerName
,	arcm.Address 
,	arcm.Address2
,	arcm.City
,	arcm.State
,	arcm.Zip
,	cast(arcm.CustGroup as varchar(5)) + '.' + ltrim(rtrim(arcm.Customer)) as CustomerKey
FROM 
	ARCM arcm LEFT OUTER JOIN
	HQCO hqco ON
		arcm.CustGroup=hqco.CustGroup 	
WHERE
	hqco.udTESTCo <> 'Y' 		

GO


