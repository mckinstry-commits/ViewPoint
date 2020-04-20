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

CREATE FUNCTION [dbo].[fnPMContractDDChangedOrder]
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
	PMOI.PMCo AS PMOICompany
	,PMOI.Contract AS PMOIContract
	,PMOI.ContractItem AS PMOIContractItem
	,PMOI.Description AS PMOIDescription
	,PMOI.ACO AS PMOIACO
	,PMOI.ACOItem AS PMOIACOItem
	,PMOI.Units AS PMOIUnits
	,PMOI.ApprovedAmt AS PMOIApprovedAmt
	,PMOI.PCO AS PMOIPCO
	,PMOI.PCOType AS PMOIPCOType
	,PMOI.Status AS PMOIStatus
	,ISNULL(CASE WHEN PMOI.FixedAmountYN = 'Y' THEN PMOI.FixedAmount ELSE PMOI.PendingAmount END, 0) AS PCOPendingAmount
	, OHT.ACORevTotal, OHT.ACOPhaseCost
	, AOH.Description AS ACOHeaderDescription
	, AOH.ApprovalDate
	, OP.Description AS PCOHeaderDescription
	 FROM   
		dbo.PMOI PMOI
		LEFT OUTER JOIN dbo.PMOL ON (PMOI.PMCo = PMOL.PMCo) AND (PMOI.Project = PMOL.Project) AND (PMOI.ACO = PMOL.ACO) AND (PMOI.ACOItem = PMOL.ACOItem)
		INNER JOIN dbo.PMOHTotals OHT ON OHT.PMCo = PMOI.PMCo AND OHT.ACO = PMOI.ACO
		LEFT OUTER JOIN dbo.PMOH AOH ON PMOI.PMCo = AOH.PMCo AND PMOI.ACO = AOH.ACO
		LEFT OUTER JOIN dbo.PMOP OP ON OP.PMCo = PMOI.PMCo AND OP.PCO = PMOI.PCO AND OP.PCOType = PMOI.PCOType
	 WHERE  
		PMOI.PMCo = @Company AND (PMOI.Contract >= @BeginningContract AND PMOI.Contract <= @EndingContract) AND  PMOI.InterfacedDate IS NOT NULL  
)
      
GO
