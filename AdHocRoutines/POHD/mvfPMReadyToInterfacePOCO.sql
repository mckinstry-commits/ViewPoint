
/*
SELECT
	pmpoco.KeyID
,	pmpoco.POCo  AS POCo
,	pmpoco.PO AS POReqNumber
,	pohd.udMCKPONumber AS McKPONumber
,	pmpoco.POCONum
,	pmpoco.Description AS POCODesc
,	pohd.Vendor
,	apvm.Name AS VendorName
,	pohd.JCCo
,	pohd.Job
,	jcjm.Description AS JobName
,	pmpoco.Status
,	pmsc.Description AS StatusDesc
,	pmpoco.DateSent
,	pmpoco.DateApproved
,	pmpoco.ReadyBy
from
	HQCO hqco JOIN
	PMPOCO pmpoco on
		hqco.HQCo=pmpoco.POCo
	and hqco.udTESTCo <> 'Y' JOIN
	POHD pohd ON 
		pmpoco.POCo=pohd.POCo
	AND pmpoco.PO=pohd.PO JOIN
	APVM apvm ON
		pohd.VendorGroup=apvm.VendorGroup
	AND pohd.Vendor=apvm.Vendor JOIN
	JCJM jcjm ON
		pohd.JCCo=jcjm.JCCo
	AND pohd.Job=jcjm.Job JOIN
	PMSC pmsc ON
		pmpoco.Status=pmsc.Status
ORDER BY
	pmpoco.POCo  
,	pohd.udMCKPONumber
,	pmpoco.PO 
,	pmpoco.POCONum	


sp_depends PMPOCO


sp_helptext vfPMReadyToInterfacePOCO


*/

IF EXISTS ( SELECT * FROM sysobjects WHERE name='mvfPMReadyToInterfacePOCO' AND type ='TF')
BEGIN
	PRINT 'DROP FUNCTION mvfPMReadyToInterfacePOCO'
	DROP FUNCTION mvfPMReadyToInterfacePOCO
END
go

PRINT 'CREATE FUNCTION mvfPMReadyToInterfacePOCO'
go


CREATE FUNCTION dbo.mvfPMReadyToInterfacePOCO(@Form varchar(30) /*, @keyid bigint */)
RETURNS @readyToInterfaceItems TABLE 
(
    -- Columns returned by the function
	PMCo bCompany NOT NULL,
    Project bJob NOT NULL,
	JobStatus tinyint NOT NULL,
	ProjectMgr bigint, 
	Interface varchar(30) NOT NULL,
	ID varchar(30),
	CO int,
	ACO varchar(30),
	Item varchar(10),
	[Description] varchar (120),
	Amount decimal(18,2),
	InterfacedYN varchar(10) null,
	Form varchar(30),
	KeyID bigint
)
AS 

-- =============================================
-- Author:		AW vfPMReadyToInterfacePOCO
-- Modified: 		TFS 42706 added another level to drill down query

-- Create date: 1/31/2013
-- Description:	Returns the PM Records Ready To Interface PMMF Records POs POCOs MOs Quotes
--   Used in Work Center inquery to drill down to the related items for the given record
--
-- Forms Accepted / Query results returned
-- PMProjects -- All related form headers
-- PMACOS -- ACO Items / all related header records
-- PMPOHeader -- PO Items  / all related header records
-- PMPOCO -- POCO Items / all related header records
-- PMSLHeader -- SL Items / all related header records
-- PMSubcontractCO -- SubCo Items / all related header records
-- PMMOHeader -- MO Items / all related header records
-- PMMSQuote -- Quote Items / all related header records
--
-- 2014.11.20 - LWO - Altered
-- Removed @KeyID parameter to allow for the selection of all records, not just a specific one.
--
-- =============================================

