SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		AW vfPMReadyToInterface
-- Modified: 

-- Create date: 1/31/2013
-- Description:	Returns the PM Records Ready To Interface
--   Used in for Both Work Center inquery and vspPMInterfaceListFillSummary PMInterface form
--     Returns items ready to interface if @ReadyToSendYN = 'Y' or items not ready if @ReadyToSendYN = 'N'
--
--  Interfacetypes:
--   1 - All items
--   2 - Approved Change Order
--   3 - Purchase Order - Original
--   4 - Purchase Order CO
--   5 - Subcontract - Original
--   6 - Subcontract CO
--   7 - Material Order
--   8 - Quote
-- =============================================
CREATE FUNCTION dbo.vfPMReadyToInterface(@PMCo bCompany, @Project bProject, @Interfacetype int = 1, @ReadyToSendYN bYN = 'Y')
RETURNS @readyToInterface TABLE 
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
	[Description] varchar (120),
	Amount decimal(16,2),
	Form varchar(30),
	KeyID bigint
)
AS 
-- Returns the first name, last name, job title, and contact type for the specified contact.
BEGIN
-- Source vspPMInterfaceListFillSummary
WITH ctePMSL_ACODesc (PMCo, Project, SLCo, SL, SubCO, ACODesc) AS
	(
		SELECT PMCo, Project, SLCo, SL, SubCO, CASE WHEN (COUNT(*) > 1) THEN MAX('Multiple') ELSE MAX(ACO) END as ACODesc 
			FROM (
			    SELECT DISTINCT PMCo, Project, SLCo, SL, SubCO, ACO 
				FROM dbo.PMSL 
				WHERE SL IS NOT NULL AND SLItem IS NOT NULL AND SubCO IS NOT Null 
					AND InterfaceDate IS NULL
					AND SendFlag = isnull(@ReadyToSendYN,'N')  
				GROUP BY PMCo, Project, SLCo, SL, SubCO, ACO 
				) g
		GROUP BY PMCo, Project, SLCo, SL, SubCO
	),
	ctePMMF_ACODesc (PMCo, Project, POCo, PO, POCONum, ACODesc) AS
	(
		SELECT PMCo, Project, POCo, PO, POCONum, CASE WHEN (COUNT(*) > 1) THEN MAX('Multiple') ELSE MAX(ACO) END as ACODesc 
			FROM (
			    SELECT DISTINCT PMCo, Project, POCo, PO, POCONum, ACO 
				FROM dbo.PMMF 
				WHERE PO IS NOT NULL AND POItem IS NOT NULL AND POCONum IS NOT NULL
					AND InterfaceDate IS NULL 
					AND SendFlag = isnull(@ReadyToSendYN,'N') 
					AND MaterialOption='P'
				GROUP BY PMCo, Project, POCo, PO, POCONum, ACO 
				) g
		GROUP BY PMCo, Project, POCo, PO, POCONum
	) 
INSERT @readyToInterface(PMCo,JobStatus,ProjectMgr,Project,Interface,Description,ID,CO,ACO,Amount,Form,KeyID)
-- Pending Projects that can be interfaced - if pending must be sent first
SELECT j.JCCo,j.JobStatus,j.ProjectMgr,Project=j.Job,Interface='Project Pending', Description='Contract and Original Estimates',ID=null, CO=null, ACO=null,Amount=null,
	Form='PMProjects',KeyID=j.KeyID
FROM dbo.JCJM j
WHERE j.JCCo=isnull(@PMCo,j.JCCo) and j.Job = isnull(@Project,j.Job) and j.JobStatus = 0 
AND ISNULL(@ReadyToSendYN,'N') = 'Y'

UNION ALL

-- List Project updates or additions to open projects
SELECT j.JCCo,j.JobStatus,j.ProjectMgr,Project=j.Job,'Project Update', 'Contract and Cost Estimate updates',ID=null, CO=null, ACO=null, Amount=null,
  Form='PMProjects',KeyID=j.KeyID
