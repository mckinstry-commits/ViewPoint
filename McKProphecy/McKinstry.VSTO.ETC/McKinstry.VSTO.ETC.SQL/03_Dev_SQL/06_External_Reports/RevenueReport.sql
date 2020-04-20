use Viewpoint
go

--Contract Selector List
if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckfnRevForecastReport' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mckfnRevForecastReport'
	DROP FUNCTION mers.mckfnRevForecastReport
end
go

print 'CREATE FUNCTION mers.mckfnRevForecastReport'
go

create function mers.mckfnRevForecastReport
(
	@JCCo		bCompany
,   @Dept		bDept
,	@Contract	bContract
,   @Project    bJob
,	@POC_MP		VARCHAR(50)
,   @StartMth   VARCHAR(7)
,   @EndMth		VARCHAR(7)
)
-- ========================================================================
-- mers.mckfnRevForecastReport
-- Author:	Ziebell, Jonathan
-- Create date: 10/03/2016
-- Description:	Prophecy Labor Forecast Report
-- Update Hist: USER--------DATE-------DESC----------
--				J.Ziebell   10/3/16	   Begin Report Dev
--				J.Ziebell	11/18/2016 Fix Revenue Calculation, Add Fields
-- ========================================================================
RETURNS TABLE
AS 
RETURN 
WITH MonthlyCost ( JCCo 
				, Contract
				, Department
				, udPRGNumber
				, udPRGDescription
				, PostedMonth
				, ProjectionMonth
				, ProjectedCost
				)
		AS (SELECT  JM.JCCo
					, CI.Contract
					, CI.Department
					, CI.udPRGNumber
					, CI.udPRGDescription
					, PR.Mth
					, PR.DetMth
					, sum(PR.Amount) AS ProjectedCost 
			FROM JCJM JM With (Nolock)
				INNER JOIN JCJP JP  With (Nolock)
					ON JP.JCCo = JM.JCCo 
					AND JP.Job = JM.Job 
					AND JP.Contract = JM.Contract
				INNER JOIN JCPR PR With (Nolock)
					ON PR.JCCo = JP.JCCo 
					AND PR.Job = JP.Job 
					AND PR.PhaseGroup = JP.PhaseGroup 
					AND PR.Phase = JP.Phase
					AND PR.DetMth IS NOT NULL
					AND PR.Mth = (SELECT MAX(PR1.Mth) FROM JCPR PR1 With (Nolock)
										WHERE PR1.JCCo = PR.JCCo 
										AND PR1.Job = PR.Job)
				INNER JOIN JCCI CI With (Nolock)
					ON 	JM.JCCo = CI.JCCo
					AND JP.Contract = CI.Contract
					AND JP.Item = CI.Item
				WHERE JM.JCCo = @JCCo
					AND JM.Contract = ISNULL(@Contract,JM.Contract)
					--AND ((CI.Department IS NOT NULL) AND ((@Dept IS NULL) OR (CI.Department = @Dept)))
					--AND CI.Department = ISNULL(@Dept, CI.Department)
					--AND CI.udPRGNumber = ISNULL(@Project, CI.udPRGNumber)
					--AND JM.JobStatus < 2
				GROUP BY  JM.JCCo
						, CI.Contract
						, CI.Department
						, CI.udPRGNumber
						, CI.udPRGDescription
						, PR.Mth
						, PR.DetMth), 
	FutureCost ( JCCo 
				, Contract
				, udPRGNumber
				, Department
				, ProjectedCost
				)
		AS (SELECT  JM.JCCo
					, CI.Contract
					, CI.udPRGNumber
					, CI.Department
					, CAST(sum(PR.Amount) AS float) AS ProjectedCost 
			FROM JCJM JM With (Nolock)
				INNER JOIN JCJP JP  With (Nolock)
					ON JP.JCCo = JM.JCCo 
					AND JP.Job = JM.Job 
					AND JP.Contract = JM.Contract
				INNER JOIN JCPR PR With (Nolock)
					ON PR.JCCo = JP.JCCo 
					AND PR.Job = JP.Job 
					AND PR.PhaseGroup = JP.PhaseGroup 
					AND PR.Phase = JP.Phase
					AND PR.DetMth IS NOT NULL
					AND PR.Mth = (SELECT MAX(PR1.Mth) FROM JCPR PR1 With (Nolock)
										WHERE PR1.JCCo = PR.JCCo 
										AND PR1.Job = PR.Job)
				INNER JOIN JCCI CI With (Nolock)
					ON 	JM.JCCo = CI.JCCo
					AND JP.Contract = CI.Contract
					AND JP.Item = CI.Item
				WHERE JM.JCCo = @JCCo
					AND JM.Contract = ISNULL(@Contract,JM.Contract)
					--AND ((CI.Department IS NOT NULL) AND ((@Dept IS NULL) OR (CI.Department = @Dept)))
					--AND CI.Department = ISNULL(@Dept, CI.Department)
					--AND CI.udPRGNumber = ISNULL(@Project, CI.udPRGNumber)
					--AND JM.JobStatus < 2
					AND PR.DetMth >=  CONCAT(DATEPART(YYYY,SYSDATETIME()),'-',DATEPART(MM,SYSDATETIME()),'-01')
				GROUP BY  JM.JCCo
						, CI.Contract
						, CI.udPRGNumber
						, CI.Department), 		
	Rev_Sum 
				( JCCo
				, Contract
				, udPRGNumber
				, Department
				, ProjDollars
				)
		AS (SELECT
				  CI.JCCo
				, CI.Contract
				, CI.udPRGNumber
				, CI.Department
				, SUM(IP.ProjDollars)
		FROM JCCI CI With (Nolock)
			INNER JOIN JCIP IP With (Nolock)
				ON CI.JCCo = IP.JCCo
				AND CI.Contract = IP.Contract
				AND CI.Item = IP.Item
			WHERE CI.JCCo = @JCCo
				--AND ((CI.Department IS NOT NULL) AND ((@Dept IS NULL) OR (CI.Department = @Dept)))
				AND CI.Contract = ISNULL(@Contract,CI.Contract)
				--AND CI.udPRGNumber = ISNULL(@Project, CI.udPRGNumber)
			GROUP BY  CI.JCCo
				, CI.Contract
				, CI.udPRGNumber
				, CI.Department
				--, CI.udPRGDescription 
				) ,
	Cost_Sum 
				( JCCo 
				, Contract
				, udPRGNumber
				, Department
				, ProjectedCost
				)
		AS (SELECT 
				  JM.JCCo
				, CI.Contract
				, CI.udPRGNumber
				, CI.Department
				, sum(CP.ProjCost) AS ProjectedCost 
			FROM JCJM JM With (Nolock)
			INNER JOIN JCJP JP  With (Nolock)
				ON JP.JCCo = JM.JCCo 
				AND JP.Job = JM.Job 
				AND JP.Contract = JM.Contract
			INNER JOIN JCCP CP With (Nolock)
				ON CP.JCCo = JP.JCCo 
				AND CP.Job = JP.Job 
				AND CP.PhaseGroup = JP.PhaseGroup 
				AND CP.Phase = JP.Phase
			INNER JOIN JCCI CI With (Nolock)
				ON 	JM.JCCo = CI.JCCo
				AND JP.Contract = CI.Contract
				AND JP.Item = CI.Item
			WHERE JM.JCCo = @JCCo
				--AND ((CI.Department IS NOT NULL) AND ((@Dept IS NULL) OR (CI.Department = @Dept)))
				AND JM.Contract = ISNULL(@Contract,JM.Contract)
				--AND CI.udPRGNumber = ISNULL(@Project, CI.udPRGNumber)
				--AND JM.JobStatus < 2
			GROUP BY  JM.JCCo
					, CI.Contract
					, CI.udPRGNumber
					, CI.Department) ,
	JTD_Earn 
				( JCCo
				, Contract 
				, udPRGNumber
				, Department
				, JTDEarnedRev
				, JTDGMPerc
				, CostToComplete
				)
		AS (SELECT 
				  WIP.JCCo
				, WIP.Contract
				, WIP.PRGNumber AS udPRGnumber
				, WIP.JCCIDepartment
				, MAX(WIP.JTDEarnedRev)
				, MAX(ProjFinalGMPerc)
				, MAX(EstimatedCostToComplete)
			FROM mckWipArchiveJC3 WIP With (Nolock)
			WHERE WIP.JCCo =  @JCCo
				AND WIP.Contract = ISNULL(LTRIM(@Contract), WIP.Contract)
				--AND ((WIP.JCCIDepartment IS NOT NULL) AND ((@Dept IS NULL) OR (WIP.JCCIDepartment = @Dept)))
				--AND WIP.JCCIDepartment = ISNULL(@Dept,WIP.JCCIDepartment)
				--AND WIP.PRGNumber = ISNULL(@Project, WIP.PRGNumber)
				--AND WIP.ContractStatus < 2
				AND WIP.ThroughMonth = (SELECT MAX(WIP2.ThroughMonth) 
											FROM mckWipArchiveJC3 WIP2 With (Nolock)
											WHERE WIP.JCCo = WIP2.JCCo
											AND WIP.Contract = WIP2.Contract
											AND ((WIP.PRGNumber = WIP2.PRGNumber) OR ((WIP.PRGNumber IS NULL) AND  (WIP2.PRGNumber iS NULL)))
											AND ((WIP.JCCIDepartment = WIP2.JCCIDepartment) OR ((WIP.JCCIDepartment IS NULL) AND (WIP2.JCCIDepartment iS NULL)))
											AND WIP2.ThroughMonth <= DATEADD(Month,-1,SYSDATETIME())
											--AND WIP2.ThroughMonth >='01-MAY-2016'
											)
			GROUP BY 
				  WIP.JCCo
				, WIP.Contract
				, WIP.PRGNumber
				, WIP.JCCIDepartment
				),
		Margin_Calc 
				( JCCo 
				, Contract
				, udPRGNumber
				, Department
				, MarginCalc
				)
		AS (SELECT 
				  RS.JCCo
				, RS.Contract
				, RS.udPRGNumber
				, RS.Department
				, CASE WHEN CS.ProjectedCost <= 0 THEN 1
						WHEN RS.ProjDollars = CS.ProjectedCost THEN 0
						WHEN RS.ProjDollars = 0 THEN -1
						WHEN RS.ProjDollars > CS.ProjectedCost THEN /*ROUND(*/((RS.ProjDollars-CS.ProjectedCost)/CAST(RS.ProjDollars AS FLOAT))/*, 9, 1)*/
						WHEN ((RS.ProjDollars < CS.ProjectedCost) AND (RS.ProjDollars > 0) AND ((CS.ProjectedCost - RS.ProjDollars) < RS.ProjDollars)) THEN /*ROUND(*/((RS.ProjDollars-CS.ProjectedCost)/CAST(RS.ProjDollars AS FLOAT))/* ,9,1)*/
						ELSE -1 END as 'Projected Margin' 
			FROM Rev_Sum RS
			INNER JOIN Cost_Sum CS
				ON RS.JCCo = CS.JCCo 
				AND RS.Contract = CS.Contract
				AND RS.udPRGNumber = CS.udPRGNumber
				AND RS.Department = CS.Department
			WHERE RS.JCCo = @JCCo
				AND RS.Contract = ISNULL(@Contract,RS.Contract)
				)
