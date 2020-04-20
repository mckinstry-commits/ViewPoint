use Viewpoint
Go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractJobCostProjectionDetail' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractJobCostProjectionDetail'
	DROP FUNCTION mers.mfnContractJobCostProjectionDetail
end
go

print 'CREATE FUNCTION mers.mfnContractJobCostProjectionDetail'
go

create function [mers].[mfnContractJobCostProjectionDetail]
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Month		bMonth
,	@Job		bJob
)
returns table as 
-- ========================================================================
-- Object Name: mers.mfnContractJobCostProjectionDetail
-- Author:		BillO
-- Create Date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell   5/23/2016  Change of source procedure to ignore JCCP, and pull Max Detail month only 1 time.
-- ========================================================================
return

WITH MaxDetMth(JCCo	
				, Job	
				, Mth)
	AS (Select PR2.JCCo, PR2.Job, Max(PR2.Mth) from JCPR PR2
					WHERE PR2.JCCo = @JCCo
					and	PR2.Job = @Job
					AND PR2.Mth <= @Month
					GROUP BY PR2.JCCo, PR2.Job)
SELECT
	jccpd.JCCo	
,	jccpd.Job	
,	jccpd.PhaseGroup	
,	jccpd.Phase	
,	jccpd.CostType	
,	jcpr.Mth	
,	jcpr.ResTrans	
,	jcpr.PostedDate	
,	jcpr.ActualDate	
,	jcpr.JCTransType	
,	jcpr.Source	
,	jcpr.BudgetCode	
,	jcpr.EMCo	
,	jcpr.Equipment	
,	jcpr.PRCo	
,	jcpr.Craft	
,	jcpr.Class	
,	jcpr.Employee	
,	jcpr.Description	
,	jcpr.DetMth	
,	jcpr.FromDate	
,	jcpr.ToDate	
,	jcpr.Quantity	
,	jcpr.UM	
,	jcpr.Units	
,	jcpr.UnitHours	
,	jcpr.Hours	
,	jcpr.Rate	
,	jcpr.UnitCost	
,	jcpr.Amount	
,	jcpr.BatchId	
,	jcpr.InUseBatchId	
,	jcpr.Notes	
,	jcpr.UniqueAttchID	
,	jcpr.PMCostProjection	
,	jcpr.ProjectionCode
from
	mers.mfnContractJobPhaseCostTypes(@JCCo,@Contract,@Job) jccpd 
	/*mers.mfnContractJobCostProjectionRaw(@JCCo, @Contract, @Month, @Job) jccpd left outer join */
	LEFT OUTER JOIN (JCPR jcpr 
						INNER JOIN MaxDetMth DetMth
							ON DetMth.JCCo = jcpr.JCCo
							AND DetMth.Job = jcpr.Job
							AND DetMth.Mth = jcpr.Mth)
		ON jccpd.JCCo=jcpr.JCCo
		and	jccpd.Job=jcpr.Job
		and	jccpd.PhaseGroup=jcpr.PhaseGroup
		and	jccpd.Phase=jcpr.Phase
		and	jccpd.CostType=jcpr.CostType
		/*and	jccpd.Mth=jcpr.Mth*/
	/*WHERE (DetMth.Mth = jcpr.Mth) 
		OR (jcpr.Mth IS NULL)*/

GO