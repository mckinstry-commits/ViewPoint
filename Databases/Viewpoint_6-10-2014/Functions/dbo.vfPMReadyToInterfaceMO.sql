SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		AW vfPMReadyToInterfaceMO
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
--
-- =============================================
CREATE FUNCTION dbo.vfPMReadyToInterfaceMO(@Form varchar(30), @keyid bigint)
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
	InterfacedYN varchar(10) NULL,
	Form varchar(30),
	KeyID bigint
)
AS 

BEGIN

	IF @Form = 'PMMOHeader'
	BEGIN
		INSERT @readyToInterfaceItems(PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item, InterfacedYN, Amount, Form, KeyID)
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Material Order Item', a.MtlDescription,
			ID=a.MO, CO=null,ACO=a.ACO,Item=a.MOItem, 
			CASE WHEN a.InterfaceDate IS NULL THEN 'N' ELSE 'Y' END
			,Amount=IsNull(a.Amount,0),
			Form='PMMOHeader',KeyID=b.KeyID
		FROM dbo.PMMF a
			INNER JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			INNER JOIN dbo.PMCO c ON c.PMCo=a.PMCo
			INNER JOIN dbo.INMO b on b.INCo=a.INCo and b.MO=a.MO
		WHERE a.MO IS NOT NULL AND a.MOItem IS NOT NULL
			AND a.MaterialOption = 'M'
			AND c.INInUse = 'Y'
			AND b.KeyID = @keyid		
	END
	ELSE
	BEGIN
		INSERT @readyToInterfaceItems(PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item, InterfacedYN, Amount, Form, KeyID)
		--Project
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Material Order', b.[Description],
			ID=a.MO, CO=null,ACO=null,Item=null,
			CASE WHEN EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is null) AND 
					  EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is not null) THEN 'Y' END
			,Amount=sum(IsNull(a.Amount,0)),
			Form='PMMOHeader',KeyID=b.KeyID
		FROM dbo.PMMF a
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.PMCO c ON c.PMCo=a.PMCo
			JOIN dbo.INMO b on b.INCo=a.INCo and b.MO=a.MO
		WHERE  a.MO IS NOT NULL AND a.MOItem IS NOT NULL
				AND a.MaterialOption = 'M'
				AND c.INInUse = 'Y'
				AND @Form = 'PMProjects' AND j.KeyID = @keyid
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,b.[Description],a.INCo,a.MO,b.KeyID
		UNION ALL
		--ACOs
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Material Order', b.[Description],
			ID=a.MO, CO=null,ACO=null,Item=null,
			CASE WHEN EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is null) AND 
					  EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is not null) THEN 'Y' END
			,Amount=sum(IsNull(a.Amount,0)),
			Form='PMMOHeader',KeyID=b.KeyID
		FROM dbo.PMMF a
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.PMCO c ON c.PMCo=a.PMCo
			JOIN dbo.INMO b on b.INCo=a.INCo and b.MO=a.MO
			--ACOs
			JOIN dbo.PMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
		WHERE a.MO IS NOT NULL AND a.MOItem IS NOT NULL
				AND a.MaterialOption = 'M'
				AND c.INInUse = 'Y'
				AND (@Form = 'PMACOS' AND h.KeyID = @keyid)
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,b.[Description],a.INCo,a.MO,b.KeyID
		UNION ALL
		--POs POCOs Quotes
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Material Order', b.[Description],
			ID=a.MO, CO=null,ACO=null,Item=null,
			CASE WHEN EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is null) AND 
					  EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is not null) THEN 'Y' END
			,Amount=sum(IsNull(a.Amount,0)),
			Form='PMMOHeader',KeyID=b.KeyID
		FROM dbo.PMMF a
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.PMCO c ON c.PMCo=a.PMCo
			JOIN dbo.INMO b on b.INCo=a.INCo and b.MO=a.MO
			--ACOs
			JOIN dbo.PMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
			-- POs POCOs Quotes
			JOIN dbo.PMMF f on h.PMCo=f.PMCo and h.Project=f.Project and h.ACO=f.ACO
			--related POs
			LEFT JOIN dbo.POHD z on z.POCo=f.POCo and z.PO=f.PO
			--related POCOs
			LEFT JOIN dbo.PMPOCO p on p.POCo=f.POCo and p.PO=f.PO and p.POCONum = f.POCONum
			--related Quotes
			LEFT JOIN dbo.MSQH q on q.MSCo=f.MSCo and q.Quote=f.Quote
		WHERE a.MO IS NOT NULL AND a.MOItem IS NOT NULL
				AND a.MaterialOption = 'M'
				AND c.INInUse = 'Y'
				AND (
				(@Form='PMPOHeader' AND z.KeyID = @keyid AND f.PO is not null AND f.POItem is not NULL
						AND f.MaterialOption = 'P'
						AND f.POCONum IS NULL
						AND c.POInUse = 'Y'	) OR
				(@Form='PMMSQuote' AND q.KeyID = @keyid
						AND f.Quote IS NOT NULL AND f.Location IS NOT NULL
						AND f.MaterialOption='Q' 
						AND c.MSInUse = 'Y') OR
				(@Form = 'PMPOCO' AND p.KeyID = @keyid 
						AND a.PO IS NOT NULL AND a.POItem IS NOT NULL
						AND a.POCONum IS NOT NULL
						AND c.POInUse = 'Y'
						AND a.MaterialOption='P' )
				)
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,b.[Description],a.INCo,a.MO,b.KeyID
		UNION ALL
		--SLs SubCOs
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,'Material Order', b.[Description],
			ID=a.MO, CO=null,ACO=null,Item=null,
			CASE WHEN EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is null) AND 
					  EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMMF where INCo=a.INCo and MO=a.MO and InterfaceDate is not null) THEN 'Y' END
			,Amount=sum(IsNull(a.Amount,0)),
			Form='PMMOHeader',KeyID=b.KeyID
		FROM dbo.PMMF a
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.PMCO c ON c.PMCo=a.PMCo
			JOIN dbo.INMO b on b.INCo=a.INCo and b.MO=a.MO
			--related ACOs
			JOIN dbo.PMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
			--related SLs SubCOs
			JOIN dbo.PMSL l on l.PMCo=h.PMCo and l.Project = h.Project and l.ACO=h.ACO
			--related SubCOs
			LEFT JOIN dbo.PMSubcontractCO u on u.SLCo=l.SLCo and u.SL=l.SL and u.SubCO = l.SubCO
			--related SLs
			LEFT JOIN dbo.SLHD s on s.SLCo=l.SLCo and s.SL=l.SL
		WHERE a.MO IS NOT NULL AND a.MOItem IS NOT NULL
				AND a.MaterialOption = 'M'
				AND c.INInUse = 'Y'
				AND (
				(@Form = 'PMSLHeader' and s.KeyID = @keyid 
						AND l.SL is not NULL AND l.SLItem is not NULL
						AND l.SubCO is Null 
						AND c.SLInUse='Y') OR
				(@Form = 'PMSubcontractCO' and u.KeyID = @keyid 
					AND l.SL is not NULL AND l.SLItem is not NULL
					AND l.SubCO is NOT Null 
					AND c.SLInUse='Y')
				)
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,b.[Description],a.INCo,a.MO,b.KeyID

	END
RETURN
END
GO
GRANT SELECT ON  [dbo].[vfPMReadyToInterfaceMO] TO [public]
GO
