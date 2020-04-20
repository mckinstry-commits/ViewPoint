SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*****************************************
 * Created By:	GF 04/21/2012 TK-14088 B-08882
 * Modfied By:	
 *
 *
 * Provides a view of PO Pending PO Item Work Flow Reviewers
 *
 *****************************************/

CREATE view [dbo].[WFProcessDetailForPO] as 
SELECT a.*
		,b.POCo		AS [POCo]
		,b.PO		AS [PO]
		,b.POItem	AS [POItem]
FROM [dbo].[WFProcessDetail] a
INNER JOIN [dbo].[POPendingPurchaseOrderItem] b ON b.KeyID = a.SourceKeyID
WHERE a.SourceView = 'POPendingPurchaseOrderItem'










GO
GRANT SELECT ON  [dbo].[WFProcessDetailForPO] TO [public]
GRANT INSERT ON  [dbo].[WFProcessDetailForPO] TO [public]
GRANT DELETE ON  [dbo].[WFProcessDetailForPO] TO [public]
GRANT UPDATE ON  [dbo].[WFProcessDetailForPO] TO [public]
GRANT SELECT ON  [dbo].[WFProcessDetailForPO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WFProcessDetailForPO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WFProcessDetailForPO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WFProcessDetailForPO] TO [Viewpoint]
GO
