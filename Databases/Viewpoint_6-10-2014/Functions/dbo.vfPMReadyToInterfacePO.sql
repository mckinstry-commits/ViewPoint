SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		AW vfPMReadyToInterfacePO
-- Modified: 		TFS 42706 added another level to drill down query

-- Create date: 1/31/2013
-- Description:	Returns the PM Records Ready To Interface PM POs Records
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
CREATE FUNCTION dbo.vfPMReadyToInterfacePO(@Form varchar(30), @keyid bigint)
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
	IF @Form = 'PMPOHeader'
	BEGIN
		INSERT @readyToInterfaceItems(PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item, InterfacedYN, Amount, Form, KeyID)
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,Project=a.Project,'Purchase Order Item',a.MtlDescription,
			ID=a.PO, CO=null, ACO=a.ACO, Item=a.POItem,case when a.InterfaceDate is null then 'N' else 'Y' end,isnull(a.Amount,0),
			Form='PMPOHeader',b.KeyID
		FROM dbo.PMMF a 
			INNER JOIN dbo.PMCO c on a.PMCo=c.PMCo
			INNER JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			INNER JOIN dbo.POHD b on b.POCo=a.POCo and b.PO=a.PO
		WHERE @Form = 'PMPOHeader' AND b.KeyID = @keyid AND a.PO IS NOT NULL AND a.POItem IS NOT NULL
				AND a.MaterialOption = 'P'
				AND a.POCONum IS NULL
				AND c.POInUse = 'Y'
	END
	ELSE
	BEGIN
		INSERT @readyToInterfaceItems(PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item, InterfacedYN, Amount, Form, KeyID)	
		--Project
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,Project=a.Project,'Purchase Order - Original',b.[Description],
			ID=a.PO, CO=null, ACO=max(a.ACO), Item=null,
			CASE WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is null) AND 
					  EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is not null) THEN 'Partial'
				WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is null) THEN 'N'
				WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is not null) THEN 'Y' END
			,sum(IsNull(a.Amount,0)),
			Form='PMPOHeader',b.KeyID
		FROM dbo.PMMF a 
			JOIN dbo.PMCO c on a.PMCo=c.PMCo
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.POHD b on b.POCo=a.POCo and b.PO=a.PO
		WHERE  @Form='PMProjects' AND j.KeyID = @keyid
			 AND a.PO IS NOT NULL AND a.POItem IS NOT NULL
					AND a.MaterialOption = 'P'
					AND a.POCONum IS NULL
					AND c.POInUse = 'Y'
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,b.[Description],a.POCo,a.PO,a.POCONum,a.ACO,b.KeyID
		UNION ALL
		--ACOS
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,Project=a.Project,'Purchase Order - Original',b.[Description],
			ID=a.PO, CO=null, ACO=max(a.ACO), Item=null,
			CASE WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is null) AND 
					EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is not null) THEN 'Partial'
			WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is null) THEN 'N'
			WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is not null) THEN 'Y' END
			,sum(IsNull(a.Amount,0)),
			Form='PMPOHeader',b.KeyID
		FROM dbo.PMMF a 
			JOIN dbo.PMCO c on a.PMCo=c.PMCo
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.POHD b on b.POCo=a.POCo and b.PO=a.PO
			--related ACOs
			JOIN dbo.PMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
		WHERE a.PO IS NOT NULL AND a.POItem IS NOT NULL
				AND a.MaterialOption = 'P'
				AND a.POCONum IS NULL
				AND c.POInUse = 'Y'
				AND @Form = 'PMACOS' AND h.ACO IS NOT NULL AND h.KeyID = @keyid
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,b.[Description],a.POCo,a.PO,a.ACO,b.KeyID
		UNION ALL
		--POCOs MOs Quotes
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,Project=a.Project,'Purchase Order - Original',b.[Description],
			ID=a.PO, CO=null, ACO=max(a.ACO), Item=null,
			CASE WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is null) AND 
					EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is not null) THEN 'Partial'
			WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is null) THEN 'N'
			WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is not null) THEN 'Y' END
			,sum(IsNull(a.Amount,0)),
			Form='PMPOHeader',b.KeyID
		FROM dbo.PMMF a 
			JOIN dbo.PMCO c on a.PMCo=c.PMCo
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.POHD b on b.POCo=a.POCo and b.PO=a.PO
			--related ACOs
			JOIN dbo.PMOH h on h.PMCo=a.PMCo and h.Project=a.Project and h.ACO=a.ACO
			--related POCOs MOs Quotes
			JOIN dbo.PMMF f on f.PMCo=a.PMCo and f.Project=a.Project and f.ACO=a.ACO
			--related POCOs
			LEFT JOIN dbo.PMPOCO o on o.POCo=f.POCo and o.PO=f.PO and o.POCONum = f.POCONum
			--related MOs
			LEFT JOIN dbo.INMO m on m.INCo=f.INCo and m.MO=f.MO
			--related Quotes
			LEFT JOIN dbo.MSQH q on q.MSCo=f.MSCo and q.Quote=f.Quote
		WHERE a.PO IS NOT NULL AND a.POItem IS NOT NULL
				AND a.MaterialOption = 'P'
				AND a.POCONum IS NULL
				AND c.POInUse = 'Y'
				AND (
					(@Form = 'PMPOCO' AND f.PO IS NOT NULL AND f.POItem IS NOT NULL
						AND f.POCONum IS NOT NULL
						AND c.POInUse = 'Y'
						AND f.MaterialOption='P'
						AND o.KeyID = @keyid) OR
					(@Form = 'PMMOHeader' AND f.MO IS NOT NULL AND f.MOItem IS NOT NULL
						AND f.MaterialOption = 'M'
						AND c.INInUse = 'Y'
						AND m.KeyID = @keyid) OR
					(@Form = 'PMMSQuote' AND f.Quote IS NOT NULL AND f.Location IS NOT NULL
						AND f.MaterialOption='Q' 
						AND c.MSInUse = 'Y'
						AND q.KeyID = @keyid)
				)
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,b.[Description],a.POCo,a.PO,a.ACO,b.KeyID
		UNION ALL
		--SLs SubCOs
		SELECT j.JCCo,j.JobStatus,j.ProjectMgr,Project=a.Project,'Purchase Order - Original',b.[Description],
			ID=a.PO, CO=null, ACO=max(a.ACO), Item=null,
			CASE WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is null) AND 
					EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is not null) THEN 'Partial'
			WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is null) THEN 'N'
			WHEN EXISTS(select 1 from PMMF where POCo=a.POCo and PO=a.PO AND POCONum IS NULL and InterfaceDate is not null) THEN 'Y' END
			,sum(IsNull(a.Amount,0)),
			Form='PMPOHeader',b.KeyID
		FROM dbo.PMMF a 
			JOIN dbo.PMCO c on a.PMCo=c.PMCo
			JOIN dbo.JCJM j on a.PMCo=j.JCCo and a.Project = j.Job
			JOIN dbo.POHD b on b.POCo=a.POCo and b.PO=a.PO
			--related SLs SubCOs
			JOIN dbo.PMSL l on l.PMCo=a.PMCo and l.Project=a.Project and l.ACO=a.ACO
			--related Sls
			LEFT JOIN dbo.SLHD s on s.SLCo=l.SLCo and s.SL=l.SL
			--related SubCos
			LEFT JOIN dbo.PMSubcontractCO u on u.SLCo=l.SLCo and u.SL=l.SL and u.SubCO = l.SubCO
		WHERE a.PO IS NOT NULL AND a.POItem IS NOT NULL
				AND a.MaterialOption = 'P'
				AND a.POCONum IS NULL
				AND c.POInUse = 'Y'
				AND (
				(@Form='PMSLHeader' AND l.SL IS NOT NULL AND l.SLItem IS NOT NULL
					AND c.SLInUse = 'Y'
					AND l.SubCO IS NULL
					AND s.KeyID = @keyid) OR
				(@Form='PMSubcontractCO' AND l.SL IS NOT NULL AND l.SLItem IS NOT NULL
					AND l.SubCO IS NOT NULL 
					AND c.SLInUse='Y'
					AND u.KeyID = @keyid)
				)
		GROUP BY j.JCCo,j.JobStatus,j.ProjectMgr,a.Project,b.[Description],a.POCo,a.PO,a.ACO,b.KeyID
	END

RETURN
END
GO
GRANT SELECT ON  [dbo].[vfPMReadyToInterfacePO] TO [public]
GO