From dbo.JCJM j 
	INNER JOIN dbo.JCCO c on c.JCCo=j.JCCo
WHERE j.JCCo=isnull(@PMCo,j.JCCo) AND j.Job = isnull(@Project,j.Job)
	AND EXISTS(SELECT 1 FROM dbo.JCCH WHERE JCCo=isnull(@PMCo,j.JCCo) AND Job=isnull(@Project,j.Job) AND SourceStatus = 'Y')
	AND (j.JobStatus = 1
	 OR (j.JobStatus = 2 AND c.PostSoftClosedJobs = 'Y')
	 OR (j.JobStatus = 3 AND c.PostClosedJobs = 'Y'))
	AND ISNULL(@ReadyToSendYN,'N') = 'Y'
GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,j.Job,j.KeyID

UNION ALL

-- Approved change orders
SELECT j.JCCo,j.JobStatus,j.ProjectMgr,Project=h.Project,'Approved Change Order', h.[Description], ID=h.ACO, CO=null ,ACO=null, Amount=ISNULL(t.ACORevTotal,0),
  Form='PMACOS',h.KeyID
FROM dbo.PMOH h
	INNER JOIN dbo.PMOHTotals t ON t.PMCo = h.PMCo AND t.Project = h.Project AND t.ACO = h.ACO
	INNER JOIN dbo.JCJM j on h.PMCo=j.JCCo and h.Project = j.Job
WHERE h.PMCo=isnull(@PMCo,h.PMCo) AND h.Project = isnull(@Project,h.Project) and @Interfacetype in (1,2)
	AND h.ACO is not null 
	AND ( 
		(@ReadyToSendYN = 'Y' AND h.ReadyForAcctg = 'Y') OR
		(@ReadyToSendYN = 'N' AND h.ReadyForAcctg = 'N' AND EXISTS(SELECT 1 FROM PMOI WHERE PMCo=h.PMCo and Project=h.Project and ACO=h.ACO and Approved='N'))
	    )
GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,h.Project,h.ACO, h.[Description], t.ACORevTotal,h.KeyID

UNION ALL

-- Purchase Orders Originals
SELECT j.JCCo,j.JobStatus,j.ProjectMgr,Project=a.Project,'Purchase Order - Original',b.[Description],ID=a.PO, CO=null, ACO=null, sum(IsNull(a.Amount,0)),
	Form='PMPOHeader',b.KeyID
FROM dbo.PMMF a 
	INNER JOIN dbo.PMCO c on a.PMCo=c.PMCo
	INNER JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
	INNER JOIN dbo.POHD b on b.POCo=a.POCo and b.PO=a.PO
WHERE a.PMCo=isnull(@PMCo,a.PMCo) and a.Project = isnull(@Project,a.Project) and @Interfacetype in (1,3)
			AND a.PO is not null AND a.POItem is not NULL
			AND a.MaterialOption = 'P'
			AND a.InterfaceDate is NULL
			AND a.POCONum IS NULL
			AND c.POInUse = 'Y'
			AND (a.RecordType = 'O' OR (a.RecordType = 'C' AND b.[Status] = 3))
			--when @ReadyToSendYN = 'Y' then POHD.Approved, PMMF.SendFlag = 'Y' else not ready
			AND ( (isnull(@ReadyToSendYN,'N') = 'Y' AND ISNULL(b.Approved, 'Y') = 'Y' AND a.SendFlag = 'Y')
				OR
				(isnull(@ReadyToSendYN,'N') = 'N' AND (ISNULL(b.Approved, 'Y') = 'N' OR a.SendFlag = 'N'))
			)
GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,a.PO, b.[Description],b.KeyID

UNION ALL

-- Purchase Order Change Orders
SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Purchase Order CO',o.[Description],ID=a.PO, CO=a.POCONum, ACO=ad.ACODesc, 
	Amount=sum(IsNull(a.Amount,0)),
	Form='PMPOCO',o.KeyID
