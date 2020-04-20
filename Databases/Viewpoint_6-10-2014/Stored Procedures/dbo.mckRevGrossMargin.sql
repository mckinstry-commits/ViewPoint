SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE dbo.mckRevGrossMargin(
    @Company bCompany = 0
   ,@Department bDept = null
   ,@Contract bContract = null
   ,@POC bProjectMgr = null
   ,@ThruMth bDate = null
   ,@CustomerNum varchar(15) = null
)
AS
/***********************************************************************************************************
* WorkInProgress                                                                                           *
*                                                                                                          *
* Purpose: for SSRS Revenue Gross margin Report                                                            *
*                                                                                                          *
* Date			By			Comment                                                                            *
* ==========	========	=======================================================================            *
* 03/18/2014 	ZachFu	Created                                                                            *
* 04/17/2014   ZachFu   Filtered by SourceStatus='I' or 'J', ActiveYN='Y', udRevType is not Annuity        *
*                                                                                                          *
*                                                                                                          *
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

IF @CustomerNum = ''
   SET @CustomerNum = null
ELSE
   SET @CustomerNum = CAST(@CustomerNum AS int);

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
   (@CustomerNum IS NULL OR cd.CustomerNum = @CustomerNum)
   AND (cd.udRevType IS NULL OR cd.udRevType <> 'A') -- not Annuity
   AND cd.udLockYN = 'Y'

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
   jc.SourceStatus IN ('I','J')
   AND jc.ActiveYN = 'Y'
   AND (jc.udRevType IS NULL OR jc.udRevType <> 'A') -- not Annuity
   AND jc.udLockYN = 'Y'


;WITH RevGrsMrgn
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
   ,cd.ProjectedProjDollars AS ProjectedProjDollars
   ,cd.ProjectedReceivedAmt AS ProjectedReceivedAmt
   ,ISNULL(jc.JCActualCost,0) AS JCActualCost
   ,ISNULL(jc.JCCurrEstCost,0) AS JCCurrEstCost
   ,ISNULL(jc.JCForecastCost,0) AS JCForecastCost
   ,ISNULL(jc.JCOrigEstCost,0) AS JCOrigEstCost
   ,ISNULL(jc.JCProjCost,0) AS JCProjCost
   ,ISNULL(jc.JCRecvdNotInvcdCost,0) AS JCRecvdNotInvcdCost
   ,ISNULL(jc.JCRemainCmtdCost,0) AS JCRemainCmtdCost
   ,ISNULL(jc.JCTotalCmtdCost,0) AS JCTotalCmtdCost
   ,ISNULL((jc.JCProjCost - jc.JCActualCost),0) AS [EstCostToComplete]
   ,ISNULL((cd.ProjectedProjDollars - jc.JCProjCost),0) AS [EstGrossMargin$]
   ,ISNULL(CAST(CASE ProjectedProjDollars
             WHEN 0 THEN 0
             ELSE ((cd.ProjectedProjDollars - jc.JCProjCost) / ProjectedProjDollars * 100)
         END AS numeric(10,2)),0) AS [EstGrossMargin%]
   ,ISNULL(CAST(CASE ProjectedProjDollars
            WHEN 0 THEN 0
            ELSE JCActualCost * ((cd.ProjectedProjDollars - jc.JCProjCost) / ProjectedProjDollars * 100)
         END AS numeric(10,2)),0) AS JTD_RevEarned
   ,ISNULL(CAST(CASE ProjectedProjDollars
            WHEN 0 THEN 0
            ELSE JCActualCost * ((cd.ProjectedProjDollars - jc.JCProjCost) / ProjectedProjDollars * 100)
         END - JCActualCost AS numeric(10,2)),0) AS JTD_GrossMarginEarned
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
   ,LTRIM(RTRIM(ContractItemGLDepartment)) AS GLDept
   ,LTRIM(ContractItemGLDepartmentName) AS GLDepartmentDesc
   ,LTRIM(RTRIM(Contract)) As ContractNumber
   ,SUBSTRING(ContractDesc,1,60) AS ContractDesc
   ,CASE ContractStatus
      WHEN 0 THEN '0-Pending'
      WHEN 1 THEN '1-Open'
      WHEN 2 THEN '2-Soft Closed'
      WHEN 3 THEN '3-Hard Closed'
      ELSE CAST(ContractStatus AS varchar(2))
    END AS ContractStatus
   ,ContractCloseDate
   --,CAST(ContractPOC AS varchar(10)) + ' - ' + ContractPOCName AS MckinstryPOC
   ,ContractPOCName AS MckinstryPOC
   ,CustomerNumber AS CustomerNumber
   ,CustomerName AS CustomerName
   ,ROUND(SUM(ISNULL(ContractAmt,0)),0) AS ContractValue
   ,ROUND(SUM(ISNULL(JCCurrEstCost,0)),0) AS TotBudgetedCost

   /* GrossMargin:
   -- (SUM(Contract Value) - SUM(Total Budgeted Cost))
   */
   ,ROUND((SUM(ISNULL(ContractAmt,0)) - SUM(ISNULL(JCCurrEstCost,0))),0) AS GrossMargin

   /* GrossMarginPct:
   -- SUM(Gross Margin) /  SUM(ContractValue) * 100
   */
   ,CASE
      WHEN SUM(ISNULL(ContractAmt,0)) = 0 THEN 0
      ELSE CAST((SUM(ISNULL(ContractAmt,0)) - SUM(ISNULL(JCCurrEstCost,0))) / SUM(ISNULL(ContractAmt,0)) AS decimal(12,3))
    END AS GrossMarginPct

    ,ROUND(SUM(ISNULL(ProjectedProjDollars,0)),0) AS ETCContractValue
    ,ROUND(SUM(ISNULL(JCProjCost,0)),0) AS ETCTotFinalCosts

    /* ETCGrossMargin:
    -- ETCCoontractValue - ETCTotalFinalCost
    */
    ,ROUND(SUM(ISNULL(ProjectedProjDollars,0)) - SUM(ISNULL(JCProjCost,0)),0) AS ETCGrossMargin

    /* ETCGrossMarginPct:
    -- (ETCGrossMargin / ETCContractValue) * 100
    */
    ,CASE
      WHEN SUM(ISNULL(ProjectedProjDollars,0)) = 0 THEN 0
