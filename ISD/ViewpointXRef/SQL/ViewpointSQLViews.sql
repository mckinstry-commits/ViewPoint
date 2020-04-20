USE Viewpoint
go

--Job

IF EXISTS ( SELECT 1 FROM sysobjects WHERE name='mvwISDJobXref' AND type='V')
BEGIN
	PRINT 'DROP VIEW mvwISDJobXref'
	DROP VIEW mvwISDJobXref
END
go

PRINT 'CREATE VIEW mvwISDJobXref'
go

CREATE VIEW mvwISDJobXref
AS

SELECT 
	xref.VPCo VPCo
,	ltrim(rtrim(xref.VPJob)) AS VPJob
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
,	jccm.udSalesPerson AS SalesPerson
,	jcmpsales.Name AS SalesPersonName
,	REPLACE(cast(xref.VPCo as varchar(5)) + '.' + ltrim(rtrim(xref.VPJob)),' ','#') as JobKey
,	cast(jccm.CustGroup as varchar(5)) + '.' + ltrim(rtrim(jccm.Customer)) as CustomerKey
,	hqco.PhaseGroup
FROM 
	budxrefJCJobs xref LEFT OUTER JOIN
	JCJM jcjm ON
		xref.VPCo=jcjm.JCCo
	AND LTRIM(RTRIM(xref.VPJob))=LTRIM(RTRIM(jcjm.Job))  LEFT OUTER	JOIN	
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
		xref.VPCo=hqco.HQCo
WHERE 
	hqco.udTESTCo <> 'Y' 
AND ltrim(rtrim(xref.SUBJOBNUMBER)) = '' 
	
--SELECT 
--	jcjm.JCCo VPCo
--,	ltrim(rtrim(jcjm.Job)) AS VPJob
--,	CASE 
--		WHEN (CHARINDEX('-',jcjm.udCGCJob) > 0) THEN LEFT(jcjm.udCGCJob,CHARINDEX('-',jcjm.udCGCJob)-1)
--		ELSE null
--	END AS CGCCo
--,	CASE 
--		WHEN (CHARINDEX('-',jcjm.udCGCJob) > 0) THEN SUBSTRING(jcjm.udCGCJob,CHARINDEX('-',jcjm.udCGCJob)+1,LEN(jcjm.udCGCJob)-CHARINDEX('-',jcjm.udCGCJob)+1)
--		ELSE jcjm.udCGCJob
--	END AS CGCJob
--,	jcjm.Description as VPJobDesc
--,	arcm.Customer AS VPCustomer
--,	arcm.Name AS VPCustomerName
--,	jcjm.MailAddress
--,	jcjm.MailAddress2
--,	jcjm.MailCity
--,	jcjm.MailState
--,	jcjm.MailZip
--,	jcjm.ProjectMgr AS POC
--,	jcmp.Name AS POCName
--,	jccm.udSalesPerson AS SalesPerson
--,	jcmpsales.Name AS SalesPersonName
--,	REPLACE(cast(jcjm.JCCo as varchar(5)) + '.' + ltrim(rtrim(jcjm.Job)),' ','#') as JobKey
--,	cast(jccm.CustGroup as varchar(5)) + '.' + ltrim(rtrim(jccm.Customer)) as CustomerKey
--,	hqco.PhaseGroup
--from 
--	HQCO hqco LEFT OUTER JOIN
--	JCJM jcjm ON 
--		jcjm.JCCo=hqco.HQCo LEFT OUTER	JOIN	
--	JCMP jcmp ON
--		jcjm.JCCo=jcmp.JCCo
--	AND jcjm.ProjectMgr=jcmp.ProjectMgr LEFT OUTER JOIN
--	JCCM jccm ON
--		jcjm.JCCo=jccm.JCCo
--	AND jcjm.Contract=jccm.Contract LEFT OUTER JOIN
--	ARCM arcm ON
--		hqco.CustGroup=arcm.CustGroup
--	AND arcm.Customer=jccm.Customer LEFT OUTER	JOIN	
--	JCMP jcmpsales ON
--		jccm.JCCo=jcmpsales.JCCo
--	AND jccm.udSalesPerson=jcmpsales.ProjectMgr 
--WHERE
--	jcjm.Job IS NOT null
--AND	hqco.udTESTCo <> 'Y' 

go

--Phase	
IF EXISTS ( SELECT 1 FROM sysobjects WHERE name='mvwISDJobPhaseXref' AND type='V')
BEGIN
	PRINT 'DROP VIEW mvwISDJobPhaseXref'
	DROP VIEW mvwISDJobPhaseXref
END
go


--SELECT * FROM budxrefPhase
PRINT 'CREATE VIEW mvwISDJobPhaseXref'
go

create VIEW mvwISDJobPhaseXref
AS
SELECT DISTINCT
	job.VPCo
