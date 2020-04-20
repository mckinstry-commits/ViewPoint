SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		AW [vfPMReadyToInterfaceItemDetails]
-- Modified: 

-- Create date: 4/11/2013
-- Description:	Returns the PM Records Ready To Interface Item Details
--  Form 
--		PMProjects - returns same set as vfPMReadyToInterface
--		PMACOS - returns ACO Items
--		PMPOHeader - returns PO Items
--		PMPOCO - returns POCO Items
--		PMSLHeader - returns SL Items
--		PMSubcontractCO - returns SubCo Items
--		PMMOHeader - returns MO Items
--		PMMSQuote -	returns Quote Items
--
--
-- =============================================
CREATE FUNCTION dbo.vfPMReadyToInterfaceItemDetails(@Form varchar(30), @keyid bigint)
RETURNS @readyToInterfaceItemDetails TABLE 
(
    -- Columns returned by the function
	PMCo bCompany NOT NULL,
    Project bJob NOT NULL,
	JobStatus tinyint NOT NULL,
	ProjectMgr bigint,  
	Interface varchar(30) NOT NULL,
	ACO varchar(30),
	CO int,
	ID varchar(30), 
	Item varchar(10),
	[Description] varchar (120),
	UM bUM null,
	Units bUnits null,
	Amount decimal(18,2),
	InterfacedYN bYN null,
	Form varchar(30),
	KeyID bigint
)
AS 

BEGIN

-- PM Project record
INSERT @readyToInterfaceItemDetails(PMCo,Project,JobStatus,ProjectMgr,
	Interface, Description, ID, CO, ACO, Item,
	UM, Units, InterfacedYN,Amount, 
	Form, KeyID)
SELECT j.JCCo,j.Job,j.JobStatus,j.ProjectMgr,
	Interface='Project', j.Description,ID=j.Job, CO=null, ACO=null, Item=null,
	UM=null, Units=null, 
	CASE WHEN EXISTS(SELECT 1 FROM dbo.JCCH WHERE JCCo=j.JCCo AND Job=j.Job AND SourceStatus = 'Y'
								AND ( (j.JobStatus = 1)
								 OR (j.JobStatus = 2 AND c.PostSoftClosedJobs = 'Y')
								 OR (j.JobStatus = 3 AND c.PostClosedJobs = 'Y'))) OR j.JobStatus = 0 THEN 'N' ELSE 'Y' END
	,Amount=null,
	Form='PMProjects',KeyID=j.KeyID
FROM dbo.JCJM j
JOIN dbo.JCCO c on c.JCCo=j.JCCo
WHERE @Form='PMProjects' AND j.KeyID=@keyid

-- ACOs
UNION ALL

SELECT  j.JCCo,j.Job,j.JobStatus,j.ProjectMgr,
	'Approved Change Order Item', i.[Description], ID=h.ACO, CO=null , ACO=null, Item=i.ACOItem, 
	i.UM, i. Units, 
	CASE WHEN i.InterfacedDate IS NULL THEN 'N' ELSE 'Y' END
	,Amount=ISNULL(i.ApprovedAmt,0),
	Form='PMACOS',h.KeyID
FROM dbo.PMOH h
	INNER JOIN dbo.PMOI i ON i.PMCo = h.PMCo AND i.Project = h.Project AND i.ACO = h.ACO
	INNER JOIN dbo.JCJM j on h.PMCo=j.JCCo and h.Project = j.Job
WHERE @Form='PMACOS' AND h.ACO IS NOT NULL 
		AND h.KeyID = @keyid

UNION ALL

-- PO/POCO/MO/Quote items
SELECT DISTINCT j.JCCo,j.Job,j.JobStatus,j.ProjectMgr,
	CASE a.MaterialOption
		WHEN 'Q' THEN 'MS Quote Item' 
		WHEN 'M' THEN 'Material Order Item' 
		WHEN 'P' THEN 'Purchase Order' + CASE WHEN a.POCONum IS NOT NULL THEN ' CO' ELSE '' END + ' Item' 
		ELSE '' END AS Interface,
	a.[MtlDescription], 
	CASE a.MaterialOption
		WHEN 'Q' THEN a.Quote
		WHEN 'M' THEN a.MO 
		when 'P' THEN a.PO
		ELSE null END AS ID, a.POCONum AS CO,a.ACO,
	CAST(
		CASE a.MaterialOption
			WHEN 'M' THEN a.MOItem 
			WHEN 'P' THEN a.POItem
			ELSE null END as varchar(10)) AS Item, 
	 a.UM, a.Units, 
	 CASE WHEN a.InterfaceDate IS NULL THEN 'N' ELSE 'Y' END
	 ,a.Amount,
	Form=@Form,
	CASE @Form 
			WHEN 'PMPOHeader' THEN b.KeyID
			WHEN 'PMPOCO' THEN o.KeyID
			WHEN 'PMMOHeader' THEN i.KeyID
			WHEN 'PMMSQuote' THEN q.KeyID
			ELSE null END as KeyID
