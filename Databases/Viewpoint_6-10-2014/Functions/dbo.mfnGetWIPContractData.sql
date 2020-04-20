SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[mfnGetWIPContractData](
    @JCCo tinyint = null
   ,@Contract varchar(10) = null
   ,@ThruMonth date = null
   ,@POC bProjectMgr = null
   ,@GLDepartment varchar(20) = null
)
RETURNS TABLE 
AS
/****************************************************************************************************
* mfnGetWIPContractData                                                                             *
*                                                                                                   *
* Date         By             Comment                                                               *
* ==========   ===========    =========================================================             *
* 03/07/2014   BillO          Created                                                               *
* 03/10/2014   ZachF          Added Month param, ContractStatus and Join hint                       *
* 03/16/2014   Zachf          Wildcard for Contract                                                 *
* 04/12/2014   Zachf          Added POC and GLDepartment as parameter                               *
* 04/17/2014   Zachf          Added udRevType, jcci.udLockYN in result set                          *                                                                                                   *
*                                                                                                   *
****************************************************************************************************/
RETURN
SELECT 
	 jccm.JCCo
   ,jccm.Contract
   ,jccm.Description AS ContractDesc
   ,jccm.ContractStatus AS ContractStatus
   ,CAST(jccm.ActualCloseDate AS date) AS ContractCloseDate
   ,arcm.Customer AS CustomerNum
   ,arcm.Name AS CustName
   ,jccm.udPOC AS ContractPOC
   ,jcmp.Name AS ContractPOCName
   ,jccm.Department AS ContractDepartment
   ,cmdept.Description AS ContractDepartmentName
   ,cmglpi.Instance AS ContractGLDepartment
   ,cmglpi.Description AS ContractGLDepartmentName
   ,jcci.Item AS ContractItem
   ,jcci.Description AS ContractItemDescription
   ,jcci.Department AS ContractItemDepartment
   ,cidept.Description AS ContractItemDepartmentName
   ,ciglpi.Instance AS ContractItemGLDepartment
   ,ciglpi.Description AS ContractItemGLDepartmentName
   ,jcci.OrigContractAmt
   ,jcci.ContractAmt
   ,jcci.BillOriginalAmt
   ,jcci.BillCurrentAmt
   ,jcci.CurrentRetainAmt
   ,jcci.ReceivedAmt
   ,@ThruMonth AS ProjectionThruMonth
   ,jcci.udRevType AS udRevType
   ,jcci.udLockYN AS udLockYN  
   ,COALESCE(SUM(jcip.OrigContractAmt),0) AS ProjectedOrigContractAmount
   ,COALESCE(SUM(jcip.BilledAmt),0) AS ProjectedBilledAmt
   ,COALESCE(SUM(jcip.ContractAmt),0) AS ProjectedContractAmt
   ,COALESCE(SUM(jcip.CurrentRetainAmt),0) AS ProjectedCurrentRetainAmt
   ,COALESCE(SUM(jcip.ProjDollars),0) AS ProjectedProjDollars
   ,COALESCE(SUM(jcip.ReceivedAmt),0) AS ProjectedReceivedAmt
FROM 
	JCCM jccm WITH (READUNCOMMITTED)
   LEFT JOIN
	   JCCI jcci WITH (READUNCOMMITTED)
         ON jccm.JCCo = jcci.JCCo
	         AND jccm.Contract = jcci.Contract
   LEFT JOIN
	   JCDM cmdept WITH (READUNCOMMITTED)
         ON jccm.JCCo = cmdept.JCCo
	         AND jccm.Department = cmdept.Department
   LEFT JOIN
	   JCDM cidept WITH (READUNCOMMITTED)
         ON jcci.JCCo = cidept.JCCo
	         AND jcci.Department = cidept.Department
   LEFT JOIN
	   JCMP jcmp WITH (READUNCOMMITTED)
         ON jccm.JCCo = jcmp.JCCo
	         AND jccm.udPOC = jcmp.ProjectMgr
   LEFT JOIN
	   GLPI cmglpi WITH (READUNCOMMITTED)
         ON jccm.JCCo = cmglpi.GLCo
	         AND cmglpi.PartNo = 3
	         AND cmglpi.Instance = SUBSTRING(cmdept.OpenRevAcct,10,4)
   LEFT JOIN
	   GLPI ciglpi WITH (READUNCOMMITTED)
         ON jcci.JCCo = ciglpi.GLCo
	         AND ciglpi.PartNo = 3
	         AND ciglpi.Instance = SUBSTRING(cidept.OpenRevAcct,10,4)
   LEFT JOIN
      JCIP jcip WITH (READUNCOMMITTED)
         ON jcip.JCCo = jcci.JCCo
	         AND jcip.Contract = jcci.Contract	
	         AND jcip.Item = jcci.Item
   LEFT JOIN
      ARCM arcm WITH (READUNCOMMITTED)
         ON arcm.CustGroup = jccm.CustGroup
            AND arcm.Customer = jccm.Customer            	
WHERE
   (@JCCo IS NULL OR jccm.JCCo = @JCCo)
   AND (@Contract IS NULL OR LTRIM(RTRIM(jccm.Contract)) LIKE LTRIM(RTRIM(@Contract)) + '%')
   AND (jcip.Mth <= ISNULL(@ThruMonth,GETDATE()))
   AND (@POC IS NULL OR jccm.udPOC = @POC)
   AND (@GLDepartment IS NULL OR ciglpi.Instance = @GLDepartment)
GROUP BY
    jccm.JCCo
   ,jccm.Contract
   ,jccm.Description
   ,jccm.ContractStatus
   ,jccm.ActualCloseDate
   ,arcm.Customer
   ,arcm.Name
   ,jccm.udPOC 
   ,jcmp.Name 
   ,jccm.Department 
   ,cmdept.Description 
   ,cmglpi.Instance 
   ,cmglpi.Description 
   ,jcci.Item 
   ,jcci.Description 
   ,jcci.Department 
   ,cidept.Description 
   ,ciglpi.Instance 
   ,ciglpi.Description 
   ,jcci.OrigContractAmt
   ,jcci.ContractAmt
   ,jcci.BillOriginalAmt
   ,jcci.BillCurrentAmt
   ,jcci.CurrentRetainAmt
   ,jcci.ReceivedAmt
   ,jcci.udRevType
   ,jcci.udLockYN
GO
