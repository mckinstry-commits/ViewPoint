use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckspFill_RevFlat' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE dbo.mckspFill_RevFlat'
	DROP PROCEDURE dbo.mckspFill_RevFlat
end
go

print 'CREATE PROCEDURE dbo.mckspFill_RevFlat'
go

CREATE PROCEDURE [dbo].[mckspFill_RevFlat]
(
	@Fill		VARCHAR(3) 
--,	@Contract	bContract
)
as
-- ========================================================================
-- Object Name: dbo.mckspFill_RevFlat
-- Author:		Ziebell, Jonathan
-- Create date: 04/10/2017
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	04/10/2017 Initial Build
--				J.Ziebell   04/28/2017 Spearate NEW and OLD Builds	
--	            J.Ziebell   05/09/2017 Lock Y, Revenue Type
--				J.Ziebell   05/10/2017 Department Fix
--              J.Ziebell   06/06/2017 ProjectedFinal Cost in Absent Future Cost
--				J.Ziebell	06/19/2017 Add RemContractRevenue
-- ========================================================================

DECLARE	@LockMth Date
		, @FirstMonth Date
		, @BackMonth Date

DECLARE	@Future_Cost TABLE
				( JCCo bCompany
				, Contract bContract
				, Department bDept
				, udPRGNumber bJob
				, FutureCost NUMERIC(38,8)
				, CurrMth NUMERIC(38,8)
				)
DECLARE	@Future_Cost_Old TABLE
				( JCCo bCompany
				, Contract bContract
				, Department bDept
				, udPRGNumber bJob
				, FutureCost NUMERIC(38,8)
				, CurrMth NUMERIC(38,8)
				)

DECLARE  @Contract_Rem_Rev TABLE
				( JCCo bCompany
				, Contract bContract
				, RemRevenue NUMERIC(38,8)
				)

SELECT @LockMth = LastMthSubClsd from dbo.GLCO where GLCo = 1
SET @FirstMonth = DATEADD(MONTH,1,@LockMth)
SET @BackMonth = DATEADD(MONTH,-1,@LockMth)


SET NOCOUNT ON 
If @Fill = 'ALL'
	TRUNCATE TABLE mckJCPRRevFlat
IF @Fill = 'NEW'
	DELETE FROM mckJCPRRevFlat WHERE EffectMth=@FirstMonth
IF @Fill = 'OLD'	
	DELETE FROM mckJCPRRevFlat WHERE EffectMth=@LockMth
SET NOCOUNT OFF

BEGIN
INSERT INTO @Contract_Rem_Rev (   JCCo
								, Contract
								, RemRevenue) 
						 (SELECT
							  WIP1.JCCo
							, WIP1.Contract
							, SUM(ISNULL(WIP1.RevenueWIPAmount,0) - ISNULL(WIP1.JTDEarnedRev,0)) AS RemRevenue
							FROM mckWipArchiveJC3 WIP1
								WHERE WIP1.ContractStatus < 2
									AND WIP1.ThroughMonth =  @FirstMonth
									AND WIP1.Contract IS NOT NULL
							GROUP BY
							 WIP1.JCCo
							, WIP1.Contract
							)
END

