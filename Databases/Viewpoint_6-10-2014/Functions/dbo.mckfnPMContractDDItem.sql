SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- **************************************************************
--  PURPOSE: Fetches item detail records for PM Contract Drilldown report
--    INPUT: Values list (see below)
--   RETURN: Table
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    03/20/2014  Created function
--    03/20/2014  Tested function
-- **************************************************************

CREATE FUNCTION [dbo].[mckfnPMContractDDItem]
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
		JCCI.JCCo AS JCCICompany
		,JCCI.Contract AS JCCIContract
		,JCCI.Item AS JCCIItem
		,JCCI.Description AS JCCIDescription
		,JCCI.BillType AS JCCIBillType
		,JCCI.UM AS JCCIUM
		,JCCI.OrigContractUnits AS JCCIOrigContractUnits
		,JCCI.UnitPrice AS JCCIUnitPrice
		,JCCI.ContractAmt AS JCCIContractAmt
		,JCCI.OrigContractAmt AS JCCIOrigContractAmt
		,JCCI.BilledAmt AS JCCIBilledAmt
	 FROM   
		dbo.JCCI JCCI
	 WHERE  
		JCCI.JCCo = @Company AND (JCCI.Contract >= @BeginningContract AND JCCI.Contract <= @EndingContract)
)
      
GO