BEGIN

	IF @Form = 'PMPOCO'
	BEGIN
		INSERT @readyToInterfaceItems(PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item, InterfacedYN, Amount, Form, KeyID)
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Purchase Order CO Item',a.MtlDescription,
			ID=a.PO, CO=a.POCONum, ACO=a.ACO, Item=a.POItem,
			CASE WHEN a.InterfaceDate is null THEN 'N' ELSE 'Y' END
			,Amount=isnull(a.Amount,0),
			Form='PMPOCO',o.KeyID
		FROM dbo.PMMF a 
			INNER JOIN dbo.PMCO c on a.PMCo=c.PMCo
			INNER JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			INNER JOIN dbo.PMPOCO o on o.POCo=a.POCo and o.PO=a.PO and o.POCONum = a.POCONum
		WHERE  a.PO IS NOT NULL AND a.POItem IS NOT NULL
				AND a.POCONum IS NOT NULL
				AND c.POInUse = 'Y'
				AND a.MaterialOption='P' 
				--AND o.KeyID = @keyid	
	END
	ELSE
	BEGIN
		INSERT @readyToInterfaceItems(PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item, InterfacedYN, Amount, Form, KeyID)
		--Project
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Purchase Order CO',o.[Description],
			ID=a.PO, CO=a.POCONum, ACO=max(a.ACO), Item=null,
			CASE WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is null) AND 
					  EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is not null) THEN 'Y' END
			,Amount=sum(IsNull(a.Amount,0)),
			Form='PMPOCO',o.KeyID
		FROM dbo.PMMF a 
			JOIN dbo.PMCO c on a.PMCo=c.PMCo
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.PMPOCO o on o.POCo=a.POCo and o.PO=a.PO and o.POCONum = a.POCONum
		WHERE a.PO IS NOT NULL AND a.POItem IS NOT NULL
				AND a.POCONum IS NOT NULL
				AND c.POInUse = 'Y'
				AND a.MaterialOption='P' 
				AND (@Form = 'PMProjects' /* AND j.KeyID = @keyid */)
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,o.[Description],a.POCo,a.PO,a.POCONum,o.KeyID
		UNION ALL
		--ACO
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Purchase Order CO',o.[Description],
			ID=a.PO, CO=a.POCONum, ACO=max(a.ACO), Item=null,
			CASE WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is null) AND 
					  EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is not null) THEN 'Y' END
			,Amount=sum(IsNull(a.Amount,0)),
			Form='PMPOCO',o.KeyID
		FROM dbo.PMMF a 
			JOIN dbo.PMCO c on a.PMCo=c.PMCo
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.PMPOCO o on o.POCo=a.POCo and o.PO=a.PO and o.POCONum = a.POCONum
			--ACOs
			JOIN dbo.PMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
		WHERE a.PO IS NOT NULL AND a.POItem IS NOT NULL
				AND a.POCONum IS NOT NULL
				AND c.POInUse = 'Y'
				AND a.MaterialOption='P' 
				AND (@Form = 'PMACOS' /* AND h.KeyID = @keyid */)
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,o.[Description],a.POCo,a.PO,a.POCONum,o.KeyID
		--PO MOs Quotes
		UNION ALL
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Purchase Order CO',o.[Description],
			ID=a.PO, CO=a.POCONum, ACO=max(a.ACO), Item=null,
			CASE WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is null) AND 
					  EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is not null) THEN 'Y' END
			,Amount=sum(IsNull(a.Amount,0)),
			Form='PMPOCO',o.KeyID
		FROM dbo.PMMF a 
			JOIN dbo.PMCO c on a.PMCo=c.PMCo
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.PMPOCO o on o.POCo=a.POCo and o.PO=a.PO and o.POCONum = a.POCONum
			--ACOs
			JOIN dbo.PMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
			--related POs MOs Quotes
			LEFT JOIN dbo.PMMF f on h.PMCo=f.PMCo and h.Project=f.Project and h.ACO=f.ACO
			--related POs
			LEFT JOIN dbo.POHD b on b.POCo=f.POCo and b.PO=f.PO
			--related MOs
			LEFT JOIN dbo.INMO m on m.INCo=a.INCo and m.MO=a.MO
			--related Quotes
			LEFT JOIN dbo.MSQH q on q.MSCo=a.MSCo and q.Quote=a.Quote
		WHERE a.PO IS NOT NULL AND a.POItem IS NOT NULL
				AND a.POCONum IS NOT NULL
				AND c.POInUse = 'Y'
				AND a.MaterialOption='P' 
				AND (
					(@Form='PMPOHeader' /* AND b.KeyID = @keyid */ AND f.PO is not null AND f.POItem is not NULL
						AND f.MaterialOption = 'P'
						AND f.POCONum IS NULL
						AND c.POInUse = 'Y') OR
					(@Form='PMMOHeader' /* AND m.KeyID = @keyid */ AND f.MO IS NOT NULL AND f.MOItem IS NOT NULL
						AND f.MaterialOption = 'M'
						AND c.INInUse = 'Y'	) OR
					(@Form='PMMSQuote' /* AND q.KeyID = @keyid */
						AND f.Quote IS NOT NULL AND f.Location IS NOT NULL
						AND f.MaterialOption='Q' 
						AND c.MSInUse = 'Y') 
				)
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,o.[Description],a.POCo,a.PO,a.POCONum,o.KeyID
		--SLs SubCOs
		UNION ALL
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Purchase Order CO',o.[Description],
			ID=a.PO, CO=a.POCONum, ACO=max(a.ACO), Item=null,
			CASE WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is null) AND 
					  EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO and POCONum is not null and InterfaceDate is not null) THEN 'Y' END
			,Amount=sum(IsNull(a.Amount,0)),
			Form='PMPOCO',o.KeyID
		FROM dbo.PMMF a 
			JOIN dbo.PMCO c on a.PMCo=c.PMCo
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.PMPOCO o on o.POCo=a.POCo and o.PO=a.PO and o.POCONum = a.POCONum
			--ACOs
			JOIN dbo.PMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
			--related Sls SubCOs
			JOIN dbo.PMSL l on l.PMCo=h.PMCo and l.Project = h.Project and l.ACO=h.ACO
			--related Sls
			LEFT JOIN dbo.SLHD s on s.SLCo=l.SLCo and s.SL=l.SL
			--related SubCos
			LEFT JOIN dbo.PMSubcontractCO u on u.SLCo=l.SLCo and u.SL=l.SL and u.SubCO = l.SubCO
		WHERE a.PO IS NOT NULL AND a.POItem IS NOT NULL
				AND a.POCONum IS NOT NULL
				AND c.POInUse = 'Y'
				AND a.MaterialOption='P' 
				AND (
					(@Form = 'PMSLHeader' /* and s.KeyID = @keyid */
						AND l.SL is not NULL AND l.SLItem is not NULL
						AND l.SubCO is NOT Null 
						AND c.SLInUse='Y') OR
					(@Form = 'PMSubcontractCO' /* and u.KeyID = @keyid */
						AND l.SL is not NULL AND l.SLItem is not NULL
						AND l.SubCO is NOT Null 
						AND c.SLInUse='Y')
				)
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,o.[Description],a.POCo,a.PO,a.POCONum,o.KeyID
	END
