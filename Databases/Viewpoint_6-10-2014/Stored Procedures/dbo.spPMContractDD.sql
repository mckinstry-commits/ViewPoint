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
--    03/27/2014  Created stored procedure
--    03/27/2014  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[spPMContractDD]
	@Company [dbo].[bCompany]
	,@BeginningContract [dbo].[bContract]
	,@EndingContract [dbo].[bContract]
AS
	SELECT 
		ContractData.JCCMCompany
		,ContractData.JCCMContract
		,ContractData.JCCMDescription
		,ContractData.JCCMCustomer
		,ContractData.ARCMName
		,ContractData.JCCMOrigContractAmt
		,ContractData.JCCMContractAmt
		,ContractData.JCCMBilledAmt
		,ContractData.JCMPProjectManagerName
		,ItemData.JCCICompany
		,ItemData.JCCIContract
		,ItemData.JCCIItem
		,ItemData.JCCIDescription
		,ItemData.JCCIBillType
		,ItemData.JCCIUM
		,ItemData.JCCIOrigContractUnits
		,ItemData.JCCIUnitPrice
		,ItemData.JCCIOrigContractAmt
		,ItemData.JCCIContractAmt
		,ItemData.JCCIBilledAmt
		,ChangedOrderData.PMOICompany
		,ChangedOrderData.PMOIContract
		,ChangedOrderData.PMOIContractItem
		,ChangedOrderData.PMOIDescription
		,ChangedOrderData.PMOIACO
		,ChangedOrderData.PMOIACOItem
		,ChangedOrderData.PMOIUnits
		,ChangedOrderData.PMOIApprovedAmt
		,ChangedOrderData.PMOIPCO
		,ChangedOrderData.PMOIPCOType
		,ChangedOrderData.PMOIStatus
		,ChangedOrderData.PCOPendingAmount
	FROM 
		[dbo].[fnPMContractDDContract] (@Company, @BeginningContract, @EndingContract) ContractData
		INNER JOIN [dbo].[fnPMContractDDItem] (@Company, @BeginningContract, @EndingContract) ItemData ON (ContractData.JCCMCompany = ItemData.JCCICompany) AND (ContractData.JCCMContract = ItemData.JCCIContract)
		LEFT OUTER JOIN [dbo].[fnPMContractDDChangedOrder] (@Company, @BeginningContract, @EndingContract) ChangedOrderData ON (ItemData.JCCICompany = ChangedOrderData.PMOICompany) AND (ItemData.JCCIContract = ChangedOrderData.PMOIContract)
	ORDER BY
		ContractData.JCCMCompany, ContractData.JCCMContract, ItemData.JCCIItem
GO