FROM dbo.PMMF a
	INNER JOIN dbo.PMCO c on a.PMCo=c.PMCo
	JOIN dbo.JCJM j on j.JCCo=a.PMCo and j.Job=a.Project
	--related POs
	LEFT JOIN dbo.POHD b on b.POCo=a.POCo and b.PO=a.PO
	--related POCOs
	LEFT JOIN dbo.PMPOCO o on o.POCo=a.POCo and o.PO=a.PO and o.POCONum = a.POCONum
	--related MOs
	LEFT JOIN dbo.INMO i on i.INCo=a.INCo and i.MO=a.MO
	--related Quotes
	LEFT JOIN dbo.MSQH q on q.MSCo=a.MSCo and q.Quote=a.Quote
WHERE (@Form = 'PMPOHeader' AND a.PO IS NOT NULL AND a.POItem IS NOT NULL
			AND a.MaterialOption = 'P'
			AND a.POCONum IS NULL
			AND c.POInUse = 'Y'
			AND (a.RecordType = 'O' OR (a.RecordType = 'C' AND b.[Status] = 3))
			AND b.KeyID = @keyid
	   ) OR
	   (@Form = 'PMPOCO' AND a.PO IS NOT NULL AND a.POItem IS NOT NULL
			AND a.POCONum IS NOT NULL
			AND c.POInUse = 'Y'
			AND a.MaterialOption='P'
			AND o.KeyID = @keyid
	   ) OR
	   (@Form = 'PMMOHeader' AND a.MO IS NOT NULL AND a.MOItem IS NOT NULL
			AND a.MaterialOption = 'M'
			AND c.INInUse = 'Y'
			AND i.KeyID = @keyid
	   ) OR
	   (@Form = 'PMMSQuote' AND a.Quote IS NOT NULL AND a.Location IS NOT NULL
			AND a.MaterialOption='Q' 
			AND c.MSInUse = 'Y'
			AND q.KeyID = @keyid
	   )

UNION ALL

-- SL & SubCO items
SELECT j.JCCo,j.Job,j.JobStatus,j.ProjectMgr,
'Subcontract' +case when l.SubCO is not null then ' CO' else '' end + ' Item',
l.SLItemDescription, 
ID=l.SL,l.SubCO,l.ACO, 
Item=cast(l.SL as varchar(10)), 
	l.UM, l.Units,
	 CASE WHEN l.InterfaceDate IS NULL THEN 'N' ELSE 'Y' END
	,Amount=ISNULL(l.Amount, 0),
	Form=@Form,@keyid
FROM dbo.PMSL l 
	JOIN dbo.JCJM j on j.JCCo=l.PMCo and j.Job=l.Project
	INNER JOIN dbo.PMCO c on c.PMCo=l.PMCo and c.APCo=l.SLCo
	--related SLs
	LEFT JOIN dbo.SLHD s on s.SLCo=l.SLCo and s.SL=l.SL
	--related SubCOs
	LEFT JOIN dbo.PMSubcontractCO o on o.SLCo=l.SLCo and o.SL=l.SL and o.SubCO = l.SubCO
WHERE (@Form = 'PMSLHeader' AND l.SL IS NOT NULL AND l.SLItem IS NOT NULL
		AND c.SLInUse = 'Y'
		AND l.SubCO IS NULL
		AND (l.RecordType = 'O' OR (l.RecordType = 'C' AND s.[Status] = 3)) 
		AND s.KeyID = @keyid
	) OR 
	(@Form = 'PMSubcontractCO' AND  l.SL IS NOT NULL AND l.SLItem IS NOT NULL
		AND l.SubCO IS NOT NULL 
		AND c.SLInUse='Y'
		AND o.KeyID = @keyid
	)

RETURN
END
GO
GRANT SELECT ON  [dbo].[vfPMReadyToInterfaceItemDetails] TO [public]
GO