IF @Fill IN ('ALL','NEW')
	BEGIN
		INSERT INTO @Future_Cost (JCCo, Contract, Department, udPRGNumber, FutureCost, CurrMth)
							SELECT f.JCCo
									, f.Contract
									, f.Department
									, f.udPRGNumber
									, SUM(f.TotalCost) AS 'FutureCost'
									, SUM(CASE WHEN f.Mth = @FirstMonth THEN f.TotalRev ELSE 0 END) AS CurrMth
							FROM dbo.mckJCPRMthFlat f
							WHERE f.Mth >= @FirstMonth
							AND f.EffectMth = @FirstMonth
							GROUP BY JCCo
									, f.Contract
									, f.Department
									, f.udPRGNumber

		INSERT INTO mckJCPRRevFlat
			SELECT CM.JCCo
					, WIP.GLDepartment as Department
					, WIP.GLDepartmentName AS Description
					, WIP.Department as 'JCDept'
					, WIP.RevenueTypeName AS 'RevType'
					, CM.Contract
					, CM.Description AS ContractDesc
					, WIP.PRGNumber AS 'PRG Number'
					, WIP.PRGDescription AS 'PRG Description'
					, @FirstMonth as EffectMth
					, WIP.POC
					, WIP.POCName
					, WIP.ProjectMgrNumber As 'ProjMgr'
					, WIP.ProjectMgrName As 'ProjMgrName'
					, ISNULL(FC.FutureCost,0) AS 'FutureCostTotal'	
					, WIP.RevenueWIPAmount AS RevTotal   
					, WIP.CostWIPAmount AS CostTotal
					, WIP.ProjFinalGMPerc AS ProjGMP
					, CASE WHEN ISNULL(FC.FutureCost,0) = 0 THEN 0
							WHEN (WIP.ProjFinalGMPerc = 1) THEN ISNULL(FC.FutureCost,0) 
							WHEN (WIP.ProjFinalGMPerc <> 0) THEN (FC.FutureCost/(1-WIP.ProjFinalGMPerc)) 
							ELSE ISNULL(FC.FutureCost,0) END AS FutureRevTotal
					, ISNULL(OWIP.JTDEarnedRev,0) 
					, (WIP.RevenueWIPAmount - ISNULL(OWIP.JTDEarnedRev,0)) AS RemainRev
					--, (WIP.ProjContractAmt - OWIP.JTDEarnedRev - 0) AS UnburnRev	
					, CASE WHEN ((ISNULL(WIP.CostWIPAmount,0) = 0) AND (ISNULL(WIP.RevenueWIPAmount,0)=0)) THEN 0
							WHEN ISNULL(FC.FutureCost,0) = 0 THEN (WIP.RevenueWIPAmount - ISNULL(OWIP.JTDEarnedRev,0))
							WHEN (WIP.ProjFinalGMPerc = 1) THEN (WIP.RevenueWIPAmount - ISNULL(OWIP.JTDEarnedRev,0) - ISNULL(FC.FutureCost,0)) 
							WHEN (WIP.ProjFinalGMPerc <> 0) THEN (WIP.RevenueWIPAmount - ISNULL(OWIP.JTDEarnedRev,0) - (FC.FutureCost/(1-WIP.ProjFinalGMPerc))) 
							ELSE (WIP.RevenueWIPAmount - ISNULL(OWIP.JTDEarnedRev,0) - ISNULL(FC.FutureCost,0)) END AS UnburnRev
					, ((WIP.CostWIPAmount - ISNULL(OWIP.JTDActualCost,0)) - ISNULL(FC.FutureCost,0)) AS AbsFutureCost
					--, (OWIP.EstimatedCostToComplete - ISNULL(FC.FutureCost,0)) AS AbsFutureCost
					, CASE WHEN (((WIP.CostWIPAmount - ISNULL(OWIP.JTDActualCost,0)) - ISNULL(FC.FutureCost,0)) = 0) THEN 0
							WHEN (WIP.ProjFinalGMPerc = 1) THEN ((WIP.CostWIPAmount - ISNULL(OWIP.JTDActualCost,0)) - ISNULL(FC.FutureCost,0))
							WHEN (WIP.ProjFinalGMPerc <> 0) THEN (((WIP.CostWIPAmount - ISNULL(OWIP.JTDActualCost,0)) - ISNULL(FC.FutureCost,0))/(1-WIP.ProjFinalGMPerc)) 
							ELSE ((WIP.CostWIPAmount - ISNULL(OWIP.JTDActualCost,0)) - ISNULL(FC.FutureCost,0)) END AS AbsFutureRev
					, (WIP.ProjFinalGMPerc - OWIP.ProjFinalGMPerc) AS MarginChange
					, CASE WHEN ISNULL(OWIP.JTDActualCost,0) = 0 THEN 0
							WHEN ((WIP.ProjFinalGMPerc - OWIP.ProjFinalGMPerc) = 0) THEN 0
							WHEN (WIP.ProjFinalGMPerc = 1) THEN (WIP.RevenueWIPAmount - OWIP.JTDEarnedRev) 
							WHEN (WIP.ProjFinalGMPerc <> 0) THEN ((OWIP.JTDActualCost/(1-WIP.ProjFinalGMPerc))-OWIP.JTDEarnedRev) 
							ELSE (OWIP.JTDActualCost - OWIP.JTDEarnedRev) END AS MarginChgImpact
					--, (x - OWIP.JTDEarnedRev) AS MarginChgImpact
					, FC.CurrMth as AdjCurrentmth
					, RR.RemRevenue
			FROM HQCO HQ With (Nolock)
					INNER JOIN JCCM CM With (Nolock)
						ON HQ.HQCo = CM.JCCo
					INNER JOIN mckWipArchiveJC3 WIP With (Nolock)
						ON CM.JCCo = WIP.JCCo
						AND LTRIM(CM.Contract) = WIP.Contract
						AND WIP.ContractStatus < 2
						AND WIP.ThroughMonth =  @FirstMonth
					LEFT OUTER JOIN @Contract_Rem_Rev RR
						ON WIP.JCCo = RR.JCCo
						AND WIP.Contract = RR.Contract
					LEFT OUTER JOIN mckWipArchiveJC3 OWIP With (Nolock)
						ON WIP.JCCo = OWIP.JCCo
						AND WIP.Contract = OWIP.Contract
						AND WIP.PRGNumber = OWIP.PRGNumber
						AND WIP.GLDepartment = OWIP.GLDepartment
						AND WIP.RevenueType = OWIP.RevenueType
						AND OWIP.ThroughMonth = @LockMth
						AND OWIP.IsLocked = 'Y'
					LEFT OUTER JOIN @Future_Cost FC
						ON WIP.JCCo = FC.JCCo
						AND WIP.Contract = LTRIM(FC.Contract)
						AND WIP.PRGNumber = FC.udPRGNumber
						AND WIP.GLDepartment = FC.Department
					WHERE WIP.GLDepartment IS NOT NULL
						AND WIP.PRGNumber IS NOT NULL
	END

