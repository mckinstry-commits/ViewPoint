SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE dbo.mckWorkInProgress(
    @Company bCompany = null
   ,@Department bDept = null
   ,@Contract bContract = null
   ,@POC bProjectMgr = null
   ,@ThruMth bDate = null
)
AS
/***********************************************************************************************************
* WorkInProgress                                                                                           *
*                                                                                                          *
* Purpose: for SSRS Work In Progress Report                                                                *
*                                                                                                          *
*                                                                                                          *
* Date			By			Comment                                                                            *
* ==========	========	=============================================================================      *
* 03/13/2014 	ZachFu	Created                                                                            *
* 04/11/2014 	ZachFu	Refined calculations                                                               *
* 04/17/2014   ZachFu   Filtered by SourceStatus='I' or 'J', ActiveYN='Y', udRevType is not Annuity        *
* 04/28/2014   ZachFu   Include Open, Soft Closed and Hard Closed data.  Final filtering in report         *
*                                                                                                          *                                                                                                          *
************************************************************************************************************/
BEGIN

IF @Company = ''
   SET @Company = null;

IF @Department = ''
   SET @Department = null;

IF @Contract = ''
   SET @Contract = null;

IF @POC = ''
   SET @POC = null;

IF @ThruMth IS NULL
   SET @ThruMth = Getdate();

-- Push to first date of month
SET @ThruMth = CAST(DATEADD(dd,-(DAY(@ThruMth)-1),@ThruMth) AS date)

IF OBJECT_ID('tempdb.dbo.[#TempContractData]') IS NOT NULL
DROP TABLE #TempContractData

IF OBJECT_ID('tempdb.dbo.[#TempJobCost]') IS NOT NULL
DROP TABLE #TempJobCost


SELECT
	 cd.JCCo AS JCCo
   ,cd.Contract AS Contract
   ,cd.ContractDesc AS ContractDesc
   ,cd.ContractStatus AS ContractStatus
   ,cd.ContractCloseDate AS ContractCloseDate
   ,cd.CustomerNum AS CustomerNumber
   ,cd.CustName AS CustomerName
   ,cd.ContractPOC AS ContractPOC
   ,cd.ContractPOCName AS ContractPOCName
   ,cd.ContractDepartment AS ContractDepartment
   ,cd.ContractDepartmentName AS ContractDepartmentName
   ,cd.ContractGLDepartment AS ContractGLDepartment
   ,cd.ContractGLDepartmentName AS ContractGLDepartmentName
   ,cd.ContractItem AS ContractItem
   ,cd.ContractItemDescription AS ContractItemDescription
   ,cd.ContractItemDepartment AS ContractItemDepartment
   ,cd.ContractItemDepartmentName AS ContractItemDepartmentName
   ,cd.ContractItemGLDepartment AS ContractItemGLDepartment
   ,cd.ContractItemGLDepartmentName AS ContractItemGLDepartmentName
   ,cd.ProjectionThruMonth AS ProjectionThruMonth
   ,cd.OrigContractAmt AS OrigContractAmt
   ,cd.ContractAmt AS ContractAmt
   ,cd.BillOriginalAmt AS BillOriginalAmt
   ,cd.BillCurrentAmt AS BillCurrentAmt
   ,cd.CurrentRetainAmt AS CurrentRetainAmt
   ,cd.ReceivedAmt AS ReceivedAmt
   ,cd.ProjectedOrigContractAmount AS ProjectedOrigContractAmount
   ,cd.ProjectedBilledAmt AS ProjectedBilledAmt
   ,cd.ProjectedContractAmt AS ProjectedContractAmt
   ,cd.ProjectedCurrentRetainAmt AS ProjectedCurrentRetainAmt
   ,cd.ProjectedProjDollars AS ProjectedProjDollars
   ,cd.ProjectedReceivedAmt AS ProjectedReceivedAmt
INTO
   #TempContractData
FROM
	dbo.mfnGetWIPContractData(@Company,@Contract,@ThruMth,@POC,@Department) cd
WHERE
   cd.JCCo = @Company
   AND (@Department IS NULL OR cd.ContractItemGLDepartment LIKE '%' + @Department + '%')
   AND (@POC IS NULL OR cd.ContractPOC = @POC)
   AND (cd.udRevType IS NULL OR cd.udRevType <> 'A') -- not Annuity
   AND cd.udLockYN = 'Y'
   AND cd.ContractStatus IN (1,2,3) -- Open, Soft Closed, Hard Closed


SELECT
    jc.JCCo
   ,jc.Contract
   ,jc.ContractItem
   ,jc.JCActualCost AS JCActualCost
   ,jc.JCCurrEstCost AS JCCurrEstCost
   ,jc.JCForecastCost AS JCForecastCost
   ,jc.JCOrigEstCost AS JCOrigEstCost
   ,jc.JCProjCost AS JCProjCost
   ,jc.JCRecvdNotInvcdCost AS JCRecvdNotInvcdCost
   ,jc.JCRemainCmtdCost AS JCRemainCmtdCost
   ,jc.JCTotalCmtdCost AS JCTotalCmtdCost