SELECT 
		  CM.JCCo
		, MC.Department AS 'JC Department'
		, DM.Description AS 'JC Department Desc'
		, CM.Contract
		, CM.Description AS 'Contract Description'
		, MC.udPRGNumber AS 'PRG Number'
		, MC.udPRGDescription AS 'PRG Description'
		--, J.Job as 'Project'
		--, J.Description as 'Project Description'
		, MP_POC.Name AS 'POC'
		--, MP.Name as 'Project Manager'
		, MC.ProjectionMonth AS 'Projection Month'
		, MC.ProjectedCost As 'Monthly Projected Cost'
		, FC.ProjectedCost AS 'FutureCostTotal'
		, RS.ProjDollars AS 'Revenue Total'
		, CS.ProjectedCost AS 'Cost Total'
		--, CASE WHEN RS.ProjDollars >0 THEN ((RS.ProjDollars-CS.ProjectedCost)/CAST(RS.ProjDollars AS FLOAT)) ELSE 0 END as 'Projected Margin'
		, GIN.MarginCalc as 'Projected Margin'
		, CASE WHEN GIN.MarginCalc >= 0 THEN (FC.ProjectedCost/(1-GIN.MarginCalc)) 
				--WHEN RS.ProjDollars = CS.ProjectedCost THEN FC.ProjectedCost
				--WHEN RS.ProjDollars >= 0 THEN FC.ProjectedCost
				ELSE FC.ProjectedCost END as 'Future Revenue Total'
		, JE.JTDEarnedRev AS 'JTD Earned Revenue'
		, (RS.ProjDollars - JE.JTDEarnedRev) AS 'Remaining Revenue'
		--, CASE WHEN RS.ProjDollars >0 THEN ((RS.ProjDollars) - (JE.JTDEarnedRev) - (((1+((RS.ProjDollars-CS.ProjectedCost)/RS.ProjDollars)) * FC.ProjectedCost)))  ELSE 0 END AS 'Unburned Revenue'
		, CASE WHEN GIN.MarginCalc >= 0 THEN ((RS.ProjDollars) - (JE.JTDEarnedRev) - (FC.ProjectedCost/(1-GIN.MarginCalc))) 
				--WHEN RS.ProjDollars = CS.ProjectedCost THEN ((RS.ProjDollars) - (JE.JTDEarnedRev) - (FC.ProjectedCost))
				--WHEN RS.ProjDollars >= 0 THEN ((RS.ProjDollars) - (JE.JTDEarnedRev) - (FC.ProjectedCost))
				ELSE ((RS.ProjDollars) - (JE.JTDEarnedRev) - (FC.ProjectedCost)) END AS 'Unburned Revenue'
		, (JE.CostToComplete - FC.ProjectedCost) AS 'Absent Future Cost'
		, CASE WHEN GIN.MarginCalc >= 0 THEN ((JE.CostToComplete - FC.ProjectedCost)/CAST((1-GIN.MarginCalc) AS FLOAT)) 
				--WHEN RS.ProjDollars = CS.ProjectedCost THEN (JE.CostToComplete - FC.ProjectedCost)
				--WHEN RS.ProjDollars >= 0 THEN (JE.CostToComplete - FC.ProjectedCost)
				ELSE (JE.CostToComplete - FC.ProjectedCost) END AS 'Abs Future Cost as Rev'
		, CASE WHEN RS.ProjDollars >0 THEN ROUND((GIN.MarginCalc - JE.JTDGMPerc),9,1)
				ELSE 0 END AS 'Margin Change'
		--, CASE WHEN RS.ProjDollars >0 THEN (MC.ProjectedCost * (1+((RS.ProjDollars-CS.ProjectedCost)/RS.ProjDollars))) ELSE 0 END AS 'Monthly Revenue' 
		, CASE WHEN GIN.MarginCalc >= 0 THEN (MC.ProjectedCost/(1-GIN.MarginCalc)) 
				--WHEN RS.ProjDollars = CS.ProjectedCost THEN MC.ProjectedCost
				--WHEN RS.ProjDollars >= 0 THEN MC.ProjectedCost
				ELSE MC.ProjectedCost END AS 'Monthly Revenue'
		, /*CASE WHEN ((MC.ProjectionMonth =  CONCAT(DATEPART(YYYY,SYSDATETIME()),'-',DATEPART(MM,SYSDATETIME()),'-01')) AND (RS.ProjDollars >0))
						 THEN ((MC.ProjectedCost * (1+((RS.ProjDollars-CS.ProjectedCost)/RS.ProjDollars)))+((RS.ProjDollars) - (JE.JTDEarnedRev) - (((1+((RS.ProjDollars-CS.ProjectedCost)/RS.ProjDollars)) * FC.ProjectedCost))))
				WHEN (RS.ProjDollars >0) THEN (MC.ProjectedCost * (1+((RS.ProjDollars-CS.ProjectedCost)/RS.ProjDollars)))
				ELSE 0 END AS*/ JE.JTDGMPerc AS 'Adjusted Monthly Revenue'