,	ltrim(rtrim(job.VPJob)) AS VPJob
,	job.CGCCo
,	job.CGCJob
,	job.VPJobDesc
,	job.VPCustomer
,	job.VPCustomerName
,	job.POC
,	job.POCName
,	job.SalesPerson
,	job.SalesPersonName
,	jcjp.PhaseGroup  AS VPPhaseGroup
,	jcjp.Phase AS VPPhase
--,	jcch.CostType
,	jcct.Abbreviation AS CostTypeCode
,	jcct.Description AS CostTypeDesc
,	jcjp.Description AS VPPhaseDescription
,	jcjp.Notes AS ConversionNotes
,	REPLACE(cast(jcjp.JCCo as varchar(5)) + '.' + ltrim(rtrim(jcjp.Job)) + '.' + cast(ltrim(rtrim(jcjp.PhaseGroup)) as varchar(5)) + '.' + cast(ltrim(rtrim(jcjp.Phase)) as varchar(15)) + '.' + cast(ltrim(rtrim(jcct.Abbreviation)) as varchar(5)),' ','#') as PhaseKey
,	job.JobKey
,	job.CustomerKey
FROM 
	mvwISDJobXref job JOIN
	JCJP jcjp ON 
		job.VPCo=jcjp.JCCo
	AND job.VPJob=LTRIM(RTRIM(jcjp.Job)) 
	AND job.PhaseGroup=jcjp.PhaseGroup JOIN	 	
	JCCH jcch ON
		jcjp.JCCo=jcch.JCCo
	AND jcjp.Job=jcch.Job
	AND jcjp.PhaseGroup=jcch.PhaseGroup
	AND jcjp.Phase=jcch.Phase JOIN
	JCCT jcct ON
		jcch.PhaseGroup=jcch.PhaseGroup
	and	jcch.CostType=jcct.CostType 		
go


--JobPhase	
IF EXISTS ( SELECT 1 FROM sysobjects WHERE name='mvwISDJobPhases' AND type='V')
BEGIN
	PRINT 'DROP VIEW mvwISDJobPhases'
	DROP VIEW mvwISDJobPhases
END
go
--Customer	
IF EXISTS ( SELECT 1 FROM sysobjects WHERE name='mvwISDCustomerXref' AND type='V')
BEGIN
	PRINT 'DROP VIEW mvwISDCustomerXref'
	DROP VIEW mvwISDCustomerXref
END
go

PRINT 'CREATE VIEW mvwISDCustomerXref'
go

create VIEW mvwISDCustomerXref
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
go

--Vendor
IF EXISTS ( SELECT 1 FROM sysobjects WHERE name='mvwISDVendorXref' AND type='V')
BEGIN
	PRINT 'DROP VIEW mvwISDVendorXref'
	DROP VIEW mvwISDVendorXref
END
go

PRINT 'CREATE VIEW mvwISDVendorXref'
go

create VIEW mvwISDVendorXref
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

--Phase Master

IF EXISTS ( SELECT 1 FROM sysobjects WHERE name='mvwISDPhaseMaster' AND type='V')
BEGIN
	PRINT 'DROP VIEW mvwISDPhaseMaster'
	DROP VIEW mvwISDPhaseMaster
END
go

PRINT 'CREATE VIEW mvwISDPhaseMaster'
go

create VIEW mvwISDPhaseMaster
AS
SELECT 
	jcpm.*
,	ltrim(rtrim(jcpm.PhaseGroup)) + '.' + ltrim(rtrim(jcpm.Phase)) AS PhaseMasterKey
FROM
	JCPM jcpm 
WHERE
	jcpm.PhaseGroup IN (SELECT DISTINCT PhaseGroup FROM HQCO WHERE udTESTCo <> 'Y' )
go


--Phase Master Cost Types
IF EXISTS ( SELECT 1 FROM sysobjects WHERE name='mvwISDPhaseMasterCostTypes' AND type='V')
BEGIN
	PRINT 'DROP VIEW mvwISDPhaseMasterCostTypes'
	DROP VIEW mvwISDPhaseMasterCostTypes
END
go

PRINT 'CREATE VIEW mvwISDPhaseMasterCostTypes'
go

create VIEW mvwISDPhaseMasterCostTypes
AS	
SELECT 
	jcpc.* 
,	jcct.Abbreviation AS CostTypeCode
,	jcct.Description AS CostTypeDesc
,	ltrim(rtrim(jcpc.PhaseGroup)) + '.' + ltrim(rtrim(jcpc.Phase)) AS PhaseMasterKey
,	ltrim(rtrim(jcpc.PhaseGroup)) + '.' + ltrim(rtrim(jcpc.Phase)) + '.' +  ltrim(rtrim(jcct.Abbreviation)) AS PhaseMasterCostTypeKey
FROM 
	JCPC jcpc LEFT OUTER JOIN
	mvwISDPhaseMaster t1 ON
		jcpc.PhaseGroup=t1.PhaseGroup
	AND jcpc.Phase=t1.Phase JOIN
	JCCT jcct ON
		jcct.PhaseGroup=jcpc.PhaseGroup
	AND jcct.CostType=jcpc.CostType
	
GO


--SELECT * FROM  mvwISDCustomerXref WHERE      CustomerKey='1.217330'
--SELECT * FROM  mvwISDJobXref WHERE CGCJob like '%00340%'    CustomerKey='1.217330'

--SELECT * FROM  mvwISDJobXref WHERE      JobKey='1.10001-001'
--SELECT * FROM  mvwISDJobPhaseXref WHERE JobKey= '20.20562-001'

--SELECT * FROM mvwISDJobPhases
--SELECT * FROM mvwISDCustomerXref	
--SELECT * FROM mvwISDVendorXref

--SELECT * FROM mvwISDPhaseMaster
--SELECT * FROM mvwISDPhaseMasterCostTypes
GO

