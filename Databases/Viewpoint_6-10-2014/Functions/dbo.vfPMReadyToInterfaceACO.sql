SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		AW vfPMReadyToInterfaceACO
-- Modified: 		TFS 42706 added another level to drill down query

-- Create date: 1/31/2013
-- Description:	Returns the PM Records Ready To Interface ACO Records
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
--
-- =============================================
CREATE FUNCTION dbo.vfPMReadyToInterfaceACO(@Form varchar(30), @keyid bigint)
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
	InterfacedYN varchar(10) NULL,
	Amount decimal(18,2),
	Form varchar(30),
	KeyID bigint
)
AS 

BEGIN

	INSERT @readyToInterfaceItems(PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item, InterfacedYN, Amount, Form, KeyID)
	--ACO Items
	SELECT j.JCCo,j.JobStatus,j.ProjectMgr,h.Project,'Approved Change Order Item', i.[Description], 
		ID=h.ACO, CO=null , ACO=null, Item=i.ACOItem,
		CASE WHEN i.InterfacedDate IS NULL THEN 'N' ELSE 'Y' END
		,Amount=ISNULL(i.ApprovedAmt,0),
		Form='PMACOS',h.KeyID
	FROM dbo.PMOH h
		JOIN dbo.PMOI i ON i.PMCo = h.PMCo AND i.Project = h.Project AND i.ACO = h.ACO
		JOIN dbo.JCJM j on h.PMCo=j.JCCo and h.Project = j.Job
	WHERE @Form = 'PMACOS' AND h.ACO IS NOT NULL 
			AND h.KeyID = @keyid
	UNION ALL
	--Project
	SELECT j.JCCo,j.JobStatus,j.ProjectMgr,h.Project,'Approved Change Order', h.[Description], 
			ID=i.ACO, CO=null , ACO=null, Item=null, 
			CASE WHEN EXISTS(select 1 from PMOI where PMCo=i.PMCo and Project=i.Project and ACO=i.ACO and InterfacedDate is null) AND
				EXISTS(select 1 from PMOI where PMCo=i.PMCo and Project=i.Project and ACO=i.ACO and InterfacedDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMOI where PMCo=i.PMCo and Project=i.Project and ACO=i.ACO and InterfacedDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMOI where PMCo=i.PMCo and Project=i.Project and ACO=i.ACO and InterfacedDate is not null) THEN 'Y' END
			,Amount=sum(ISNULL(i.ApprovedAmt,0)),
			Form='PMACOS',h.KeyID
	FROM dbo.PMOH h
		JOIN dbo.PMOI i ON i.PMCo = h.PMCo AND i.Project = h.Project AND i.ACO = h.ACO
		JOIN dbo.JCJM j on h.PMCo=j.JCCo and h.Project = j.Job
	WHERE @Form='PMProjects' AND j.KeyID = @keyid
	GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,h.Project, h.[Description], i.PMCo,i.Project,i.ACO,h.KeyID,h.ReadyForAcctg
	UNION ALL
	-- POs POCOs MOs Quotes
	SELECT j.JCCo,j.JobStatus,j.ProjectMgr,h.Project,'Approved Change Order', h.[Description], 
			ID=i.ACO, CO=null , ACO=null, Item=null, 
			CASE WHEN EXISTS(select 1 from PMOI where PMCo=i.PMCo and Project=i.Project and ACO=i.ACO and InterfacedDate is null) AND
				EXISTS(select 1 from PMOI where PMCo=i.PMCo and Project=i.Project and ACO=i.ACO and InterfacedDate is not null) THEN 'Partial'
			WHEN EXISTS(select 1 from PMOI where PMCo=i.PMCo and Project=i.Project and ACO=i.ACO and InterfacedDate is null) THEN 'N'
			WHEN EXISTS(select 1 from PMOI where PMCo=i.PMCo and Project=i.Project and ACO=i.ACO and InterfacedDate is not null) THEN 'Y' END 
			,Amount=sum(ISNULL(i.ApprovedAmt,0)),
			Form='PMACOS',h.KeyID
	FROM dbo.PMOH h
		JOIN dbo.PMOI i ON i.PMCo = h.PMCo AND i.Project = h.Project AND i.ACO = h.ACO
		JOIN dbo.JCJM j on h.PMCo=j.JCCo and h.Project = j.Job
		JOIN dbo.PMCO c on c.PMCo=j.JCCo
		--related POs MOs Quotes POCOs
		JOIN dbo.PMMF a on a.PMCo=h.PMCo and a.Project = h.Project and a.ACO = h.ACO
		--related POs
		LEFT JOIN dbo.POHD b on b.POCo=a.POCo and b.PO=a.PO
		--related MOs
		LEFT JOIN dbo.INMO m on m.INCo=a.INCo and m.MO=a.MO
		--related POCOs
		LEFT JOIN dbo.PMPOCO o on o.POCo=a.POCo and o.PO=a.PO and o.POCONum = a.POCONum
		--related Quotes
		LEFT JOIN dbo.MSQH q on q.MSCo=a.MSCo and q.Quote=a.Quote
	WHERE (@Form = 'PMPOHeader' AND a.PO IS NOT NULL AND a.POItem IS NOT NULL
			AND a.MaterialOption = 'P'
			AND a.POCONum IS NULL
			AND c.POInUse = 'Y'
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
	GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,h.Project, h.[Description], i.PMCo,i.Project,i.ACO,h.KeyID,h.ReadyForAcctg
	UNION ALL
	--SLs & SubCOs
	SELECT j.JCCo,j.JobStatus,j.ProjectMgr,h.Project,'Approved Change Order', h.[Description], 
			ID=i.ACO, CO=null , ACO=null, Item=null,
			CASE WHEN EXISTS(select 1 from PMOI where PMCo=i.PMCo and Project=i.Project and ACO=i.ACO and InterfacedDate is null) AND
				EXISTS(select 1 from PMOI where PMCo=i.PMCo and Project=i.Project and ACO=i.ACO and InterfacedDate is not null) THEN 'Partial'
			WHEN EXISTS(select 1 from PMOI where PMCo=i.PMCo and Project=i.Project and ACO=i.ACO and InterfacedDate is null) THEN 'N'
			WHEN EXISTS(select 1 from PMOI where PMCo=i.PMCo and Project=i.Project and ACO=i.ACO and InterfacedDate is not null) THEN 'Y' END  
			,Amount=sum(ISNULL(i.ApprovedAmt,0)),
			Form='PMACOS',h.KeyID
	FROM dbo.PMOH h
		JOIN dbo.PMOI i ON i.PMCo = h.PMCo AND i.Project = h.Project AND i.ACO = h.ACO
		JOIN dbo.JCJM j on h.PMCo=j.JCCo and h.Project = j.Job
		JOIN dbo.PMCO c on c.PMCo=j.JCCo
		-- related SLs & SubCOs
		JOIN dbo.PMSL l on l.PMCo=h.PMCo and l.Project = h.Project and l.ACO=h.ACO
		-- from PMSLHeader
		LEFT JOIN dbo.SLHD s on s.SLCo=l.SLCo and s.SL=l.SL
		-- from PMSubcontractCO
		LEFT JOIN dbo.PMSubcontractCO o on o.SLCo=l.SLCo and o.SL=l.SL and o.SubCO = l.SubCO
	WHERE (@Form = 'PMSLHeader' AND l.SL IS NOT NULL AND l.SLItem IS NOT NULL
			AND c.SLInUse = 'Y'
			AND l.SubCO IS NULL
			AND s.KeyID = @keyid
		) OR 
		(@Form = 'PMSubcontractCO' AND  l.SL IS NOT NULL AND l.SLItem IS NOT NULL
			AND l.SubCO IS NOT NULL 
			AND c.SLInUse='Y'
			AND o.KeyID = @keyid
		)
	GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,h.Project, h.[Description], i.PMCo,i.Project,i.ACO,h.KeyID,h.ReadyForAcctg

RETURN
END
GO
GRANT SELECT ON  [dbo].[vfPMReadyToInterfaceACO] TO [public]
GO