--      ELSE CAST(((SUM(ISNULL(ContractAmt,0)) - SUM(ISNULL(JCCurrEstCost,0))) / SUM(ISNULL(ProjectedProjDollars,0))) * 100 AS decimal(12,1))
      ELSE CAST(((SUM(ISNULL(ContractAmt,0)) - SUM(ISNULL(JCCurrEstCost,0))) / SUM(ISNULL(ProjectedProjDollars,0))) AS decimal(12,3))
     END AS ETCGrossMarginPct

    /* EarnedRevenue:
    -- [%Complete] -->  ActualCost / CurrEstCost
    -- ContractAmt * [%Complete]
    */
   ,ROUND(CASE
      WHEN SUM(ISNULL(JCCurrEstCost,0)) = 0 THEN 0
      ELSE ROUND(SUM(ISNULL(ContractAmt,0)) * (SUM(ISNULL(JCActualCost,0)) / SUM(ISNULL(JCCurrEstCost,0))),0)
    END,0) AS EarnedRevenue
    
   /* EarnedMarginDollar:
   --      
   -- [EarnedRevenue] - SUM(ActualCost]
   */
   ,ROUND(CASE
      WHEN SUM(ISNULL(JCCurrEstCost,0)) = 0 THEN 0
      ELSE SUM(ISNULL(ContractAmt,0)) * (SUM(ISNULL(JCActualCost,0)) / SUM(ISNULL(JCCurrEstCost,0)))
    END - SUM(ISNULL(JCActualCost,0)),0) AS EarnedMarginDollar

   /* EarnedMarginPct:
   -- [EarnedMarginDollar] / ContractAmt
   */
   ,CAST(CASE
      WHEN SUM(ISNULL(ContractAmt,0)) = 0 THEN 0
      ELSE (CASE
               WHEN SUM(ISNULL(JCCurrEstCost,0)) = 0 THEN 0
               ELSE SUM(ISNULL(ContractAmt,0)) * (SUM(ISNULL(JCActualCost,0)) / SUM(ISNULL(JCCurrEstCost,0)))
--            END - SUM(ISNULL(JCActualCost,0))) / SUM(ISNULL(ContractAmt,0)) * 100
            END - SUM(ISNULL(JCActualCost,0))) / SUM(ISNULL(ContractAmt,0))
    END AS decimal(12,3)) AS EarnedMarginPct

FROM
   RevGrsMrgn
GROUP BY
    JCCo
   ,LTRIM(RTRIM(ContractItemGLDepartment))
   ,LTRIM(ContractItemGLDepartmentName)
   ,Contract
   ,SUBSTRING(ContractDesc,1,60)
--   ,CAST(ContractPOC AS varchar(10)) + ' - ' + ContractPOCName
   ,ContractPOCName
   ,ContractStatus
   ,ContractCloseDate
   ,CustomerNumber
   ,CustomerName
   ,ContractAmt
ORDER BY
    JCCo
   ,Contract
   ,GLDept

END
GO
GRANT EXECUTE ON  [dbo].[mckRevGrossMargin] TO [public]
GO
