USE [Viewpoint]
GO

/****** Object:  View [dbo].[mvwISDVendorXref]    Script Date: 11/03/2014 14:38:58 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[mvwISDVendorXref]'))
DROP VIEW [dbo].[mvwISDVendorXref]
GO

USE [Viewpoint]
GO

/****** Object:  View [dbo].[mvwISDVendorXref]    Script Date: 11/03/2014 14:38:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create VIEW [dbo].[mvwISDVendorXref]
AS
SELECT DISTINCT
	apvm.VendorGroup
,	apvm.Vendor AS VPVendor
,	apvm.udCGCVendor AS CGCVendor
,	apvm.Name AS VendorName
,	apvm.udSubcontractorYN AS IsSubcontractor
,	apvm.Address 
,	apvm.Address2
,	apvm.City
,	apvm.State
,	apvm.Zip
,	cast(apvm.VendorGroup as varchar(5)) + '.' + ltrim(rtrim(apvm.Vendor)) as VendorKey
FROM
	APVM apvm LEFT OUTER JOIN
	HQCO hqco ON
		apvm.VendorGroup=hqco.VendorGroup
WHERE
	hqco.udTESTCo <> 'Y' 		

GO


