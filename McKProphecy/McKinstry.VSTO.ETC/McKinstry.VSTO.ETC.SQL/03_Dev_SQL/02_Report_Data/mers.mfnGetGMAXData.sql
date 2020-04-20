USE [Viewpoint]
GO
/****** Object:  UserDefinedFunction [dbo].[mfnGetGMAXData]    Script Date: 5/18/2017 4:03:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER function [dbo].[mfnGetGMAXData]
(
	@JCCo		bCompany
,   @Job		bJob
)
-- ========================================================================
-- dbo.mfnGetGMAXData
-- Author:	Ziebell, Jonathan
-- Create date: 08/23/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC----------
--				J.Ziebell   10/3/16	   Change to use Job based Record
--				J.Ziebell   11/15/2016 Include Addtional Numbers
--				J.Ziebell   03/02/2017 DBO and 2 new Cost Fields
--              J.Ziebell   05/18/2017 Add new Standard Rate fields
--              J.Ziebell   05/26/2017 Added Equip Cost
--				J.Ziebell	06/05/2017 Date from udJobGMAX
-- ========================================================================
RETURNS TABLE
AS 
RETURN 
	WITH JCCP_Cost 
				( JCCo
				, Job
				, ProjCost
				, ProjHours
				, ProjNonLCost
				, EquipCost
				)
		AS (SELECT
				  CP.JCCo
				, CP.Job 
				, SUM(CP.ProjCost)
				, SUM(CP.ProjHours) AS ProjHours
				, SUM(CASE WHEN CP.CostType <> 1 THEN CP.ProjCost ELSE 0 END) AS ProjNonLCost
				, SUM(CASE WHEN CP.CostType = 5 THEN CP.ProjCost ELSE 0 END) AS EquipCost
			FROM JCCP CP
			WHERE CP.JCCo = @JCCo
				AND CP.Job = @Job
			GROUP BY CP.JCCo
				, CP.Job),
	Shop_HRS 
				( JCCo
				, Job
				, ProjHours
				)
		AS (SELECT
				  CP.JCCo
				, CP.Job 
				, SUM(CP.ProjHours)
			FROM JCCP CP
			INNER JOIN JCPM PM
					ON CP.PhaseGroup = PM.PhaseGroup
					AND SUBSTRING(CP.Phase,1,10) = SUBSTRING(PM.Phase,1,10)
			WHERE CP.JCCo = @JCCo
				AND CP.Job = @Job
				AND CP.CostType=1
				AND PM.udParentPhase in ('9000-0000-      - ','9200-0000-      - ','9300-0000-      - '
										,'9500-0000-      - ','9600-0000-      - ','9700-0000-      - ')
			GROUP BY CP.JCCo
				, CP.Job),
	Staff_HRS 
				( JCCo
				, Job
				, ProjHours
				)
		AS (SELECT
				  CP.JCCo
				, CP.Job 
				, SUM(CP.ProjHours)
			FROM JCCP CP
			WHERE CP.JCCo = @JCCo
				AND CP.Job = @Job
				AND CP.CostType=1
				AND CP.Phase Between '0131-0000-      -   ' and '0131-1620-      -   '
			GROUP BY CP.JCCo
				, CP.Job),
	Labor_HRS
				( JCCo
				, Job
				, ProjHours
				, ProjCost
				)
		AS (SELECT
				  CP.JCCo
				, CP.Job 
				, SUM(CP.ProjHours)
				, SUM(CP.ProjCost)
			FROM JCCP CP
			WHERE CP.JCCo = @JCCo
				AND CP.Job = @Job
				AND CP.CostType=1
			GROUP BY CP.JCCo
				, CP.Job),
	Bond_CST 
				( JCCo
				, Job
				, ProjCost
				)
		AS (SELECT
				  CP.JCCo
				, CP.Job 
				, SUM(CP.ProjCost)
			FROM JCCP CP
			WHERE CP.JCCo = @JCCo
				AND CP.Job = @Job
				AND CP.CostType<>1
				AND CP.Phase IN ('0100-0850-      -   ','0100-0860-      -   ')
			GROUP BY CP.JCCo
				, CP.Job)
	, 	SmallT_CST 
				( JCCo
				, Job
				, ProjCost
				)
		AS (SELECT
				  CP.JCCo
				, CP.Job 
				, SUM(CP.ProjCost)
			FROM JCCP CP
			WHERE CP.JCCo = @JCCo
				AND CP.Job = @Job
				AND CP.CostType<>1
				AND CP.Phase = '0100-0210-      -   '
			GROUP BY CP.JCCo
				, CP.Job)
	, JCID_Sum 
				( JCCo
				, Job
				, ProjDollars
				)
		AS (SELECT
				  CI.JCCo
				, CI.udPRGNumber
				, SUM(ID.ProjDollars)
			FROM JCCI CI 
				INNER JOIN JCID ID
					ON CI.JCCo = ID.JCCo
					AND CI.Contract = ID.Contract
					AND CI.Item = ID.Item
					AND CI.udPRGNumber = @Job
					AND CI.JCCo = @JCCo
			GROUP BY CI.JCCo
				, CI.udPRGNumber
				)
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
	, Labor.ProjCost AS ProjLabrCost
	, Labor.ProjHours
	, C.ProjNonLCost
	, C.ProjCost
	, C.EquipCost
	, ID.ProjDollars AS ProjRev
	, Shop.ProjHours AS Shop_HRS
	, Staff.ProjHours AS Staff_HRS
	, (Labor.ProjHours - Shop.ProjHours - Staff.ProjHours) AS Field_HRS
	, Bond.ProjCost AS Bond_CST
	, ST.ProjCost AS SmallTools_CST
	, CASE WHEN (J.udGMAXYN = 'Y') THEN 'Y' ELSE 'N' END AS 'GMAX'
	, G.Assumptions
	, BR.StaffLabor
	, BR.UnionLabor
	, BR.ShopLabor
FROM udJobGMAX G
	INNER JOIN HQCO HQ
		ON G.Co = HQ.HQCo
		AND ((HQ.udTESTCo <>'Y') OR (HQ.udTESTCo IS NULL))
	INNER JOIN JCCP_Cost C
		ON G.Co = C.JCCo
		AND G.Job = C.Job
	INNER JOIN JCJM J
		ON G.Co = J.JCCo
		AND G.Job = J.Job
	INNER JOIN mckStanBurdenRates BR
		ON BR.EffectiveDate = (SELECT MAX(BR1.EffectiveDate) from mckStanBurdenRates BR1)
	LEFT OUTER JOIN Shop_HRS Shop
		ON G.Co = Shop.JCCo
		AND G.Job = Shop.Job
	LEFT OUTER JOIN Staff_HRS Staff
		ON G.Co = Staff.JCCo
		AND G.Job = Staff.Job
	LEFT OUTER JOIN Labor_HRS Labor
		ON G.Co = Labor.JCCo
		AND G.Job = Labor.Job
	LEFT OUTER JOIN Bond_CST Bond
		ON G.Co = Bond.JCCo
		AND G.Job = Bond.Job
	LEFT OUTER JOIN SmallT_CST ST
		ON G.Co = ST.JCCo
		AND G.Job = ST.Job
	LEFT OUTER JOIN JCID_Sum ID
		ON G.Co = ID.JCCo
		AND G.Job = ID.Job
WHERE G.Date = (SELECT MAX(G1.Date) from udJobGMAX G1
					WHERE G.Co = G1.Co
					AND G.Job = G1.Job)
	AND G.Co = @JCCo
	AND G.Job = @Job