FROM HQCO HQ With (Nolock)
		INNER JOIN JCCM CM With (Nolock)
			ON HQ.HQCo = CM.JCCo
			AND CM.JCCo = @JCCo
		--INNER JOIN JCCI CI With (Nolock)
		--	ON CM.JCCo = CI.JCCo
		--	AND CM.Contract = CI.Contract
		--	AND CI.Item = JP.Item
		INNER JOIN MonthlyCost MC  With (Nolock)
			ON HQ.HQCo = MC.JCCo
			AND CM.Contract = MC.Contract
		INNER JOIN FutureCost FC With (Nolock)
			ON MC.JCCo = FC.JCCo
			AND MC.Contract = FC.Contract
			AND MC.udPRGNumber = FC.udPRGNumber
			AND MC.Department = FC.Department
		INNER JOIN Rev_Sum RS With (Nolock)
			ON MC.JCCo = RS.JCCo
			AND MC.Contract = RS.Contract
			AND MC.udPRGNumber = RS.udPRGNumber
			AND MC.Department = RS.Department
		INNER JOIN Cost_Sum  CS With (Nolock)
			ON MC.JCCo = CS.JCCo
			AND MC.Contract = CS.Contract
			AND MC.udPRGNumber = CS.udPRGNumber
			AND MC.Department = CS.Department
		INNER JOIN JTD_Earn  JE With (Nolock)
			ON MC.JCCo = JE.JCCo
			AND LTRIM(MC.Contract) = JE.Contract
			AND MC.udPRGNumber = JE.udPRGNumber
			AND MC.Department = JE.Department
		INNER JOIN Margin_Calc GIN
			ON MC.JCCo = GIN.JCCo 
			AND MC.Contract = GIN.Contract 
			AND MC.udPRGNumber = GIN.udPRGNumber
			AND MC.Department = GIN.Department
		LEFT OUTER JOIN	JCMP MP_POC  With (Nolock)
			ON CM.JCCo = MP_POC.JCCo
			AND CM.udPOC = MP_POC.ProjectMgr 
		--LEFT OUTER JOIN	JCMP MP 
		--	ON CM.JCCo = MP.JCCo
		--	AND J.ProjectMgr = MP.ProjectMgr 
		LEFT OUTER JOIN	JCDM DM With (Nolock)
			ON CM.JCCo = DM.JCCo
			AND MC.Department = DM.Department 
