SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[mfnGetWIPData](
    @JCCo tinyint = null
   ,@Contract varchar(10) = null
   ,@ThruMonth date = null
)
RETURNS TABLE 
AS
/****************************************************************************************************
* mfnGetWIPData                                                                                     *
*                                                                                                   *
* ** Do not run with null Contract, query will not come back                                        *
*                                                                                                   *
* Date         By             Comment                                                               *
* ==========   ===========    =========================================================             *
* 03/07/2014   BillO          Created                                                               *
* 03/13/2014   ZachF          Added Derived columns                                                 *
*                                                                                                   *
*                                                                                                   *
*                                                                                                   *
****************************************************************************************************/
RETURN

WITH BaseData
AS
(
SELECT
	 cd.JCCo AS JCCo
   ,cd.Contract AS Contract
   ,cd.ContractDesc AS ContractDesc
   ,cd.ContractStatus AS ContractStatus
   ,cd.ContractCloseDate AS ContractCloseDate
   ,cd.ContractPOC AS ContractPOC
   ,cd.CustomerNum AS CustomerNumber
   ,cd.CustName AS CustomerName
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
   ,jc.JCActualCost AS JCActualCost
   ,jc.JCCurrEstCost AS JCCurrEstCost
   ,jc.JCForecastCost AS JCForecastCost
   ,jc.JCOrigEstCost AS JCOrigEstCost
   ,jc.JCProjCost AS JCProjCost
   ,jc.JCRecvdNotInvcdCost AS JCRecvdNotInvcdCost
   ,jc.JCRemainCmtdCost AS JCRemainCmtdCost
   ,jc.JCTotalCmtdCost AS JCTotalCmtdCost
   ,CAST(CASE jc.JCProjCost WHEN 0 THEN 0 ELSE (jc.JCActualCost/jc.JCProjCost) * 100 END AS decimal(6,2)) AS [Rev%Complete]
   ,(jc.JCProjCost - jc.JCActualCost) AS [EstCostToComplete]
   ,(cd.ProjectedProjDollars - jc.JCProjCost) AS [EstGrossMargin$]
FROM
	dbo.mfnGetWIPContractData(@JCCo,@Contract,@ThruMonth) cd
   LEFT JOIN
      dbo.mfnGetWIPContractJobCost(@JCCo,@Contract,@ThruMonth,'S') jc -- 'S' is to excldue 'Sales Pursuit' records
         ON jc.JCCo= cd.JCCo
            AND jc.Contract = cd.Contract
	         AND jc.ContractItem= cd.ContractItem
)
,DeriveData
AS
(
SELECT *
   ,CAST(CASE ProjectedProjDollars WHEN 0 THEN 0 ELSE ([EstGrossMargin$] / ProjectedProjDollars * 100) END AS numeric(10,2)) AS [EstGrossMargin%]
   ,CAST(CASE ProjectedProjDollars WHEN 0 THEN 0 ELSE JCActualCost * ([EstGrossMargin$] / ProjectedProjDollars * 100) END AS numeric(10,2)) AS JTD_RevEarned
   ,CAST(CASE ProjectedProjDollars WHEN 0 THEN 0 ELSE JCActualCost * ([EstGrossMargin$] / ProjectedProjDollars * 100) END - JCActualCost AS numeric(10,2)) AS JTD_GrossMarginEarned
FROM BaseData
)
SELECT * FROM DeriveData
GO