INTO
   #TempJobCost
FROM
   dbo.mfnGetWIPContractJobCost(@Company,@Contract,@ThruMth,'S',@POC,@Department) jc -- 'S' is to excldue 'Sales Pursuit' records
WHERE
   jc.JCCo = @Company
   AND jc.SourceStatus IN ('I','J')
   AND jc.ActiveYN = 'Y'
   AND (jc.udRevType IS NULL OR jc.udRevType <> 'A') -- not Annuity
   AND jc.udLockYN = 'Y'
   AND jc.ContractStatus IN (1,2,3) -- Open, Soft Closed, Hard Closed


;WITH WIPData
AS
(
SELECT
    cd.JCCo AS JCCo
   ,cd.Contract AS Contract
   ,cd.ContractDesc AS ContractDesc
   ,cd.ContractStatus AS ContractStatus
   ,cd.ContractCloseDate AS ContractCloseDate
   ,cd.CustomerNumber AS CustomerNumber
   ,cd.CustomerName AS CustomerName
   ,cd.ContractPOC AS ContractPOC
   ,cd.ContractPOCName AS ContractPOCName
   ,cd.ContractDepartment AS ContractDepartment
   ,cd.ContractDepartmentName AS ContractDepartmentName
   ,cd.ContractGLDepartment AS ContractGLDepartment
   ,cd.ContractGLDepartmentName AS ContractGLDepartmentName
   ,cd.ContractItem AS ContractItem
   ,cd.ContractItemDescription AS ContractItemDescription
   ,cd.ContractItemDepartment AS ContractItemDepartment
   ,cd.ContractItemDepartmentName AS ContractItemDepartmentName
   ,cd.ContractItemGLDepartment AS ContractItemGLDepartment
   ,cd.ContractItemGLDepartmentName AS ContractItemGLDepartmentName
   ,cd.ProjectionThruMonth AS ProjectionThruMonth
   ,cd.OrigContractAmt AS OrigContractAmt
   ,cd.ContractAmt AS ContractAmt
   ,cd.BillOriginalAmt AS BillOriginalAmt
   ,cd.BillCurrentAmt AS BillCurrentAmt
   ,cd.CurrentRetainAmt AS CurrentRetainAmt
   ,cd.ReceivedAmt AS ReceivedAmt
   ,cd.ProjectedOrigContractAmount AS ProjectedOrigContractAmount
   ,cd.ProjectedBilledAmt AS ProjectedBilledAmt
   ,cd.ProjectedContractAmt AS ProjectedContractAmt
   ,cd.ProjectedCurrentRetainAmt AS ProjectedCurrentRetainAmt
    --if no projection entries, use base contract values
   ,CASE
      WHEN cd.ProjectedProjDollars IS NULL OR cd.ProjectedProjDollars = 0
         THEN ISNULL(cd.ContractAmt,0)
      ELSE cd.ProjectedProjDollars
    END AS ProjectedProjDollars -- [ETCContractValue]
   ,cd.ProjectedReceivedAmt AS ProjectedReceivedAmt
   ,ISNULL(jc.JCActualCost,0) AS JCActualCost
   ,ISNULL(jc.JCCurrEstCost,0) AS JCCurrEstCost
   ,ISNULL(jc.JCForecastCost,0) AS JCForecastCost
   ,ISNULL(jc.JCOrigEstCost,0) AS JCOrigEstCost
   ,ISNULL(jc.JCProjCost,0) AS JCProjCost  --  [EstCost@Complete]
   ,ISNULL(jc.JCRecvdNotInvcdCost,0) AS JCRecvdNotInvcdCost
   ,ISNULL(jc.JCRemainCmtdCost,0) AS JCRemainCmtdCost
   ,ISNULL(jc.JCTotalCmtdCost,0) AS JCTotalCmtdCost
   ,ISNULL((jc.JCProjCost - jc.JCActualCost),0) AS [EstCostToComplete]
   -- [EstGrossMargin$]: ETC Contract Value - EstCost@Complete
   ,CASE
      WHEN cd.ProjectedProjDollars IS NULL OR cd.ProjectedProjDollars = 0
         THEN ISNULL(cd.ContractAmt,0) - ISNULL(jc.JCProjCost,0)
         ELSE cd.ProjectedProjDollars - ISNULL(jc.JCProjCost,0)
    END AS [EstGrossMargin$]
FROM
	#TempContractData cd 
   LEFT JOIN
      #TempJobCost jc
         ON jc.JCCo = cd.JCCo
         	AND ISNULL(jc.Contract,'novalue') = ISNULL(cd.Contract,'novalue')
	         AND ISNULL(jc.ContractItem,'novalue') = ISNULL(cd.ContractItem,'novalue')
)
SELECT 
    JCCo AS Company
   ,LTRIM(RTRIM(ContractItemGLDepartment)) AS DeptNum
   ,LTRIM(ContractItemGLDepartmentName) AS DeptName
   ,LTRIM(RTRIM(Contract)) As ContractNumber
   ,SUBSTRING(ContractDesc,1,60) AS ContractDesc
   ,CAST(ContractPOC AS varchar(10)) + ' - ' + ContractPOCName AS MckinstryPOC
   ,ContractStatus
   ,CASE ContractStatus
      WHEN 0 THEN '0-Pending'
      WHEN 1 THEN '1-Open'
      WHEN 2 THEN '2-Soft Closed'
      WHEN 3 THEN '3-Hard Closed'
      ELSE CAST(ContractStatus AS varchar(2))
    END AS ContractStatusDisplay
   ,ROUND(SUM(ISNULL(ProjectedProjDollars,0)),0) AS ETCContractValue
   ,ROUND(SUM(ISNULL(JCActualCost,0)),0) AS ActualCost
   ,ROUND(SUM(ISNULL(EstCostToComplete,0)),0) AS EstCostToComplete
   ,ROUND(SUM(ISNULL(JCProjCost,0)),0) AS [EstCost@Complete]
   ,ROUND(SUM(ISNULL([EstGrossMargin$],0)),0) AS [EstGrossMargin$]
   ,ROUND(SUM(ISNULL(ProjectedBilledAmt,0)),0) AS BilledToDate

   /*
   -- [Rev%Complete]: ActualCost/EstCost@Complete * 100
   */
