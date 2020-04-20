use ViewpointProphecy
go

--Contract Selector List
if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnGetGMAXData' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnGetGMAXData'
	DROP FUNCTION mers.mfnGetGMAXData
end
go

print 'CREATE FUNCTION mers.mfnGetGMAXData'
go

create function mers.mfnGetGMAXData
(
	@JCCo		bCompany
,	@Contract	bContract
,   @Job		bJob
)
-- ========================================================================
-- mers.mfnGetGMAXData
-- Author:	Ziebell, Jonathan
-- Create date: 08/23/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
RETURNS TABLE
AS 
RETURN 
	WITH JCCP_Cost 
				( JCCo
				, Job
				, ProjCost
				, ProjHours
				)
		AS (SELECT
				  CP.JCCo
				, CP.Job 
				, SUM(CP.ProjCost)
				, SUM(CP.ProjHours)
			FROM JCCP CP
			WHERE CP.JCCo = @JCCo
				AND CP.Job = @Job
			GROUP BY CP.JCCo
				, CP.Job)
SELECT
	  CM.JCCo
	, CM.Contract
	, CM.udActualStaffBurden AS 'StaffBurden'
	, CM.udContractActualFieldBurden AS 'FieldBurden'
	, CM.udContractShopBurden AS 'ShopBurden'
	, CM.udBaseFee AS 'BaseFee'
	, C.ProjCost
	, C.ProjHours
FROM JCCM CM
	INNER JOIN HQCO HQ
		ON CM.JCCo = HQ.HQCo
		AND ((HQ.udTESTCo <>'Y') OR (HQ.udTESTCo IS NULL))
	INNER JOIN JCJM JM
		ON JM.JCCo = CM.JCCo
		AND JM.Contract = CM.Contract
	INNER JOIN JCCP_Cost C
		ON CM.JCCo = C.JCCo
		AND JM.Job = C.Job
WHERE CM.JCCo = @JCCo
	AND CM.Contract = @Contract
	AND JM.Job = @Job

GO
