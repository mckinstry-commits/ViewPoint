USE MCK_INTEGRATION
go

IF EXISTS ( SELECT 1 FROM sysobjects WHERE type='V' AND name='vwVPEmployeeInfo' )
BEGIN
	PRINT 'DROP VIEW vwVPEmployeeInfo'
	DROP VIEW vwVPEmployeeInfo
END

PRINT 'CREATE VIEW vwVPEmployeeInfo'
go


CREATE  view [dbo].[vwVPEmployeeInfo]
as
select
		emp.PRCo
	,	emp.Craft
	,	emp.Class
	,	emp.PRDept
	,	substring(prdp.JCFixedRateGLAcct,10,4) AS GLDept
	,	emp.PRGroup
	,	emp.Employee
	--,	Q.Vendor
	--,	v.VendorGroup
	,	Q.MatlGroup
	,	Q.TaxGroup
from 
		Viewpoint.dbo.PREHFullName emp INNER JOIN 
		Viewpoint.dbo.PRDP prdp ON
			emp.PRCo=prdp.PRCo
		AND emp.PRDept=prdp.PRDept INNER JOIN 
		Viewpoint.dbo.HQCO Q on 
			Q.HQCo = emp.PRCo 
		AND Q.udTESTCo <> 'Y'
	--LEFT OUTER join VPIntegration.dbo.PRCM C on emp.Craft=C.Craft and emp.PRCo = C.PRCo
	--LEFT OUTER JOIN VPIntegration.dbo.PRCC empClass ON emp.PRCo=empClass.PRCo and emp.Class = empClass.Class
	
	--WHERE v.Vendor IS NOT NULL
where emp.ActiveYN = 'Y'
OR EXISTS
	(
	SELECT 
		apvm.* 
	FROM 
		Viewpoint.dbo.APHB aphb JOIN
		Viewpoint.dbo.APVM apvm ON
			aphb.VendorGroup=apvm.VendorGroup
		AND aphb.Vendor=apvm.Vendor
		AND apvm.udPRCo=emp.PRCo
		AND apvm.udEmployee=emp.Employee
		AND apvm.ActiveYN='Y'
	)
OR EXISTS
	(
	SELECT 
		apvm.* 
	FROM 
		Viewpoint.dbo.APTH apth JOIN
		Viewpoint.dbo.APVM apvm ON
			apth.VendorGroup=apvm.VendorGroup
		AND apth.Vendor=apvm.Vendor
		AND apvm.udPRCo=emp.PRCo
		AND apvm.udEmployee=emp.Employee
		AND apvm.ActiveYN='Y'
	)
			
go

GRANT SELECT ON vwVPEmployeeInfo TO PUBLIC
go

