use Viewpoint
go

--Contract Selector List
if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckfnLaborForecastReport' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mckfnLaborForecastReport'
	DROP FUNCTION mers.mckfnLaborForecastReport
end
go

print 'CREATE FUNCTION mers.mckfnLaborForecastReport'
go

create function mers.mckfnLaborForecastReport
(
	@JCCo		bCompany
,   @Dept		bDept
,	@Contract	bContract
,   @Project    bJob
,	@POC_MP		VARCHAR(50)
,   @EmpName    VARCHAR(50)
,   @StartMth   VARCHAR(7)
,   @EndMth		VARCHAR(7)
)
-- ========================================================================
-- mers.mckfnLaborForecastReport
-- Author:	Ziebell, Jonathan
-- Create date: 10/03/2016
-- Description:	Prophecy Labor Forecast Report
-- Update Hist: USER--------DATE-------DESC----------
--				J.Ziebell   10/3/16	   Begin Report Dev
--				J.Ziebell   01/26/2018 Exclude Old Detail for new batches
-- ========================================================================
RETURNS TABLE
AS 
RETURN 

SELECT 
		  J.JCCo
		, CI.Department AS 'JC Department'
		, DM.Description AS 'JC Department Desc'
		, J.Contract
		, CM.Description AS 'Contract Description'
		, J.Job as 'Project'
		, J.Description as 'Project Description'
		--, CM.udPOC AS 'ContractPOC'
		, MP_POC.Name AS 'POC'
		, MP.Name as 'Project Manager'
		--, A.CostType
		, A.Phase
		, JP.Description AS 'Phase Description'
		, A.DetMth AS 'Projection Month'
		, A.ToDate AS 'Projection Period End'
		--, A.Source
		, CASE WHEN (A.Employee IS NOT NULL) THEN CAST(A.Employee AS VARCHAR(5)) ELSE 'NOID' END AS EmployeeID
		, CASE WHEN (A.Employee IS NOT NULL) THEN 'YES' ELSE'NO' END AS EmplIDExists
		, N.FullName as 'Employee Name'
		, A.Description AS 'Detail Description'
		, CASE WHEN (A.Employee IS NOT NULL) THEN (N.FullName) ELSE A.Description END AS NameOrDesc
		, A.Hours
		, A.Amount
		, A.Mth As PostedMonth
FROM JCJM J 
		INNER JOIN HQCO HQ
			ON HQ.HQCo = J.JCCo
		INNER JOIN JCCM CM
			ON J.JCCo = CM.JCCo
			AND J.Contract = CM.Contract
		INNER JOIN JCPR A
			ON J.JCCo = A.JCCo
			AND J.Job = A.Job
			AND A.Mth >= (SELECT MAX(CP1.Mth) FROM JCCP CP1
							WHERE CP1.JCCo = A.JCCo  
								AND CP1.Job = A.Job
								AND ((CP1.ProjHours <>0) 
									OR (CP1.ProjCost <>0)))
			AND A.Mth = (Select MAX (A1.Mth) FROM JCPR A1 
							WHERE A.JCCo = A1.JCCo
							AND A.Job = A1.Job)
		INNER JOIN JCJP JP
			ON J.JCCo = JP.JCCo
			AND J.Job = JP.Job
			AND A.PhaseGroup = JP.PhaseGroup
			AND A.Phase = JP.Phase
		LEFT OUTER JOIN JCCI CI
			ON J.JCCo = CI.JCCo
			AND J.Contract = CI.Contract
			AND CI.Item = JP.Item
		LEFT OUTER JOIN	JCMP MP_POC 
			ON CM.JCCo = MP_POC.JCCo
			AND CM.udPOC = MP_POC.ProjectMgr 
		LEFT OUTER JOIN PREHName N
			ON A.JCCo = N.PRCo
			AND A.Employee = N.Employee
		LEFT OUTER JOIN	JCMP MP 
			ON J.JCCo = MP.JCCo
			AND J.ProjectMgr = MP.ProjectMgr 
		LEFT OUTER JOIN	JCDM DM
			ON J.JCCo = DM.JCCo
			AND CI.Department = DM.Department 
WHERE A.CostType = 1
AND ((A.Hours <>0) OR (A.Amount <>0))
	AND A.DetMth >=  CONCAT(DATEPART(YYYY,SYSDATETIME()),'-',DATEPART(MM,SYSDATETIME()),'-01') 
	AND J.JCCo =  ISNULL(@JCCo, A.JCCo)
	AND CI.Department = ISNULL(@Dept, CI.Department)
	AND ((J.Contract  LIKE ('%' + coalesce((@Contract),'') + '%')) OR (@Contract IS NULL))
	AND ((J.Job LIKE ('%' + coalesce((@Project),'') + '%')) OR (@Project IS NULL)) 
	AND ((@POC_MP IS NULL)
			OR (UPPER(MP_POC.Name) LIKE ('%' + coalesce(UPPER(@POC_MP),'') + '%'))
			OR (UPPER(MP.Name) LIKE ('%' + coalesce(UPPER(@POC_MP),'') + '%'))) 
	AND (UPPER(N.FullName) LIKE ('%' + coalesce(UPPER(@EmpName),'') + '%') OR @EmpName IS NULL)
	AND ( (@StartMth IS NULL)
			OR ( (CAST((SUBSTRING(@StartMth,1,2)) AS INT)<=(DATEPART(MONTH, A.DetMth))) 
					AND (CAST((SUBSTRING(@StartMth,4,4)) AS INT)=(DATEPART(YEAR, A.DetMth))))
			OR (CAST((SUBSTRING(@StartMth,4,4)) AS INT)<(DATEPART(YEAR, A.DetMth))))
	AND ( (@EndMth IS NULL)
			OR ( (CAST((SUBSTRING(@EndMth,1,2)) AS INT)>=(DATEPART(MONTH, A.DetMth))) 
					AND (CAST((SUBSTRING(@EndMth,4,4)) AS INT)=(DATEPART(YEAR, A.DetMth))))
			OR (CAST((SUBSTRING(@EndMth,4,4)) AS INT)>(DATEPART(YEAR, A.DetMth))))

GO

Grant SELECT ON mers.mckfnLaborForecastReport TO [MCKINSTRY\Viewpoint Users]