RETURN
END
go

IF EXISTS ( SELECT * FROM sysobjects WHERE name='mspPMReadyToInterfacePOCO' AND type ='P')
BEGIN
	PRINT 'DROP PROCEDURE mspPMReadyToInterfacePOCO'
	DROP PROCEDURE mspPMReadyToInterfacePOCO
END
go

PRINT 'CREATE PROCEDURE mspPMReadyToInterfacePOCO'
go

CREATE PROCEDURE mspPMReadyToInterfacePOCO
(
	@Form varchar(30)
)
as
SELECT 
	ui.PMCo  AS PMCo
,	pohd.PO AS POReqNumber
,	pohd.udMCKPONumber AS McKPONumber
,	ui.CO AS POCONum
,	ui.Description AS POCODesc
,	pohd.Vendor
,	apvm.Name AS VendorName
,	pohd.JCCo
,	pohd.Job
,	jcjm.Description AS JobName
,	pmpoco.Status
,	pmsc.Description AS StatusDesc
,	pmpoco.ReadyForAcctg
,	pmpoco.DateSent
,	pmpoco.DateApproved
,	pmpoco.ReadyBy
,	jcmp.Name AS ProjectManager
--,	ui.* 
,	ui.ACO
,	ui.Item
,	ui.Amount
,	ui.InterfacedYN
,	ui.Form
,	ui.Interface
,	ui.KeyID
FROM  
	HQCO hqco JOIN
	mvfPMReadyToInterfacePOCO(@Form) ui ON 
		hqco.HQCo=ui.PMCo
	and hqco.udTESTCo <> 'Y' JOIN
	PMPOCO pmpoco ON
		pmpoco.PMCo=ui.PMCo
	AND pmpoco.KeyID=ui.KeyID join
	POHD pohd ON 
		pmpoco.POCo=pohd.POCo
	AND pmpoco.PO=pohd.PO JOIN
	APVM apvm ON
		pohd.VendorGroup=apvm.VendorGroup
	AND pohd.Vendor=apvm.Vendor JOIN
	JCJM jcjm ON
		pohd.JCCo=jcjm.JCCo
	AND pohd.Job=jcjm.Job JOIN
	PMSC pmsc ON
		pmpoco.Status=pmsc.Status JOIN
	JCMP jcmp ON
		jcmp.JCCo=ui.PMCo
	AND jcmp.ProjectMgr=ui.ProjectMgr
ORDER BY
	ui.PMCo 
,	pohd.udMCKPONumber
,	pohd.PO
,	ui.CO 
go


mspPMReadyToInterfacePOCO @Form='PMProjects'

--mspPMReadyToInterfacePOCO @Form='PMProjects'			-- POCO Items / all related header records
--mspPMReadyToInterfacePOCO @Form='PMPOCO'				-- POCO Items / all related header records
--mspPMReadyToInterfacePOCO @Form='PMACOS'				-- ACO Items / all related header records
--mspPMReadyToInterfacePOCO @Form='PMPOHeader'			-- PO Items  / all related header records
--mspPMReadyToInterfacePOCO @Form='PMSLHeader'			-- SL Items / all related header records
--mspPMReadyToInterfacePOCO @Form='PMSubcontractCO'		-- SubCo Items / all related header records
--mspPMReadyToInterfacePOCO @Form='PMMOHeader'			-- MO Items / all related header records
--mspPMReadyToInterfacePOCO @Form='PMMSQuote'			-- Quote Items / all related header records