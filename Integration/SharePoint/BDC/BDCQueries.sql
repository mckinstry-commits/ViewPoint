DECLARE @CGCJob varchar(10)
SELECT @CGCJob='Y00023'


DECLARE @VPJob varchar(10)
SELECT @VPJob=' 14789-001'

--Job
SELECT 
	cast(jcjm.JCCo as varchar(5)) + '.' + ltrim(rtrim(jcjm.Job)) as JobKey
,	jcjm.JCCo VPCo
,	jcjm.Job AS VPJob
,	CASE 
		WHEN (CHARINDEX('-',jcjm.udCGCJob) > 0) THEN LEFT(jcjm.udCGCJob,CHARINDEX('-',jcjm.udCGCJob)-1)
		ELSE null
	END AS CGCCo
,	CASE 
		WHEN (CHARINDEX('-',jcjm.udCGCJob) > 0) THEN SUBSTRING(jcjm.udCGCJob,CHARINDEX('-',jcjm.udCGCJob)+1,LEN(jcjm.udCGCJob)-CHARINDEX('-',jcjm.udCGCJob)+1)
		ELSE jcjm.udCGCJob
	END AS CGCJob
,	jcjm.udCGCJob
,	jcjm.Description as JobDesc
,	jcjm.MailAddress
,	jcjm.MailAddress2
,	jcjm.MailCity
,	jcjm.MailState
,	jcjm.MailZip
,	jcjm.ProjectMgr AS POC
,	jcmp.Name AS POCName
from 
	JCJM jcjm LEFT OUTER JOIN
	HQCO hqco ON
		jcjm.JCCo=hqco.HQCo LEFT OUTER	JOIN	
	JCMP jcmp ON
		jcjm.JCCo=jcmp.JCCo
	AND jcjm.ProjectMgr=jcmp.ProjectMgr
WHERE
	hqco.udTESTCo <> 'Y' 
AND SUBSTRING(jcjm.udCGCJob,CHARINDEX('-',jcjm.udCGCJob)+1,LEN(jcjm.udCGCJob)-CHARINDEX('-',jcjm.udCGCJob)+1) = @CGCJob
ORDER BY
	1
	
--SELECT * FROM udxrefPhase

--SELECT * FROM JCJP

--Phase	
SELECT 
	cast(jcjp.JCCo as varchar(5)) + '.' + ltrim(rtrim(jcjp.Job)) + cast(jcjp.PhaseGroup as varchar(5)) + cast(jcjp.Phase as varchar(15)) + cast(jcct.Abbreviation as varchar(5)) as PhaseKey
,	jcjp.JCCo
,	jcjp.Job
,	jcjp.PhaseGroup
,	jcjp.Phase AS VPPhase
,	jcch.CostType
,	jcct.Abbreviation AS CostTypeCode
,	jcct.Description AS CostTypeDesc
--,	(SELECT MAX(udxref.oldPhase) FROM udxrefPhase udxref WHERE udxref.VPCo=jcjp.JCCo AND udxref.newPhase=jcjp.Phase) AS CGCPayItem 
--,	udxref.oldPhase AS CGCPayItem
,	jcjp.Description
FROM 
	JCJP jcjp LEFT OUTER JOIN
	HQCO hqco ON
		jcjp.JCCo=hqco.HQCo LEFT OUTER	JOIN	
	JCCH jcch ON
		jcjp.JCCo=jcch.JCCo
	AND jcjp.PhaseGroup=jcch.PhaseGroup
	AND jcjp.Phase=jcch.Phase LEFT OUTER JOIN
	JCCT jcct ON
		jcch.PhaseGroup=jcch.PhaseGroup
	and	jcch.CostType=jcct.CostType /*LEFT OUTER JOIN	
	udxrefPhase udxref ON
		jcjp.JCCo=udxref.VPCo
	AND jcjp.Phase=udxref.newPhase  */
WHERE
	hqco.udTESTCo <> 'Y' 
AND LTRIM(RTRIM(jcjp.Job))=LTRIM(RTRIM(@VPJob))
ORDER BY
	1			
SELECT * FROM JCCH
--Customer	
SELECT DISTINCT
	cast(arcm.CustGroup as varchar(5)) + '.' + ltrim(rtrim(arcm.Customer)) as CustomerKey
,	arcm.CustGroup
,	arcm.Customer AS VPCustomer	
,	arcm.udCGCCustomer AS CGCCustomer
,	arcm.udASTCust AS AsteaCustomer
,	arcm.Name AS CustomerName
,	arcm.Address 
,	arcm.Address2
,	arcm.City
,	arcm.State
,	arcm.Zip

FROM 
	ARCM arcm LEFT OUTER JOIN
	HQCO hqco ON
		arcm.CustGroup=hqco.CustGroup 	
WHERE
	hqco.udTESTCo <> 'Y' 		
		

--Vendor
SELECT DISTINCT
	cast(apvm.VendorGroup as varchar(5)) + '.' + ltrim(rtrim(apvm.Vendor)) as VendorKey
,	apvm.VendorGroup
,	apvm.Vendor AS VPVendor
,	apvm.udCGCVendor AS CGCVendor
,	apvm.Name AS VendorName
,	apvm.udSubcontractorYN AS IsSubcontractor
,	apvm.Address 
,	apvm.Address2
,	apvm.City
,	apvm.State
,	apvm.Zip
FROM
	APVM apvm LEFT OUTER JOIN
	HQCO hqco ON
		apvm.VendorGroup=hqco.VendorGroup
WHERE
	hqco.udTESTCo <> 'Y' 		
		
SELECT * FROM APVM		