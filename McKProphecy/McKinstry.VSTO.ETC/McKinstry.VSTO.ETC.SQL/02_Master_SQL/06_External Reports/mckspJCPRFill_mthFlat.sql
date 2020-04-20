use Viewpoint
go

--if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckspJCPRFill_mthFlat' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
--begin
--	print 'DROP PROCEDURE dbo.mckspJCPRFill_mthFlat'
--	DROP PROCEDURE dbo.mckspJCPRFill_mthFlat
--end
--go

--print 'CREATE PROCEDURE dbo.mckspJCPRFill_mthFlat'
--go

ALTER PROCEDURE [dbo].[mckspJCPRFill_mthFlat]
(
	@Fill		VARCHAR(3) 
--,	@Contract	bContract
)
as
-- ========================================================================/1
-- Object Name: dbo.mckspJCPRFill_mthFlat
-- Author:		Ziebell, Jonathan
-- Create date: 04/10/2017
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	04/10/2017 Initial Build
--				J.Ziebell   04/28/2017 Spearate NEW and OLD Builds			
--				J.Ziebell	01/25/2018 Fix Old Detail pulling in on cleared out jobs.	
--				J.Ziebell	02/01/2018 Drop old Months off Monthly Cost Data
-- ========================================================================

DECLARE	@LockMth Date
		, @FirstMonth Date
		, @BackMonth Date

SELECT @LockMth = LastMthSubClsd from dbo.GLCO where GLCo = 1
SET @FirstMonth = DATEADD(MONTH,1,@LockMth)
--SET @BackMonth = DATEADD(MONTH,-1,@LockMth)

SET NOCOUNT ON 
If @Fill = 'ALL'
	TRUNCATE TABLE mckJCPRMthFlat
IF @Fill = 'NEW'
	DELETE FROM mckJCPRMthFlat WHERE EffectMth=@FirstMonth
IF @Fill = 'OLD'	
	DELETE FROM mckJCPRMthFlat WHERE EffectMth=@LockMth
SET NOCOUNT OFF

IF @Fill IN ('ALL','NEW')
	BEGIN
		/* Insert the Current First Open Month Data into the table */
		INSERT INTO mckJCPRMthFlat 
		SELECT			  JM.JCCo
						, CI.Contract
						--, CI.Department
						, DM.udGLDept
						, CI.udPRGNumber
						, CI.udPRGDescription
						, @FirstMonth
						, PR.Mth
						, PR.DetMth
						, WIP.ProjFinalGMPerc AS ProjGMP
						, 0 as TotalRev	
						, SUM(PR.Amount) AS TotalCost 
						, SUM(PR.Hours) AS TotalHours
						, SUM(CASE WHEN PR.CostType=1 THEN PR.Amount ELSE 0 END) AS LabCost
						, SUM(CASE WHEN PR.CostType=2 THEN PR.Amount ELSE 0 END) AS MatCost
						, SUM(CASE WHEN PR.CostType=3 THEN PR.Amount ELSE 0 END) AS SubCost
						, SUM(CASE WHEN PR.CostType=4 THEN PR.Amount ELSE 0 END) AS OthCost
						, SUM(CASE WHEN PR.CostType=5 THEN PR.Amount ELSE 0 END) AS EqpCost
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
						AND PR.DetMth >= @FirstMonth
						AND PR.Mth >= (SELECT MAX(CP1.Mth) FROM JCCP CP1
											WHERE CP1.JCCo = PR.JCCo  
												AND CP1.Job = PR.Job
												AND ((CP1.ProjHours <>0) OR (CP1.ProjCost <>0)))
						AND PR.Mth = (SELECT MAX(PR1.Mth) FROM JCPR PR1 With (Nolock)
											WHERE PR1.JCCo = PR.JCCo 
												AND PR1.Job = PR.Job
												AND PR1.Mth <=@FirstMonth)
					INNER JOIN JCCI CI With (Nolock)
						ON 	JM.JCCo = CI.JCCo
						AND JP.Contract = CI.Contract
						AND JP.Item = CI.Item
					LEFT OUTER JOIN	JCDM DM With (Nolock)
						ON CI.JCCo = DM.JCCo
						AND CI.Department = DM.Department 
					LEFT OUTER JOIN mckWipArchiveJC3 WIP With (Nolock)
						ON JM.JCCo = WIP.JCCo
						AND LTRIM(CI.Contract) = WIP.Contract
						AND CI.udPRGNumber = WIP.PRGNumber
						AND DM.udGLDept = WIP.GLDepartment
						AND WIP.ThroughMonth =  @FirstMonth
					WHERE ((PR.Hours <> 0) OR (PR.Amount<>0))
					AND JM.JCCo <>222
						--AND JM.Contract = ISNULL(@Contract,JM.Contract)
						--AND ((CI.Department IS NOT NULL) AND ((@Dept IS NULL) OR (CI.Department = @Dept)))
						--AND CI.Department = ISNULL(@Dept, CI.Department)
						--AND CI.udPRGNumber = ISNULL(@Project, CI.udPRGNumber)
						--AND JM.JobStatus < 2
					GROUP BY  JM.JCCo
							, CI.Contract
							, DM.udGLDept
							, CI.udPRGNumber
							, CI.udPRGDescription
							, PR.Mth
							, PR.DetMth
							, WIP.ProjFinalGMPerc
	END