--   ,ROUND(CASE SUM(ISNULL(JCProjCost,0)) WHEN 0 THEN 0 ELSE (SUM(ISNULL(JCActualCost,0))/SUM(JCProjCost)) * 100 END,0) AS [Rev%Complete]
   ,CASE SUM(ISNULL(JCProjCost,0)) WHEN 0 THEN 0 ELSE (SUM(ISNULL(JCActualCost,0))/SUM(JCProjCost)) END AS [Rev%Complete]
   /*
   -- [EstGrossMargin%]:
   --    (Est GrossMargin$/ECT Contract Value) * 100
   */
--   ,CAST(ROUND(CASE SUM(ISNULL(ProjectedProjDollars,0))
   ,CAST(CASE SUM(ISNULL(ProjectedProjDollars,0))
            WHEN 0 THEN 0
  --          ELSE (SUM(ISNULL([EstGrossMargin$],0)) / SUM(ISNULL(ProjectedProjDollars,0)) * 100) END,1) AS decimal(12,2)) AS [EstGrossMargin%]
            ELSE (SUM(ISNULL([EstGrossMargin$],0)) / SUM(ISNULL(ProjectedProjDollars,0))) END AS decimal(12,3)) AS [EstGrossMargin%]
   /*
   -- [JTD_RevEarned]:
   --    If Actual Cost = 0 Then 0
   --      Else If EstGrossMargin$ < 0 Then Actual Cost + EstGrossMargin$
   --             Else (Actual Cost/EstCost@Compl * 100) * ETC Contract Value
   */
  ,ROUND(CASE WHEN SUM(ISNULL(JCActualCost,0)) = 0 THEN 0
              ELSE CASE WHEN SUM(ISNULL([EstGrossMargin$],0)) < 0 THEN SUM(ISNULL(JCActualCost,0)) + SUM(ISNULL([EstGrossMargin$],0))        
                        ELSE CASE WHEN SUM(ISNULL(JCProjCost,0)) = 0 THEN 0
                                  ELSE SUM(ISNULL(JCActualCost,0)) / SUM(ISNULL(JCProjCost,0)) * SUM(ISNULL(ProjectedProjDollars,0))
                             END
                   END
         END,0) AS [JTD_RevEarned]
   /*
   -- [JTD_GrossMarginEarned]: 
   --    If Actual Cost = 0 Then 0
   --      Else If EstGrossMargin$ < 0 Then EstGrossMargin$
   --          Else JTDRevenueEarned - Actual Cost
   */
   ,ROUND(CASE WHEN SUM(ISNULL(JCActualCost,0)) = 0 THEN 0
               ELSE CASE WHEN SUM(ISNULL([EstGrossMargin$],0)) < 0 THEN SUM(ISNULL([EstGrossMargin$],0)) 
                         ELSE CASE WHEN SUM(ISNULL(JCProjCost,0)) = 0 THEN 0
                                   ELSE (SUM(ISNULL(JCActualCost,0)) / SUM(ISNULL(JCProjCost,0)) * SUM(ISNULL(ProjectedProjDollars,0))) - SUM(ISNULL(JCActualCost,0))
                              END
                    END
          END,0) AS [JTD_GrossMarginEarned]                    
FROM
   WIPData
GROUP BY
    JCCo
   ,LTRIM(RTRIM(ContractItemGLDepartment))
   ,LTRIM(ContractItemGLDepartmentName)
   ,Contract
   ,SUBSTRING(ContractDesc,1,60)
   ,CAST(ContractPOC AS varchar(10)) + ' - ' + ContractPOCName
   ,ContractStatus
ORDER BY
    JCCo
   ,Contract
   ,DeptNum
   ,DeptName

END
GO
GRANT EXECUTE ON  [dbo].[mckWorkInProgress] TO [public]
GO
