SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMMiscellaneousBatchReport]  
AS  

/*==================================================================================    
    
Author: ??    
Create date: ??    
    
Usage: Used in Form 940 Schedule A reporting. Procedure returns two sets      
of data, difference being determined by the SummaryFlag column in the       
last select statement. A flag value of 'S' means the row is a summary      
row. It sums FUTA subject earning amounts by state for the reporting year.      
A flag of 'D' shows the individual employee records that make up state      
sums values.      
    
Parameters:           
    
Related reports: SM Misc Batch List (ID#: 1145)    
    
Revision History      
Date  Author  Issue     Description      
02/09/2012 ScottAlvey CL-NA / V1-B-08621 Due to the changed work complete behavior  
this B item introduced a new view was created, SMWorkCompletedAllCurrent. This view  
used to look at SMWorkCompleted, which due to the change now only sees non-deleted items.  
The report needs to see deleted items as well to show what is being backed out, so the  
SMWorkCompletedAllCurrent view was introduced to do this. This (SMMiscellaneousBatchReport)  
view is being modified to look to this new view (SMWorkCompletedAllCurrent). Also changed the 
logic behind the Type field. Since IsDeleted = 0 could be an add or chagne record I left
that the same, just changed to look to IsDeleted = 1 then 'Delete'
    
==================================================================================*/    
  
SELECT Co, Mth, BatchId, BatchSeq,   
 CASE WHEN vSMGLDetailTransaction.GLCo IS NULL THEN 'Add'    
  --WHEN SMWorkCompletedAllCurrent.ActualCost IS NULL THEN 'Delete'    
  WHEN SMWorkCompletedAllCurrent.IsDeleted = 1 THEN 'Delete'  
  ELSE 'Change' END    
 Type,   
 SMMiscellaneousBatch.SMWorkCompletedID,   
 SMWorkCompletedAllCurrent.WorkOrder,   
 SMWorkOrder.Description WorkOrderDescription,  
 SMWorkCompletedAllCurrent.Scope,  
 SMWorkOrderScope.Description ScopeDescription,  
 SMWorkCompletedAllCurrent.WorkCompleted,   
 SMWorkCompletedAllCurrent.Description AS Description,   
 SMWorkCompletedAllCurrent.Date AS ActualDate,  
 SMWorkCompletedAllCurrent.SMCostType,  
 SMCostType.Description CostTypeDesc,   
 SMCO.GLJrnl AS Jrnl,   
 SMCO.MiscCostOffsetGLCo AS OffsetGLCo,   
 SMCO.MiscCostOffsetGLAcct AS OffsetGLAcct,   
 SMWorkCompletedAllCurrent.GLCo AS GLCo,  
 CASE WHEN SMWorkOrderScope.IsTrackingWIP='Y' AND SMWorkOrderScope.IsComplete='N'   
  THEN  SMWorkCompletedAllCurrent.CostWIPAccount   
  ELSE SMWorkCompletedAllCurrent.CostAccount END AS GLAcct,   
 SMWorkCompletedAllCurrent.ActualCost AS NewAmount,  
 vSMGLDetailTransaction.GLCo AS OldGLCo,  
 vSMGLDetailTransaction.GLAccount AS OldGLAccount,  
 vSMGLDetailTransaction.Amount AS OldAmount  
FROM SMMiscellaneousBatch  
 LEFT JOIN SMWorkCompletedAllCurrent ON SMWorkCompletedAllCurrent.SMWorkCompletedID=SMMiscellaneousBatch.SMWorkCompletedID  
 LEFT JOIN SMCostType ON SMCostType.SMCo = SMWorkCompletedAllCurrent.SMCo AND SMCostType.SMCostType = SMWorkCompletedAllCurrent.SMCostType  
 LEFT JOIN SMWorkOrderScope ON SMWorkCompletedAllCurrent.SMCo = SMWorkOrderScope.SMCo   
  AND SMWorkCompletedAllCurrent.WorkOrder = SMWorkOrderScope.WorkOrder AND SMWorkCompletedAllCurrent.Scope = SMWorkOrderScope.Scope  
 LEFT JOIN SMWorkOrder ON SMWorkOrder.SMCo = SMWorkCompletedAllCurrent.SMCo   
  AND SMWorkOrder.WorkOrder = SMWorkCompletedAllCurrent.WorkOrder   
 LEFT JOIN SMCO ON SMCO.SMCo=SMMiscellaneousBatch.Co  
 LEFT JOIN vSMWorkCompletedGL ON vSMWorkCompletedGL.SMWorkCompletedID = SMMiscellaneousBatch.SMWorkCompletedID  
 LEFT JOIN vSMGLDetailTransaction ON vSMGLDetailTransaction.SMGLDetailTransactionID = vSMWorkCompletedGL.CostGLDetailTransactionID  
  
GO
GRANT SELECT ON  [dbo].[SMMiscellaneousBatchReport] TO [public]
GRANT INSERT ON  [dbo].[SMMiscellaneousBatchReport] TO [public]
GRANT DELETE ON  [dbo].[SMMiscellaneousBatchReport] TO [public]
GRANT UPDATE ON  [dbo].[SMMiscellaneousBatchReport] TO [public]
GRANT SELECT ON  [dbo].[SMMiscellaneousBatchReport] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMMiscellaneousBatchReport] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMMiscellaneousBatchReport] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMMiscellaneousBatchReport] TO [Viewpoint]
GO