IF @Fill IN ('ALL','OLD')
	BEGIN
		/* Insert the Current First Open Month Data into the table */
		INSERT INTO mckJCPRMthFlat 
			SELECT			  JM.JCCo
						, CI.Contract
						--, CI.Department
						, DM.udGLDept
						, CI.udPRGNumber
						, CI.udPRGDescription
						, @LockMth
						, PR.Mth
						, PR.DetMth
						, WIP.ProjFinalGMPerc AS ProjGMP
						, 0 as TotalRev	
						, SUM(PR.Amount) AS TotalCost 
						, SUM(PR.Hours) AS TotalHours
						, SUM(CASE WHEN PR.CostType=1 THEN PR.Amount ELSE 0 END) AS LabCost
						, SUM(CASE WHEN PR.CostType=2 THEN PR.Amount ELSE 0 END) AS MatCost
						, SUM(CASE WHEN PR.CostType=3 THEN PR.Amount ELSE 0 END) AS SubCost
						, SUM(CASE WHEN PR.CostType=4 THEN PR.Amount ELSE 0 END) AS OthCost
						, SUM(CASE WHEN PR.CostType=5 THEN PR.Amount ELSE 0 END) AS EqpCost
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
						AND PR.DetMth >= @LockMth
						AND PR.Mth >= (SELECT MAX(CP1.Mth) FROM JCCP CP1
											WHERE CP1.JCCo = PR.JCCo  
												AND CP1.Job = PR.Job
												AND ((CP1.ProjHours <>0) OR (CP1.ProjCost <>0)))
						AND PR.Mth = (SELECT MAX(PR1.Mth) FROM JCPR PR1 With (Nolock)
											WHERE PR1.JCCo = PR.JCCo 
											AND PR1.Job = PR.Job
											AND PR1.Mth <=@LockMth)
					INNER JOIN JCCI CI With (Nolock)
						ON 	JM.JCCo = CI.JCCo
						AND JP.Contract = CI.Contract
						AND JP.Item = CI.Item
					LEFT OUTER JOIN	JCDM DM With (Nolock)
						ON CI.JCCo = DM.JCCo
						AND CI.Department = DM.Department 
					LEFT OUTER JOIN mckWipArchiveJC3 WIP With (Nolock)
						ON JM.JCCo = WIP.JCCo
						AND LTRIM(CI.Contract) = WIP.Contract
						AND CI.udPRGNumber = WIP.PRGNumber
						AND DM.udGLDept = WIP.GLDepartment
						AND WIP.ThroughMonth = @LockMth
					WHERE ((PR.Hours <> 0) OR (PR.Amount<>0))
					AND JM.JCCo <>222
						--AND JM.Contract = ISNULL(@Contract,JM.Contract)
						--AND ((CI.Department IS NOT NULL) AND ((@Dept IS NULL) OR (CI.Department = @Dept)))
						--AND CI.Department = ISNULL(@Dept, CI.Department)
						--AND CI.udPRGNumber = ISNULL(@Project, CI.udPRGNumber)
						--AND JM.JobStatus < 2
					GROUP BY  JM.JCCo
							, CI.Contract
							, DM.udGLDept
							, CI.udPRGNumber
							, CI.udPRGDescription
							, PR.Mth
							, PR.DetMth
							, WIP.ProjFinalGMPerc
	END

IF @Fill='ALL'
	BEGIN
		UPDATE mckJCPRMthFlat
		SET TotalRev = CASE WHEN ISNULL(TotalCost,0) = 0 THEN 0
						WHEN (ProjGMP = 1) THEN ISNULL(TotalCost,0) 
						WHEN (ProjGMP <> 0) THEN (TotalCost/(1-ProjGMP)) 
						ELSE ISNULL(TotalCost,0) END 
	END

IF @Fill='NEW'
	BEGIN
		UPDATE mckJCPRMthFlat
		SET TotalRev = CASE WHEN ISNULL(TotalCost,0) = 0 THEN 0
						WHEN (ProjGMP = 1) THEN ISNULL(TotalCost,0) 
						WHEN (ProjGMP <> 0) THEN (TotalCost/(1-ProjGMP)) 
						ELSE ISNULL(TotalCost,0) END
		WHERE EffectMth = @FirstMonth
	END

IF @Fill='OLD'
	BEGIN
		UPDATE mckJCPRMthFlat
		SET TotalRev = CASE WHEN ISNULL(TotalCost,0) = 0 THEN 0
						WHEN (ProjGMP = 1) THEN ISNULL(TotalCost,0) 
						WHEN (ProjGMP <> 0) THEN (TotalCost/(1-ProjGMP)) 
						ELSE ISNULL(TotalCost,0) END
		WHERE EffectMth = @LockMth 
	END


--Grant EXECUTE ON dbo.mckspJCPRFill_mthFlat TO [MCKINSTRY\Viewpoint Users]