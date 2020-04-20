use ViewpointProphecy
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnGetRevProjBatch' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnGetRevProjBatch'
	DROP FUNCTION mers.mfnGetRevProjBatch
end
go

print 'CREATE PROCEDURE mers.mfnGetRevProjBatch'
go

CREATE function [mers].[mfnGetRevProjBatch]
(
	@JCCo				bCompany
,	@Contract			bJob
,	@ProjectionMonth	bMonth
)
-- ========================================================================
-- mfnGetRevProjBatch
-- Author:		Ziebell, Jonathan
-- Create date: 07/25/2016
-- Description:	Select SUM of projection values by Project Phase and Cost Type
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================

RETURNS TABLE
AS 
RETURN 
SELECT 
	  I.udPRGNumber AS PRG
	, I.udPRGDescription AS 'PRG Description'
	, I.Department AS 'JC Dept'
	, DM.Description AS 'JC Dept Description'
	, I.Item AS 'Contract Item'
	, I.Description AS 'Contract Item Description'
	, T.CurrentContract AS 'Current Contract'
	, T.FutureAmount AS 'Future CO'
	, (R.RevProjDollars - T.CurrentContract) AS 'Projected Changes'
	, R.PrevRevProjDollars AS 'Previous Projected CV'
	, 'CALCME' AS 'Projected CV'
	, T.ProjCost AS 'Posted Projected Cost'
	, T.ProjCost AS 'Projected Cost'
	, 'CALCME' AS 'Projected CI Margin'
FROM JCCI I
	INNER JOIN JCIR	R
		ON I.JCCo = R.Co
		AND I.Contract=R.Contract
		AND I.Item = R.Item
		AND I.JCCo = @JCCo
		AND I.Contract = @Contract
		AND R.Mth = @ProjectionMonth
	INNER JOIN JCDM DM
		ON I.Department = DM.Department
		AND I.JCCo = DM.JCCo
	INNER JOIN JCIRTotals T
		ON I.JCCo = T.Co
		AND I.Contract = T.Contract
		AND I.Item = T.Item

GO