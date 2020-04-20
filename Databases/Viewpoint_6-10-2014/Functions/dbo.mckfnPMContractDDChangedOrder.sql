SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- **************************************************************
--  PURPOSE: Fetches changed order detail records for PM Contract Drilldown report
--    INPUT: Values list (see below)
--   RETURN: Table
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    03/20/2014  Created function
--    03/20/2014  Tested function
-- **************************************************************

CREATE FUNCTION [dbo].[mckfnPMContractDDChangedOrder]
(
	 @Company [dbo].[bCompany]
	,@BeginningContract [dbo].[bContract]
	,@EndingContract [dbo].[bContract]  
)

RETURNS TABLE 
AS

RETURN
(
	SELECT 
	ACOPMOI.PMCo AS PMOICompany
	,ACOPMOI.Contract AS PMOIContract
	,ACOPMOI.ContractItem AS PMOIContractItem
	,ACOPMOI.Description AS PMOIDescription
	,ACOPMOI.ACO AS PMOIACO
	,ACOPMOI.ACOItem AS PMOIACOItem
	,ACOPMOI.Units AS PMOIUnits
	,ACOPMOI.ApprovedAmt AS PMOIApprovedAmt
	,ACOPMOI.PCO AS PMOIPCO
	,ACOPMOI.PCOType AS PMOIPCOType
	,ACOPMOI.Status AS PMOIStatus
	,PCOPMOI.PMCo AS PCOPMOICompany
	,PCOPMOI.Contract AS PCOPMOIContract
	,PCOPMOI.ContractItem AS PCOPMOIContractItem
	,PCOPMOI.Description AS PCOPMOIDescription
	,PCOPMOI.ACO AS PCOPMOIACO
	,PCOPMOI.ACOItem AS PCOPMOIACOItem
	,PCOPMOI.Units AS PCOPMOIUnits
	,PCOPMOI.ApprovedAmt AS PCOPMOIApprovedAmt
	,PCOPMOI.PCO AS PCOPMOIPCO
	,PCOPMOI.PCOType AS PCOPMOIPCOType
	,PCOPMOI.Status AS PCOPMOIStatus
	,ISNULL(CASE WHEN ACOPMOI.FixedAmountYN = 'Y' THEN ACOPMOI.FixedAmount ELSE ACOPMOI.PendingAmount END, 0) AS ACOPendingAmount
	,ISNULL(CASE WHEN PCOPMOI.FixedAmountYN = 'Y' THEN PCOPMOI.FixedAmount ELSE PCOPMOI.PendingAmount END, 0) AS PCOPendingAmount
	, OHT.ACORevTotal
	, OHT.ACOPhaseCost
	, PCOOHT.PCORevTotal
	, PCOOHT.PCOPhaseCost
	--, AOH.Description AS ACOHeaderDescription
	--, AOH.ApprovalDate
	--, PCO.Description AS PCOHeaderDescription
	 FROM   
		dbo.PMOI AS ACOPMOI
		LEFT OUTER JOIN dbo.PMOL AS ACOPMOL ON (ACOPMOI.PMCo = ACOPMOL.PMCo) AND (ACOPMOI.Project = ACOPMOL.Project) AND (ACOPMOI.ACO = ACOPMOL.ACO) AND (ACOPMOI.ACOItem = ACOPMOL.ACOItem)
		INNER JOIN dbo.PMOHTotals OHT ON OHT.PMCo = ACOPMOI.PMCo AND OHT.ACO = ACOPMOI.ACO
		LEFT OUTER JOIN dbo.PMOH AOH ON ACOPMOI.PMCo = AOH.PMCo AND ACOPMOI.ACO = AOH.ACO
		--LEFT OUTER JOIN dbo.PMOP OP ON OP.PMCo = ACOPMOI.PMCo AND OP.PCO = ACOPMOI.PCO AND OP.PCOType = ACOPMOI.PCOType

		LEFT OUTER JOIN dbo.PMOI AS PCOPMOI ON (PCOPMOI.PMCo = ACOPMOI.PMCo) AND (PCOPMOI.Project = ACOPMOI.Project) AND (PCOPMOI.ACO = ACOPMOI.ACO) AND (PCOPMOI.ACOItem = ACOPMOI.ACOItem)
		LEFT OUTER JOIN dbo.PMOL AS PCOPMOL ON (PCOPMOI.PMCo = PCOPMOL.PMCo) AND (PCOPMOI.Project = PCOPMOL.Project) AND (PCOPMOI.ACO = PCOPMOL.ACO) AND (PCOPMOI.ACOItem = PCOPMOL.ACOItem)
		LEFT OUTER JOIN dbo.PMOP AS PCO ON (PCO.PMCo = PCOPMOI.PMCo) AND (PCO.Project = PCOPMOI.Project) AND (PCO.PCO = PCOPMOI.PCO)
		INNER JOIN dbo.PMOHTotals PCOOHT ON PCOOHT.PMCo = PCOPMOI.PMCo AND PCOOHT.ACO = PCOPMOI.ACO
		--LEFT OUTER JOIN dbo.PMOH AOH ON PCOPMOI.PMCo = AOH.PMCo AND PCOPMOI.ACO = AOH.ACO
	 WHERE  
		ACOPMOI.PMCo = @Company AND (ACOPMOI.Contract >= @BeginningContract AND ACOPMOI.Contract <= @EndingContract) AND  ACOPMOI.InterfacedDate IS NOT NULL  
		AND PCOPMOI.PMCo = @Company AND (PCOPMOI.Contract >= @BeginningContract AND PCOPMOI.Contract <= @EndingContract) AND  PCOPMOI.InterfacedDate IS NOT NULL  
)
      
GO
