SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************
* Created By:	Dan So 03/26/2012 - B-08870/TK-13411
* Modfied By:	
*
*
* Provides a base view of Inventory location specific PO/Req process
*
*****************************************/


CREATE view [dbo].[INLocationApprovalProcess] as select a.* From vINLocationApprovalProcess a


GO
GRANT SELECT ON  [dbo].[INLocationApprovalProcess] TO [public]
GRANT INSERT ON  [dbo].[INLocationApprovalProcess] TO [public]
GRANT DELETE ON  [dbo].[INLocationApprovalProcess] TO [public]
GRANT UPDATE ON  [dbo].[INLocationApprovalProcess] TO [public]
GRANT SELECT ON  [dbo].[INLocationApprovalProcess] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INLocationApprovalProcess] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INLocationApprovalProcess] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INLocationApprovalProcess] TO [Viewpoint]
GO