FROM dbo.PMMF a 
	INNER JOIN ctePMMF_ACODesc ad on ad.PMCo=a.PMCo and ad.Project=a.Project and ad.POCo=a.POCo and ad.PO=a.PO and ad.POCONum = a.POCONum
	INNER JOIN dbo.PMCO c on a.PMCo=c.PMCo
	INNER JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
	INNER JOIN dbo.POHD b on b.POCo=a.POCo and b.PO=a.PO
	INNER JOIN dbo.PMPOCO o on o.POCo=a.POCo and o.PO=a.PO and o.POCONum = a.POCONum
WHERE a.PMCo=isnull(@PMCo,a.PMCo) and a.Project = isnull(@Project,a.Project) and @Interfacetype in (1,4)
	AND a.PO is not NULL AND a.POItem is not NULL
	AND a.POCONum IS NOT NULL
	AND c.POInUse = 'Y'
	AND a.MaterialOption='P'
	AND a.InterfaceDate is NULL
	--when @ReadyToSendYN = 'Y' then PMPOCO.ReadyForAcctg, POHD.Approved, PMMF.SendFlag = 'Y' else not ready
	AND ( (isnull(@ReadyToSendYN,'N') = 'Y' AND o.ReadyForAcctg = 'Y' AND ISNULL(b.Approved, 'Y') = 'Y' AND a.SendFlag = 'Y')
			OR
		(isnull(@ReadyToSendYN,'N') = 'N' AND (o.ReadyForAcctg = 'N' OR ISNULL(b.Approved, 'Y') = 'N' AND a.SendFlag = 'N'))
	)
GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,a.PO, o.POCONum, o.[Description], a.POCONum, ad.ACODesc,o.KeyID

UNION ALL

-- Subcontract Original
SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Subcontract - Original',s.[Description],ID=a.SL,CO=null,ACO=null, Amount = sum(IsNull(a.Amount,0)),
	Form='PMSLHeader',s.KeyID
FROM dbo.PMSL a with (nolock) 
	INNER JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
	INNER JOIN dbo.PMCO c on c.PMCo=a.PMCo and c.APCo=a.SLCo
	INNER JOIN dbo.SLHD s on s.SLCo=a.SLCo and s.SL=a.SL
WHERE a.PMCo=isnull(@PMCo,a.PMCo) and a.Project = isnull(@Project,a.Project) and @Interfacetype IN (1,5)
	AND a.SL is not NULL AND a.SLItem is not NULL
	AND c.SLInUse = 'Y'
	AND a.SubCO IS NULL
	AND a.InterfaceDate IS NULL
	AND (a.RecordType = 'O' OR (a.RecordType = 'C' AND s.[Status] = 3))
	--when @ReadyToSendYN = 'Y' then PMSL.SendFlag and SLHD.Approved = 'Y' else not ready
	AND (
		(isnull(@ReadyToSendYN,'N') = 'Y' AND ISNULL(s.Approved,'Y') = 'Y' AND a.SendFlag = 'Y')
		OR
		(isnull(@ReadyToSendYN,'N') = 'N' AND (ISNULL(s.Approved,'Y') = 'N' OR a.SendFlag = 'N'))
	)
GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project, a.SL, s.[Description], s.KeyID

UNION ALL

-- Subcontract Change Orders
SELECT j.JCCo,j.JobStatus,j.ProjectMgr,o.Project,'Subcontract CO',s.[Description],ID=a.SL,CO=a.SubCO, ACO=ad.ACODesc, Amount = sum(IsNull(a.Amount,0)),
	Form='PMSubcontractCO',KeyID=o.KeyID