WHERE MC.ProjectedCost <> 0
	AND MC.ProjectionMonth >=  CONCAT(DATEPART(YYYY,SYSDATETIME()),'-',DATEPART(MM,SYSDATETIME()),'-01') 
	AND MC.JCCo =  @JCCo
	AND ((MC.Department IS NOT NULL) AND ((@Dept IS NULL) OR (MC.Department = @Dept)))
	AND CM.Contract = ISNULL(@Contract, CM.Contract)
	AND MC.udPRGNumber = ISNULL(@Project, MC.udPRGNumber) 
	--AND ((CM.Contract  LIKE ('%' + coalesce((@Contract),'') + '%')) OR (@Contract IS NULL))
	--AND ((MC.udPRGNumber LIKE ('%' + coalesce((@Project),'') + '%')) OR (@Project IS NULL)) 
	AND ((@POC_MP IS NULL)
			OR (UPPER(MP_POC.Name) LIKE ('%' + coalesce(UPPER(@POC_MP),'') + '%'))
			/*OR (UPPER(MP.Name) LIKE ('%' + coalesce(UPPER(@POC_MP),'') + '%'))*/) 
	AND ( (@StartMth IS NULL)
			OR ( (CAST((SUBSTRING(@StartMth,1,2)) AS INT)<=(DATEPART(MONTH, MC.ProjectionMonth))) 
					AND (CAST((SUBSTRING(@StartMth,4,4)) AS INT)=(DATEPART(YEAR, MC.ProjectionMonth))))
			OR (CAST((SUBSTRING(@StartMth,4,4)) AS INT)<(DATEPART(YEAR, MC.ProjectionMonth))))
	AND ( (@EndMth IS NULL)
			OR ( (CAST((SUBSTRING(@EndMth,1,2)) AS INT)>=(DATEPART(MONTH, MC.ProjectionMonth))) 
					AND (CAST((SUBSTRING(@EndMth,4,4)) AS INT)=(DATEPART(YEAR, MC.ProjectionMonth))))
			OR (CAST((SUBSTRING(@EndMth,4,4)) AS INT)>(DATEPART(YEAR, MC.ProjectionMonth))))

GO

Grant SELECT ON mers.mckfnRevForecastReport TO [MCKINSTRY\Viewpoint Users]