USE [Viewpoint]
GO

/****** Object:  View [dbo].[mvwISDJobPhaseXref]    Script Date: 11/03/2014 14:35:48 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[mvwISDJobPhaseXref]'))
DROP VIEW [dbo].[mvwISDJobPhaseXref]
GO

USE [Viewpoint]
GO

/****** Object:  View [dbo].[mvwISDJobPhaseXref]    Script Date: 11/03/2014 14:35:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



create VIEW [dbo].[mvwISDJobPhaseXref]
AS
SELECT 
	jcjm.JCCo AS VPCo
,	ltrim(rtrim(jcjm.Job)) AS VPJob
,	xref.CGCCo AS CGCCo
,	xref.CGCJob AS CGCJob
,	jcjm.Description AS VPJobDesc
,	xref.VPCustomer AS VPCustomer
,	xref.VPCustomerName AS VPCustomerName
,	xref.POC AS POC
,	xref.POCName AS POCName
,	xref.SalesPerson AS SalesPerson
,	xref.SalesPersonName AS SalesPersonName
,	jcch.PhaseGroup AS VPPhaseGroup
,	jcch.Phase AS VPPhase
,	jcjp.ActiveYN AS IsPhaseActive
--,	jcch.CostType
,	case jcch.CostType
		WHEN 1 THEN 'L'
		WHEN 2 THEN 'M'
		WHEN 3 THEN 'S'
		WHEN 4 THEN 'O'
		WHEN 5 THEN 'E'
		ELSE 'X'
	END AS CostTypeCode
--,	jcct.Abbreviation AS CostTypeCode
,	case jcch.CostType
		WHEN 1 THEN 'Labor'
		WHEN 2 THEN 'Material'
		WHEN 3 THEN 'Subcontract'
		WHEN 4 THEN 'Other'
		WHEN 5 THEN 'McK Owned Equipment'
		ELSE 'X'
	END AS CostTypeDesc
--,	jcct.Description AS CostTypeDesc
,	jcjp.Description AS VPPhaseDescription
,	jcjp.Notes AS ConversionNotes
,	REPLACE(cast(jcjp.JCCo as varchar(5)) + '.' + ltrim(rtrim(jcjp.Job)) + '.' + cast(ltrim(rtrim(jcjp.PhaseGroup)) as varchar(5)) + '.' + cast(ltrim(rtrim(jcjp.Phase)) as varchar(15)) + '.' 
	+ cast(ltrim(rtrim(case jcch.CostType
		WHEN 1 THEN 'L'
		WHEN 2 THEN 'M'
		WHEN 3 THEN 'S'
		WHEN 4 THEN 'O'
		WHEN 5 THEN 'E'
		ELSE 'X'
	END)) as varchar(5)),' ','#') as PhaseKey
,	REPLACE(cast(jcjm.JCCo as varchar(5)) + '.' + ltrim(rtrim(jcjm.Job)),' ','#') as JobKey 
,	xref.CustomerKey AS CustomerKey
FROM 
	JCJM jcjm INNER JOIN
	JCJP jcjp ON 
		jcjm.JCCo=jcjp.JCCo
	AND LTRIM(RTRIM(jcjm.Job))=LTRIM(RTRIM(jcjp.Job)) INNER JOIN	 	
	JCCH jcch ON
		jcjp.JCCo=jcch.JCCo
	AND jcjp.Job=jcch.Job
	AND jcjp.PhaseGroup=jcch.PhaseGroup
	AND jcjp.Phase=jcch.Phase LEFT OUTER JOIN
	mvwISDJobXref xref ON
		jcjm.JCCo=xref.VPCo
	AND REPLACE(cast(jcjm.JCCo as varchar(5)) + '.' + ltrim(rtrim(jcjm.Job)),' ','#')=xref.JobKey JOIN
	HQCO hqco ON
		jcjm.JCCo=hqco.HQCo
	AND hqco.udTESTCo <> 'Y'
--WHERE
--	jcjp.JCCo NOT IN (SELECT HQCo FROM HQCO WHERE udTESTCo='Y')
--AND	LTRIM(RTRIM(jcjm.Job))='11071-001'
--ORDER BY
--	jcch.Phase
--,	jcch.CostType
GO

GRANT SELECT ON dbo.mvwISDJobPhaseXref TO IntegrationAccount
go


--SELECT * FROM [mvwISDJobXref] where JobKey='20.21049-001'
--SELECT * FROM [mvwISDJobPhaseXref] where JobKey='20.21049-001'