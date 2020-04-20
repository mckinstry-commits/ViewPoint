SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		AW vfPMReadyToInterfaceProject
-- Modified: 		TFS 42706 added another level to drill down query
--
-- Create date: 1/31/2013
-- Description:	Returns the PM Records Ready To Interface Project Records
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
CREATE FUNCTION dbo.vfPMReadyToInterfaceProject(@Form varchar(30), @keyid bigint)
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

		INSERT @readyToInterfaceItems(PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item, InterfacedYN, Amount, Form, KeyID)
		SELECT DISTINCT j.JCCo,j.JobStatus,j.ProjectMgr,j.Job,Interface='Project', j.Description,
			ID=j.Job, CO=null, ACO=null, Item=null, 
			CASE WHEN EXISTS(SELECT 1 FROM dbo.JCCH WHERE JCCo=j.JCCo AND Job=j.Job AND SourceStatus = 'Y'
								AND ( (j.JobStatus = 1)
								 OR (j.JobStatus = 2 AND c.PostSoftClosedJobs = 'Y')
								 OR (j.JobStatus = 3 AND c.PostClosedJobs = 'Y'))) OR j.JobStatus = 0 THEN 'N' ELSE 'Y' END
			,Amount=null,
			Form='PMProjects',KeyID=j.KeyID
		FROM dbo.JCJM j
		JOIN dbo.JCCO c on c.JCCo=j.JCCo
		WHERE @Form =' PMProjects' and j.KeyID = @keyid
		UNION ALL
		--ACOs
		SELECT DISTINCT j.JCCo,j.JobStatus,j.ProjectMgr,j.Job,Interface='Project', j.Description,
			ID=j.Job, CO=null, ACO=null, Item=null, 
			CASE WHEN EXISTS(SELECT 1 FROM dbo.JCCH WHERE JCCo=j.JCCo AND Job=j.Job AND SourceStatus = 'Y'
								AND ((j.JobStatus = 1)
								 OR (j.JobStatus = 2 AND c.PostSoftClosedJobs = 'Y')
								 OR (j.JobStatus = 3 AND c.PostClosedJobs = 'Y'))) OR j.JobStatus = 0 THEN 'N' ELSE 'Y' END
			,Amount=null,
			Form='PMProjects',KeyID=j.KeyID
		FROM dbo.JCJM j
			JOIN dbo.JCCO c on c.JCCo=j.JCCo
			JOIN dbo.PMOH h on h.PMCo=j.JCCo and h.Project = j.Job
		WHERE @Form = 'PMACOS' AND h.ACO IS NOT NULL 
				AND h.KeyID = @keyid
		UNION ALL
		--POs POCOs MOs Quotes
		SELECT DISTINCT j.JCCo,j.JobStatus,j.ProjectMgr,j.Job,Interface='Project', j.Description,
			ID=j.Job, CO=null, ACO=null, Item=null, 
			CASE WHEN EXISTS(SELECT 1 FROM dbo.JCCH WHERE JCCo=j.JCCo AND Job=j.Job AND SourceStatus = 'Y'
								AND ((j.JobStatus = 1)
								 OR (j.JobStatus = 2 AND jc.PostSoftClosedJobs = 'Y')
								 OR (j.JobStatus = 3 AND jc.PostClosedJobs = 'Y'))) OR j.JobStatus = 0 THEN 'N' ELSE 'Y' END
			,Amount=null,
			Form='PMProjects',KeyID=j.KeyID
		FROM dbo.JCJM j
			JOIN dbo.PMCO c on c.PMCo=j.JCCo
			JOIN dbo.JCCO jc on jc.JCCo=j.JCCo
			--related POs MOs Quotes POCOs
			JOIN dbo.PMMF a on a.PMCo=j.JCCo and a.Project = j.Job
			--related POs
			LEFT JOIN dbo.POHD b on b.POCo=a.POCo and b.PO=a.PO
			--related MOs
			LEFT JOIN dbo.INMO i on i.INCo=a.INCo and i.MO=a.MO
			--related POCOs
			LEFT JOIN dbo.PMPOCO o on o.POCo=a.POCo and o.PO=a.PO and o.POCONum = a.POCONum
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
				AND q.KeyID = @keyid)
		UNION ALL
		-- SLs & SubCOs
		SELECT DISTINCT j.JCCo,j.JobStatus,j.ProjectMgr,j.Job,Interface='Project', j.Description,
			ID=j.Job, CO=null, ACO=null, Item=null, 
			CASE WHEN EXISTS(SELECT 1 FROM dbo.JCCH WHERE JCCo=j.JCCo AND Job=j.Job AND SourceStatus = 'Y'
								AND ((j.JobStatus = 1)
								 OR (j.JobStatus = 2 AND jc.PostSoftClosedJobs = 'Y')
								 OR (j.JobStatus = 3 AND jc.PostClosedJobs = 'Y'))) OR j.JobStatus = 0 THEN 'N' ELSE 'Y' END
			,Amount=null,
			Form='PMProjects',KeyID=j.KeyID
		FROM dbo.JCJM j
			JOIN dbo.PMCO c on c.PMCo=j.JCCo
			JOIN dbo.JCCO jc on jc.JCCo=j.JCCo
			--related SLs SubCOs
			JOIN dbo.PMSL l on l.PMCo=j.JCCo and l.Project = j.Job
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
GRANT SELECT ON  [dbo].[vfPMReadyToInterfaceProject] TO [public]
GO
