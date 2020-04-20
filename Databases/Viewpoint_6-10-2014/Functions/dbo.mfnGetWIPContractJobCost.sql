SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  FUNCTION [dbo].[mfnGetWIPContractJobCost](
    @JCCo tinyint = null
   ,@Contract varchar(10) = null
   ,@ThruMonth date = null
   ,@ExcludeDBValue varchar(30)= null
   ,@POC bProjectMgr = null
   ,@GLDepartment varchar(20) = null
)
RETURNS TABLE 
AS
/****************************************************************************************************
* mfnGetWIPContractJobCost                                                                          *
*                                                                                                   *
* Date         By             Comment                                                               *
* ==========   ===========    =========================================================             *
* 03/07/2014   BillO          Created                                                               *
* 03/10/2014   ZachF          Added Month parameter and Join hint                                   *
* 03/16/2014   Zachf          Wildcard Contract                                                     *
* 03/24/2014   Zachf          Added Exclude data rows parameter                                     *
* 04/12/2014   Zachf          Added POC and GLDepartment as parameter                               *
* 04/17/2014   Zachf          Added SourceStatus, ActiveYN, udRevType, udLockYN in resultset        *
*                                                                                                   *
****************************************************************************************************/
RETURN
SELECT 
	 jccm.JCCo
   ,jccm.Contract
   ,jccm.Description AS ContractDesc
   ,jccm.ContractStatus AS ContractStatus
   ,jccm.ActualCloseDate AS ContrtactCloseDate
   ,jobs.Job AS Job
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
   ,@ThruMonth AS ProjectionThruMonth
   ,jcch.SourceStatus AS SourceStatus
   ,jcch.ActiveYN AS ActiveYN
   ,jcci.udRevType AS udRevType
   ,jcci.udLockYN AS udLockYN 
   ,COALESCE(SUM(jccp.ActualCost),0) AS JCActualCost
   ,COALESCE(SUM(jccp.CurrEstCost),0) AS JCCurrEstCost
   ,COALESCE(SUM(jccp.ForecastCost),0) AS JCForecastCost
   ,COALESCE(SUM(jccp.OrigEstCost),0) AS JCOrigEstCost
   ,COALESCE(SUM(jccp.ProjCost),0) AS JCProjCost
   ,COALESCE(SUM(jccp.RecvdNotInvcdCost),0) AS JCRecvdNotInvcdCost
   ,COALESCE(SUM(jccp.RemainCmtdCost),0) AS JCRemainCmtdCost
   ,COALESCE(SUM(jccp.TotalCmtdCost),0) AS JCTotalCmtdCost
FROM 
  (
   SELECT
      JCCo, Job, Contract FROM JCJM jcjm WITH (READUNCOMMITTED)
   WHERE 
      (jcjm.JCCo = @JCCo OR @JCCo IS NULL)
      AND (@Contract IS NULL OR LTRIM(RTRIM(jcjm.Contract)) LIKE LTRIM(RTRIM(@Contract)) + '%')
   EXCEPT
      SELECT
         JCCo, Job, Contract FROM JCJMPM jcjmpm  WITH (READUNCOMMITTED)
      WHERE
         (jcjmpm.JCCo = @JCCo OR @JCCo IS NULL)
         AND (@Contract IS NULL OR LTRIM(RTRIM(jcjmpm.Contract)) LIKE LTRIM(RTRIM(@Contract)) + '%')
         AND udProjWrkstrm = @ExcludeDBValue
   ) jobs
   LEFT JOIN
	   JCJP jcjp WITH (READUNCOMMITTED)
         ON jobs.JCCo = jcjp.JCCo
	         AND jobs.Job = jcjp.Job
   LEFT JOIN
      JCCH jcch WITH (READUNCOMMITTED)
         ON jcch.JCCo = jcjp.JCCo
            AND jcch.Job = jcjp.Job
            AND jcch.PhaseGroup = jcjp.PhaseGroup
            AND jcch.Phase = jcjp.Phase
   LEFT JOIN
	   JCCI jcci WITH (READUNCOMMITTED)
         ON jcjp.JCCo = jcci.JCCo
	         AND jcjp.Contract = jcci.Contract 
	         AND jcjp.Item = jcci.Item
   LEFT JOIN
	   JCCM jccm WITH (READUNCOMMITTED)
         ON jcci.JCCo = jccm.JCCo
	         AND jcci.Contract = jccm.Contract
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
	   JCCP jccp WITH (READUNCOMMITTED)
         ON jccp.JCCo = jcjp.JCCo
	         AND jccp.Job = jcjp.Job
	         AND jccp.PhaseGroup = jcjp.PhaseGroup	
	         AND jccp.Phase = jcjp.Phase 
	LEFT JOIN	
	   JCCT jcct WITH (READUNCOMMITTED)
         ON jcct.PhaseGroup = jccp.PhaseGroup
	         AND jcct.CostType = jccp.CostType
   LEFT JOIN
      ARCM arcm WITH (READUNCOMMITTED)
         ON arcm.CustGroup = jccm.CustGroup
            AND arcm.Customer = jccm.Customer
WHERE
   (@JCCo IS NULL OR jccm.JCCo = @JCCo)
   AND (@Contract IS NULL OR LTRIM(RTRIM(jccm.Contract)) LIKE LTRIM(RTRIM(@Contract)) + '%')
   AND (jccp.Mth <= ISNULL(@ThruMonth,GETDATE()))
   AND (@POC IS NULL OR jccm.udPOC = @POC)
   AND (@GLDepartment IS NULL OR ciglpi.Instance = @GLDepartment)
GROUP BY
	 jccm.JCCo
   ,jccm.Contract
   ,jccm.Description
   ,jccm.ContractStatus
   ,jccm.ActualCloseDate
   ,jobs.Job
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
   ,jcch.SourceStatus
   ,jcch.ActiveYN
   ,jcci.udRevType
   ,jcci.udLockYN
GO
