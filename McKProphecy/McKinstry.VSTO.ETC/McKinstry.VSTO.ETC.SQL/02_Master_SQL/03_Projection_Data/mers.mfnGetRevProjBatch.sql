use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnGetRevProjBatch' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION dbo.mfnGetRevProjBatch'
	DROP FUNCTION dbo.mfnGetRevProjBatch
end
go

print 'CREATE PROCEDURE dbo.mfnGetRevProjBatch'
go

CREATE function [dbo].[mfnGetRevProjBatch]
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
--				J.Ziebell   8/18/2016  Column Header Change
--				J.Ziebell   2/13/2017  Send 0 Values instead of Null, CALCME
--				J.Ziebell  10/29/2017  Select Notes Field
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
	, I.Description AS 'Description'
	, T.FutureAmount AS 'Future CO'
	, (R.RevProjDollars - T.CurrentContract) AS 'Unbooked Contract Adjustment'
	, T.CurrentContract AS 'Current Contract'
	, R.PrevRevProjDollars AS 'Previous Projected Contract'
	, CAST(0 AS DECIMAL) AS 'Projected Contract'
	, T.ProjCost AS 'Posted Projected Cost'
	, ISNULL(T.ProjCost,0) AS 'Margin Seek'
	, 0 AS 'Projected Contract Item Margin %'
	, I.ProjNotes AS 'Notes'
FROM JCCI I
	INNER JOIN HQCO HQ
		ON I.JCCo = HQ.HQCo
		AND ((HQ.udTESTCo ='N') OR (HQ.udTESTCo IS NULL))
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


Grant SELECT ON dbo.mfnGetRevProjBatch TO [MCKINSTRY\Viewpoint Users]