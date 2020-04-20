SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		AW vfPMReadyToInterfaceSL
-- Modified: 		TFS 42706 added another level to drill down query

-- Create date: 1/31/2013
-- Description:	Returns the PM Records Ready To Interface PMSL Records SLs SubCOs
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
CREATE FUNCTION dbo.vfPMReadyToInterfaceSL(@Form varchar(30), @keyid bigint)
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

BEGIN

	IF @Form = 'PMSLHeader'
	BEGIN
		INSERT @readyToInterfaceItems(PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item, InterfacedYN, Amount, Form, KeyID)
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Subcontract Item',a.SLItemDescription,
			ID=a.SL,CO=null,ACO=a.ACO, Item=a.SLItem, 
			CASE WHEN a.InterfaceDate IS NULL THEN 'N' ELSE 'Y' END
			,Amount = IsNull(a.Amount,0),
			Form='PMSLHeader',s.KeyID
		FROM dbo.PMSL a with (nolock) 
			JOIN dbo.PMCO c on a.PMCo=c.PMCo
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.SLHD s on s.SLCo=a.SLCo and s.SL=a.SL
		WHERE a.SL IS NOT NULL AND a.SLItem IS NOT NULL
				AND c.SLInUse = 'Y'
				AND a.SubCO IS NULL
				AND s.KeyID = @keyid
	END
	ELSE
	BEGIN
		INSERT @readyToInterfaceItems(PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item, InterfacedYN, Amount, Form, KeyID)
		--Project
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Subcontract - Original',s.[Description],
				ID=a.SL,CO=null,ACO=max(a.ACO), Item=null, 
				CASE WHEN EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is null) AND 
					  EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is not null) THEN 'Y' END
				,Amount = sum(IsNull(a.Amount,0)),
				Form='PMSLHeader',s.KeyID
		FROM dbo.PMSL a with (nolock) 
			JOIN dbo.PMCO c on a.PMCo=c.PMCo
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.SLHD s on s.SLCo=a.SLCo and s.SL=a.SL
		WHERE a.SL IS NOT NULL AND a.SLItem IS NOT NULL
			AND c.SLInUse = 'Y'
			AND a.SubCO IS NULL
			AND @Form = 'PMProjects' and j.KeyID = @keyid
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project, a.PMCo, a.SL, s.[Description], s.KeyID
		UNION ALL
		-- ACOs
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Subcontract - Original',s.[Description],
				ID=a.SL,CO=null,ACO=max(a.ACO), Item=null, 
				CASE WHEN EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is null) AND 
					  EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is not null) THEN 'Y' END
				,Amount = sum(IsNull(a.Amount,0)),
				Form='PMSLHeader',s.KeyID
		FROM dbo.PMSL a with (nolock) 
			JOIN dbo.PMCO c on a.PMCo=c.PMCo
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.SLHD s on s.SLCo=a.SLCo and s.SL=a.SL
			--related ACOs
			JOIN dbo.PMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
		WHERE a.SL IS NOT NULL AND a.SLItem IS NOT NULL
			AND c.SLInUse = 'Y'
			AND a.SubCO IS NULL
			AND @Form = 'PMACOS' AND h.KeyID = @keyid
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project, a.PMCo, a.SL, s.[Description], s.KeyID
		UNION ALL
		--POs POCOs Quotes MOs
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Subcontract - Original',s.[Description],
				ID=a.SL,CO=null,ACO=max(a.ACO), Item=null, 
				CASE WHEN EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is null) AND 
					  EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is not null) THEN 'Y' END
				,Amount = sum(IsNull(a.Amount,0)),
				Form='PMSLHeader',s.KeyID
		FROM dbo.PMSL a with (nolock) 
			JOIN dbo.PMCO c on a.PMCo=c.PMCo
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.SLHD s on s.SLCo=a.SLCo and s.SL=a.SL
			--related ACOs
			JOIN dbo.PMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
			--related POs MOs Quotes POCOs
			JOIN dbo.PMMF f on h.PMCo=f.PMCo and h.Project=f.Project and h.ACO=f.ACO
			--related POs
			LEFT JOIN dbo.POHD b on b.POCo=f.POCo and b.PO=f.PO
			--related POCOs
			LEFT JOIN dbo.PMPOCO o on o.POCo=f.POCo and o.PO=f.PO and o.POCONum = f.POCONum
			--related MOs
			LEFT JOIN dbo.INMO m on m.INCo=f.INCo and m.MO=f.MO
			--related Quotes
			LEFT JOIN dbo.MSQH q on q.MSCo=f.MSCo and q.Quote=f.Quote
		WHERE a.SL IS NOT NULL AND a.SLItem IS NOT NULL
			AND c.SLInUse = 'Y'
			AND a.SubCO IS NULL
			AND (
			(@Form='PMPOHeader' AND b.KeyID = @keyid AND f.PO is not null AND f.POItem is not NULL
						AND f.MaterialOption = 'P'
						AND f.POCONum IS NULL
						AND c.POInUse = 'Y'	) OR
			(@Form='PMMOHeader' AND m.KeyID = @keyid AND f.MO IS NOT NULL AND f.MOItem IS NOT NULL
						AND f.MaterialOption = 'M'
						AND c.INInUse = 'Y'	) OR
			(@Form='PMMSQuote' AND q.KeyID = @keyid
						AND f.Quote IS NOT NULL AND f.Location IS NOT NULL
						AND f.MaterialOption='Q' 
						AND c.MSInUse = 'Y') OR
			(@Form = 'PMPOCO' AND o.KeyID = @keyid 
						AND f.PO IS NOT NULL AND f.POItem IS NOT NULL
						AND f.POCONum IS NOT NULL
						AND c.POInUse = 'Y'
						AND f.MaterialOption='P' )
			)
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project, a.PMCo, a.SL, s.[Description], s.KeyID
		UNION ALL
		--SUBCOs
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Subcontract - Original',s.[Description],
				ID=a.SL,CO=null,ACO=max(a.ACO), Item=null, 
				CASE WHEN EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is null) AND 
					  EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMSL where PMCo=a.PMCo and SL=a.SL and SubCO IS NULL and InterfaceDate is not null) THEN 'Y' END
				,Amount = sum(IsNull(a.Amount,0)),
				Form='PMSLHeader',s.KeyID
		FROM dbo.PMSL a with (nolock) 
			JOIN dbo.PMCO c on a.PMCo=c.PMCo
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.SLHD s on s.SLCo=a.SLCo and s.SL=a.SL
			--related ACOs
			JOIN dbo.PMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
			--related SubCOs
			JOIN dbo.PMSL l on l.PMCo=h.PMCo and l.Project = h.Project and l.ACO=h.ACO
			--related SubCOs
			LEFT JOIN dbo.PMSubcontractCO u on u.SLCo=l.SLCo and u.SL=l.SL and u.SubCO = l.SubCO
		WHERE a.SL IS NOT NULL AND a.SLItem IS NOT NULL
			AND c.SLInUse = 'Y'
			AND a.SubCO IS NULL
			AND @Form = 'PMSubcontractCO' and u.KeyID = @keyid 
			AND l.SL is not NULL AND l.SLItem is not NULL
			AND l.SubCO is NOT Null 
			AND c.SLInUse='Y'
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project, a.PMCo, a.SL, s.[Description], s.KeyID
	END
RETURN
END
GO
GRANT SELECT ON  [dbo].[vfPMReadyToInterfaceSL] TO [public]
GO
