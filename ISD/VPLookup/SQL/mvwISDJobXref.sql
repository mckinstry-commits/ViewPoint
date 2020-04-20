USE [Viewpoint]
GO

/****** Object:  View [dbo].[mvwISDJobXref]    Script Date: 11/03/2014 14:36:22 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[mvwISDJobXref]'))
DROP VIEW [dbo].[mvwISDJobXref]
GO

USE [Viewpoint]
GO

/****** Object:  View [dbo].[mvwISDJobXref]    Script Date: 11/03/2014 14:36:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[mvwISDJobXref]
AS

SELECT 
	jcjm.JCCo AS VPCo
,	ltrim(rtrim(jcjm.Job)) AS VPJob
,	xref.COMPANYNUMBER AS  CGCCo
,	ltrim(rtrim(xref.JOBNUMBER)) + CASE WHEN ltrim(rtrim(xref.SUBJOBNUMBER)) <> '' THEN '.' + ltrim(rtrim(xref.SUBJOBNUMBER)) ELSE '' END AS CGCJob
,	jcjm.Description as VPJobDesc
,	arcm.Customer AS VPCustomer
,	arcm.Name AS VPCustomerName
,	jcjm.MailAddress
,	jcjm.MailAddress2
,	jcjm.MailCity
,	jcjm.MailState
,	jcjm.MailZip
,	jcjm.ProjectMgr AS POC
,	jcmp.Name AS POCName
,	LOWER(jcmp.Email) AS POCEmail
--,	preh.PRCo AS POCPRCo
--,	preh.Employee AS POCEmployee
--,	preh.Email AS POCPREmail
,	jccm.udSalesPerson AS SalesPerson
,	jcmpsales.Name AS SalesPersonName
,	LOWER(jcmpsales.Email) AS SalesPersonEmail
,	REPLACE(cast(xref.VPCo as varchar(5)) + '.' + ltrim(rtrim(xref.VPJob)),' ','#') as JobKey
,	cast(jccm.CustGroup as varchar(5)) + '.' + ltrim(rtrim(jccm.Customer)) as CustomerKey
,	hqco.PhaseGroup
,	CASE jcjm.JobStatus
		WHEN 0 THEN '0 - Pending'
		WHEN 1 THEN '1 - Open'
		WHEN 2 THEN '2 - Soft Close'
		WHEN 3 THEN '3 - Hard Close'
	END AS JobStatus
,	glpi.Instance AS GLDepartmentNumber
,	glpi.Description AS GLDepartmentName
FROM 
	JCJM jcjm LEFT OUTER JOIN
	budxrefJCJobs xref ON
		jcjm.JCCo=xref.VPCo
	AND jcjm.Job=xref.VPJob  
	AND COALESCE(ltrim(rtrim(xref.SUBJOBNUMBER)),'') = '' LEFT OUTER JOIN	
	JCMP jcmp ON
		jcjm.JCCo=jcmp.JCCo
	AND jcjm.ProjectMgr=jcmp.ProjectMgr LEFT OUTER JOIN
	JCCM jccm ON
		jcjm.JCCo=jccm.JCCo
	AND jcjm.Contract=jccm.Contract LEFT OUTER JOIN
	ARCM arcm ON
		jccm.CustGroup=arcm.CustGroup
	AND arcm.Customer=jccm.Customer LEFT OUTER	JOIN	
	JCMP jcmpsales ON
		jccm.JCCo=jcmpsales.JCCo
	AND jccm.udSalesPerson=jcmpsales.ProjectMgr LEFT OUTER JOIN
	HQCO hqco ON
		jcjm.JCCo=hqco.HQCo /*LEFT OUTER JOIN
	dbo.PREHName preh ON
		jcmp.udPRCo=preh.PRCo
	AND jcmp.udEmployee=preh.Employee*/ LEFT OUTER JOIN
	JCDM jcdm ON
		jccm.JCCo=jcdm.JCCo
	AND jccm.Department=jcdm.Department LEFT OUTER JOIN
	GLPI glpi ON
		jcdm.GLCo=glpi.GLCo
	AND SUBSTRING(jcdm.OpenRevAcct,10,4)=glpi.Instance
	AND glpi.PartNo=3
WHERE 
	hqco.udTESTCo <> 'Y' 
--AND LTRIM(rtrim(xref.SUBJOBNUMBER))=''

GO

GRANT SELECT ON dbo.mvwISDJobXref TO IntegrationAccount
go


GRANT SELECT ON dbo.mvwISDJobXref TO Public
go

SELECT * FROM [mvwISDJobXref] where POCName like '%JON UGELSTAD%'


SELECT * FROM HQTX WHERE Description LIKE '%98296%'

select udPRCo, udEmployee, udEmployeeYN,* from APVM where udEmployee in ('58244','31335') 

