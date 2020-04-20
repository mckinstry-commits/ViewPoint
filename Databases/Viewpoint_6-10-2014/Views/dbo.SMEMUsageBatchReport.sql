SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMEMUsageBatchReport]  
AS  

/*==================================================================================    
    
Author: ScottAlvey    
Create date: 02/15/2012    
    
Usage: For use in the SM Equipment Usage Batch List report. Because a user can have a different
value between Scope and OldScope, this view unions the A and C new records with the C and D old records
and makes all the Old records stack under the new records instead of having the old records
spread out on the same line as the new records. This will make Scope and OldScope be in the column 
for ease of grouping in the report     
    
Parameters:           
    
Related reports: SM Equipment Usage Batch List (ID#: 1146)    
    
Revision History      
Date  Author  Issue     Description      

    
==================================================================================*/    

select 
	'New' as BatchTransTypeDesc
	, Co
	, BatchMonth
	, BatchId
	, BatchSeq
	, SMWorkCompletedID
	, BatchTransType
	, SMCo
	, WorkOrder
	, WorkCompleted
	, Scope
	, EMCo
	, EMGroup
	, Equipment
	, RevCode
	, GLCo
	, GLAcct
	, OffsetGLCo
	, OffsetGLAcct
	, Category
	, RevBasis
	, WorkUM
	, WorkUnits
	, TimeUM
	, TimeUnits
	, Dollars
	, RevRate
	, ActualDate
	, CustGroup
	, Customer
	, null as OldEMCo
	, null as OldEMGroup
	, null as OldEquipment
	, null as OldRevCode
	, null as OldGLCo
	, null as OldGLAcct
	, null as OldOffsetGLCo
	, null as OldOffsetGLAcct
	, null as OldCategory
	, null as OldRevBasis
	, null as OldWorkUM
	, null as  OldWorkUnits
	, null as OldTimeUM
	, null as OldTimeUnits
	, null as OldDollars
	, null as OldRevRate
	, null as OldActualDate
	, null as OldCustGroup
	, null as OldCustomer
From 
	dbo.SMEMUsageBatch
Where 
	BatchTransType in ('A','C')
	
union all

Select 
	'Old' as BatchTransTypeDesc
	, Co
	, BatchMonth
	, BatchId
	, BatchSeq
	, SMWorkCompletedID
	, BatchTransType
	, SMCo
	, WorkOrder
	, WorkCompleted
	, OldScope as Scope
	, null as EMCo
	, null as EMGroup
	, null as Equipment
	, null as RevCode
	, null as GLCo
	, null as GLAcct
	, null as OffsetGLCo
	, null as OffsetGLAcct
	, null as Category
	, null as RevBasis
	, null as WorkUM
	, null as WorkUnits
	, null as TimeUM
	, null as TimeUnits
	, null as Dollars
	, null as RevRate
	, null as ActualDate
	, null as CustGroup
	, null as Customer
	, OldEMCo
	, OldEMGroup
	, OldEquipment
	, OldRevCode
	, OldGLCo
	, OldGLAcct
	, OldOffsetGLCo
	, OldOffsetGLAcct
	, OldCategory
	, OldRevBasis
	, OldWorkUM
	, OldWorkUnits
	, OldTimeUM
	, OldTimeUnits
	, OldDollars
	, OldRevRate
	, OldActualDate
	, OldCustGroup
	, OldCustomer
From 
	dbo.SMEMUsageBatch
Where 
	BatchTransType in ('C','D')
GO
GRANT SELECT ON  [dbo].[SMEMUsageBatchReport] TO [public]
GRANT INSERT ON  [dbo].[SMEMUsageBatchReport] TO [public]
GRANT DELETE ON  [dbo].[SMEMUsageBatchReport] TO [public]
GRANT UPDATE ON  [dbo].[SMEMUsageBatchReport] TO [public]
GRANT SELECT ON  [dbo].[SMEMUsageBatchReport] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMEMUsageBatchReport] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMEMUsageBatchReport] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMEMUsageBatchReport] TO [Viewpoint]
GO