FROM dbo.PMSL a 
	INNER JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
	INNER JOIN ctePMSL_ACODesc ad on ad.PMCo=a.PMCo and ad.Project=a.Project and ad.SLCo=a.SLCo and ad.SL=a.SL and ad.SubCO = a.SubCO
	INNER join dbo.PMCO c on c.PMCo=a.PMCo and c.APCo=a.SLCo
	INNER JOIN dbo.SLHD s on s.SLCo=a.SLCo and s.SL=a.SL
	INNER JOIN dbo.PMSubcontractCO o on o.SLCo=a.SLCo and o.SL=a.SL and o.SubCO = a.SubCO
WHERE a.PMCo=isnull(@PMCo,a.PMCo) AND a.Project = isnull(@Project,a.Project) and @Interfacetype IN (1,6)
	AND a.SL is not NULL AND a.SLItem is not NULL
	AND a.SubCO is NOT Null 
	AND a.InterfaceDate is null 
	AND c.SLInUse='Y'
	--when @ReadyToSendYN = Y then PMSL.SendFlag and PMSubcontractCO.ReadyForAcctg and SLHD.Approved = 'Y' else not ready
	AND ( 
		(isnull(@ReadyToSendYN,'N') = 'Y' AND ISNULL(s.Approved,'Y') = 'Y' AND o.ReadyForAcctg = 'Y' AND a.SendFlag = 'Y')
		OR
		(isnull(@ReadyToSendYN,'N') = 'N' AND (ISNULL(s.Approved,'Y') = 'N' OR o.ReadyForAcctg = 'N' OR a.SendFlag = 'N') )
	)
GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,o.Project,a.SL, s.[Description], a.SubCO, ad.ACODesc,o.KeyID

UNION ALL

-- Material Orders
SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Material Order', b.[Description],ID=a.MO, CO=null,ACO=null,Amount=sum(IsNull(a.Amount,0)),
	Form='PMMOHeader',KeyID=b.KeyID
FROM dbo.PMMF a
	INNER JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
	INNER JOIN dbo.PMCO c ON c.PMCo=a.PMCo
	INNER JOIN dbo.INMO b on b.INCo=a.INCo and b.MO=a.MO
WHERE a.PMCo=isnull(@PMCo,a.PMCo) and a.Project = isnull(@Project,a.Project) and @Interfacetype IN (1,7)
	AND a.MO IS NOT NULL AND a.MOItem IS NOT NULL
	AND a.MaterialOption = 'M'
	AND a.InterfaceDate IS NULL
	AND c.INInUse = 'Y'
	-- when @ReadyToSendYN = 'Y' then both PMMF SendFlag and INMO Approved have to be 'Y' else Not Ready
	AND ( 
		(isnull(@ReadyToSendYN,'N') = 'Y' AND  a.SendFlag = 'Y' AND ISNULL(b.Approved,'Y') = 'Y')
		OR 
		(isnull(@ReadyToSendYN,'N') = 'N' AND  (a.SendFlag = 'N' OR ISNULL(b.Approved,'Y') = 'N') ) 
	)
GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,a.INCo, a.MO, b.[Description],b.KeyID

UNION ALL

-- Material Quotes 
SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Quote', b.[Description],ID=a.Quote,CO=null,ACO=null, Amount=sum(IsNull(a.Amount,0)),
	Form='PMMSQuote',KeyID=b.KeyID
FROM dbo.PMMF a
	INNER JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
	INNER JOIN dbo.PMCO c ON c.PMCo=a.PMCo
	INNER JOIN dbo.MSQH b on b.MSCo=a.MSCo and b.Quote=a.Quote
WHERE a.PMCo=isnull(@PMCo,a.PMCo) and a.Project = isnull(@Project,a.Project) and @Interfacetype IN (1,8)
	AND a.Quote is not null AND a.Location is not NULL
	AND a.MaterialOption='Q' 
	AND c.MSInUse = 'Y'
	AND a.InterfaceDate is NULL
	AND a.SendFlag = isnull(@ReadyToSendYN,'N')
GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,a.Quote, b.[Description],b.KeyID

RETURN
END
GO
GRANT SELECT ON  [dbo].[vfPMReadyToInterface] TO [public]
GO
