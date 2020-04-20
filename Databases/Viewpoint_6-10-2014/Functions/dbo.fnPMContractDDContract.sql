SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- **************************************************************
--  PURPOSE: Fetches contract detail records for PM Contract Drilldown report
--    INPUT: Values list (see below)
--   RETURN: Table
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    03/20/2014  Created function
--    03/20/2014  Tested function
-- **************************************************************

CREATE FUNCTION [dbo].[fnPMContractDDContract]
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
		JCCM.JCCo AS JCCMCompany
		,JCCM.Contract AS JCCMContract
		,JCCM.Description AS JCCMDescription
		,JCCM.Customer AS JCCMCustomer
		,ARCM.Name AS ARCMName
		,JCCM.OrigContractAmt AS JCCMOrigContractAmt
		,JCCM.ContractAmt AS JCCMContractAmt
		,JCCM.BilledAmt AS JCCMBilledAmt
		,JCMP.Name AS JCMPProjectManagerName

	 FROM   
		dbo.JCCM JCCM
		INNER JOIN dbo.HQCO HQCO ON JCCM.JCCo = HQCO.HQCo
		LEFT OUTER JOIN dbo.JCMP JCMP ON (JCCM.JCCo = JCMP.JCCo) AND (JCCM.udPOC = JCMP.ProjectMgr)
		LEFT OUTER JOIN dbo.ARCM ARCM ON (JCCM.CustGroup = ARCM.CustGroup) AND (JCCM.Customer = ARCM.Customer)
	 WHERE  
		JCCM.JCCo = @Company AND (JCCM.Contract >= @BeginningContract AND JCCM.Contract <= @EndingContract)
)
      
GO
