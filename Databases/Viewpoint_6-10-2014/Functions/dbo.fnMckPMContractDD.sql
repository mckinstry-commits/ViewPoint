SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- **************************************************************
--  PURPOSE: Fetches records for PM Contract Drilldown report
--    INPUT: Values list (see below)
--   RETURN: Table
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    03/20/2014  Created function
--    03/20/2014  Tested function
-- **************************************************************

CREATE FUNCTION [dbo].[fnMckPMContractDD]
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
		 HQCO.HQCo, 
		 HQCO.Name AS HQCOName, 
		 PMOI.PMCo, 
		 PMOI.Contract AS PMOIContract, 
		 PMOI.ContractItem, 
		 JCCM.Description AS JCCMDescription, 
		 JCCI.Item, 
		 JCCI.Description  AS JCCIDescription, 
		 JCCM.Customer, 
		 JCCM.ContractAmt AS JCCMContractAmt, 
		 JCCM.BilledAmt AS JCCMBilledAmt, 
		 JCCM.OrigContractAmt, 
		 ARCM.Name AS ARCMName, 
		 JCCI.ContractAmt AS JCCIContractAmt, 
		 JCCI.BilledAmt AS JCCIBilledAmt, 
		 JCCI.UM, 
		 JCCI.UnitPrice, 
		 JCCI.OrigContractUnits, 
		 JCCI.BillType, 
		 PMOI.ACO, 
		 PMOI.ACOItem, 
		 PMOI.PCOType, 
		 PMOI.Status, 
		 PMCO.FinalStatus, 
		 PMSC.CodeType, 
		 PMOI.PCO, 
		 PMOI.PCOItem, 
		 PMOI.Description AS PMOIDescription, 
		 PMOI.Units, 
		 PMOI.ApprovedAmt, 
		 PMOI.PendingAmount, 
		 JCCI.JCCo, 
		 JCCI.Contract AS JCCIContract, 
		 JCMP.Name, 
		 PMOI.Project, 
		 JCMP.ProjectMgr, 
		 PMOI.FixedAmountYN, 
		 PMOI.FixedAmount
	 FROM   
		(((((((dbo.JCCI JCCI LEFT OUTER JOIN dbo.PMOI PMOI 
		ON ((JCCI.JCCo = PMOI.PMCo) AND (JCCI.Contract = PMOI.Contract)) AND (JCCI.Item = PMOI.ContractItem)) 
		LEFT OUTER JOIN dbo.JCCM JCCM ON (JCCI.JCCo = JCCM.JCCo) AND (JCCI.Contract = JCCM.Contract)) 
		INNER JOIN dbo.HQCO HQCO ON JCCI.JCCo = HQCO.HQCo))
		--INNER JOIN dbo.brvJCContrMinJob brvJCContrMinJob ON (JCCI.JCCo = brvJCContrMinJob.JCCo) AND (JCCI.Contract = brvJCContrMinJob.Contract)) 
		LEFT OUTER JOIN dbo.JCMP JCMP ON (JCCM.JCCo = JCMP.JCCo) AND (JCCM.udPOC = JCMP.ProjectMgr)) 
		LEFT OUTER JOIN dbo.PMCO PMCO ON PMOI.PMCo = PMCO.PMCo) 
		LEFT OUTER JOIN dbo.PMSC PMSC ON PMOI.Status = PMSC.Status) 
		LEFT OUTER JOIN dbo.ARCM ARCM ON (JCCM.CustGroup = ARCM.CustGroup) AND (JCCM.Customer = ARCM.Customer)
	 WHERE  
		JCCI.JCCo = @Company AND (JCCI.Contract >= @BeginningContract AND JCCI.Contract <= @EndingContract)
		--ORDER BY JCCI.JCCo, JCCI.Contract, JCCI.Item
		-- remove duplicated key data from columns
)
      
GO