IF @Fill IN ('ALL','OLD')
	BEGIN	
		INSERT INTO @Future_Cost_Old (JCCo, Contract, Department, udPRGNumber, FutureCost, CurrMth)
							SELECT f.JCCo
									, f.Contract
									, f.Department
									, f.udPRGNumber
									, SUM(f.TotalCost) AS 'FutureCost'
									, SUM(CASE WHEN f.Mth = @LockMth THEN f.TotalRev ELSE 0 END) AS CurrMth
							FROM dbo.mckJCPRMthFlat f
							WHERE f.Mth >= @LockMth
							AND f.EffectMth = @LockMth
							AND f.Department IS NOT NULL
							GROUP BY JCCo
									, f.Contract
									, f.Department
									, f.udPRGNumber

		INSERT INTO mckJCPRRevFlat
			SELECT CM.JCCo
					, WIP.GLDepartment as Department
					, WIP.GLDepartmentName AS Description
					, WIP.Department as 'JCDept'
					, WIP.RevenueTypeName AS 'RevType'
					, CM.Contract
					, CM.Description AS ContractDesc
					, WIP.PRGNumber AS 'PRG Number'
					, WIP.PRGDescription AS 'PRG Description'
					, @LockMth as EffectMth
					, WIP.POC
					, WIP.POCName
					, WIP.ProjectMgrNumber As 'ProjMgr'
					, WIP.ProjectMgrName As 'ProjMgrName'
					, ISNULL(FC.FutureCost,0) AS 'FutureCostTotal'	
					, WIP.RevenueWIPAmount AS RevTotal   
					, WIP.CostWIPAmount AS CostTotal
					, WIP.ProjFinalGMPerc AS ProjGMP
					, CASE WHEN ISNULL(FC.FutureCost,0) = 0 THEN 0
							WHEN (WIP.ProjFinalGMPerc = 1) THEN ISNULL(FC.FutureCost,0) 
							WHEN (WIP.ProjFinalGMPerc <> 0) THEN (FC.FutureCost/(1-WIP.ProjFinalGMPerc)) 
							ELSE ISNULL(FC.FutureCost,0) END AS FutureRevTotal
					, ISNULL(OWIP.JTDEarnedRev,0) 
					, (WIP.RevenueWIPAmount - ISNULL(OWIP.JTDEarnedRev,0)) AS RemainRev
					--, (WIP.ProjContractAmt - OWIP.JTDEarnedRev - 0) AS UnburnRev	
					, CASE WHEN ((ISNULL(WIP.CostWIPAmount,0) = 0) AND (ISNULL(WIP.RevenueWIPAmount,0)=0)) THEN 0
							WHEN ISNULL(FC.FutureCost,0) = 0 THEN (WIP.RevenueWIPAmount - ISNULL(OWIP.JTDEarnedRev,0))
							WHEN (WIP.ProjFinalGMPerc = 1) THEN (WIP.RevenueWIPAmount - ISNULL(OWIP.JTDEarnedRev,0) - ISNULL(FC.FutureCost,0)) 
							WHEN (WIP.ProjFinalGMPerc <> 0) THEN (WIP.RevenueWIPAmount - ISNULL(OWIP.JTDEarnedRev,0) - (FC.FutureCost/(1-WIP.ProjFinalGMPerc))) 
							ELSE (WIP.RevenueWIPAmount - ISNULL(OWIP.JTDEarnedRev,0) - ISNULL(FC.FutureCost,0)) END AS UnburnRev
					, ((WIP.CostWIPAmount - ISNULL(OWIP.JTDActualCost,0)) - ISNULL(FC.FutureCost,0)) AS AbsFutureCost
					--, (OWIP.EstimatedCostToComplete - ISNULL(FC.FutureCost,0)) AS AbsFutureCost
					, CASE WHEN (((WIP.CostWIPAmount - ISNULL(OWIP.JTDActualCost,0)) - ISNULL(FC.FutureCost,0)) = 0) THEN 0
							WHEN (WIP.ProjFinalGMPerc = 1) THEN ((WIP.CostWIPAmount - ISNULL(OWIP.JTDActualCost,0)) - ISNULL(FC.FutureCost,0))
							WHEN (WIP.ProjFinalGMPerc <> 0) THEN (((WIP.CostWIPAmount - ISNULL(OWIP.JTDActualCost,0)) - ISNULL(FC.FutureCost,0))/(1-WIP.ProjFinalGMPerc)) 
							ELSE ((WIP.CostWIPAmount - ISNULL(OWIP.JTDActualCost,0)) - ISNULL(FC.FutureCost,0)) END AS AbsFutureRev
					, (WIP.ProjFinalGMPerc - OWIP.ProjFinalGMPerc) AS MarginChange
					, CASE WHEN ISNULL(OWIP.JTDActualCost,0) = 0 THEN 0
							WHEN ((WIP.ProjFinalGMPerc - OWIP.ProjFinalGMPerc) = 0) THEN 0
							WHEN (WIP.ProjFinalGMPerc = 1) THEN (WIP.RevenueWIPAmount - OWIP.JTDEarnedRev) 
							WHEN (WIP.ProjFinalGMPerc <> 0) THEN ((OWIP.JTDActualCost/(1-WIP.ProjFinalGMPerc))-OWIP.JTDEarnedRev) 
							ELSE (OWIP.JTDActualCost - OWIP.JTDEarnedRev) END AS MarginChgImpact
					--, (x - OWIP.JTDEarnedRev) AS MarginChgImpact
					, FC.CurrMth as AdjCurrentmth
					, RR.RemRevenue
			FROM HQCO HQ With (Nolock)
					INNER JOIN JCCM CM With (Nolock)
						ON HQ.HQCo = CM.JCCo
					INNER JOIN mckWipArchiveJC3 WIP With (Nolock)
						ON CM.JCCo = WIP.JCCo
						AND LTRIM(CM.Contract) = WIP.Contract
						AND WIP.ContractStatus < 2
						AND WIP.ThroughMonth =  @LockMth
						AND WIP.IsLocked = 'Y'
					LEFT OUTER JOIN @Contract_Rem_Rev RR
						ON CM.JCCo = RR.JCCo
						AND LTRIM(CM.Contract) = RR.Contract
					LEFT OUTER JOIN mckWipArchiveJC3 OWIP With (Nolock)
						ON WIP.JCCo = OWIP.JCCo
						AND WIP.Contract = OWIP.Contract
						AND WIP.PRGNumber = OWIP.PRGNumber
						AND WIP.GLDepartment = OWIP.GLDepartment
						AND WIP.RevenueType = OWIP.RevenueType
						AND OWIP.ThroughMonth = @BackMonth
						AND OWIP.IsLocked = 'Y'
					LEFT OUTER JOIN @Future_Cost_Old FC
						ON WIP.JCCo = FC.JCCo
						AND WIP.Contract = LTRIM(FC.Contract)
						AND WIP.PRGNumber = FC.udPRGNumber
						AND WIP.GLDepartment = FC.Department
					WHERE WIP.GLDepartment IS NOT NULL
						AND WIP.PRGNumber IS NOT NULL
	END

GO

Grant EXECUTE ON dbo.mckspFill_RevFlat TO [MCKINSTRY\Viewpoint Users]