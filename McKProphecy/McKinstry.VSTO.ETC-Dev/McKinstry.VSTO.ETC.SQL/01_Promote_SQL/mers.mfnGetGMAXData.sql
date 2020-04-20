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
,   @Job		bJob
)
-- ========================================================================
-- mers.mfnGetGMAXData
-- Author:	Ziebell, Jonathan
-- Create date: 08/23/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC----------
--				J.Ziebell   10/3/16	   Change to use Job based Record
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
	  G.Co AS JCCo
	, G.Job
	, G.ActualStaffBurden
	, G.ContractActualFieldBurden
	, G.ContractShopBurden
	, G.BaseFee
	, G.BandO
	, G.GLI
	, G.SmallTools
	, G.Warranty
	, G.Bond
	, G.StaffLaborTaxableBase AS TB_Staff
	, G.FieldLaborTaxableBase AS TB_Field
	, G.ShopLaborTaxableBase AS TB_Shop
	, G.FieldLaborAvgUnionFringe AS UF_Field
	, G.ShopLaborAvgUnionFringe AS UF_Shop
	, C.ProjCost
	, C.ProjHours
FROM udJobGMAX G
	INNER JOIN HQCO HQ
		ON G.Co = HQ.HQCo
		AND ((HQ.udTESTCo <>'Y') OR (HQ.udTESTCo IS NULL))
	INNER JOIN JCCP_Cost C
		ON G.Co = C.JCCo
		AND G.Job = C.Job
WHERE G.Co = @JCCo
	AND G.Job = @Job

GO

Grant SELECT ON mers.mfnGetGMAXData TO [MCKINSTRY\Viewpoint Users]