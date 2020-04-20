SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
* Created By:	GP 4/4/12 - TK-13774
* Modfied By:
*
* Provides a view of unique purchase order
* across all tables that PO values can be
* stored.
*
* bPOHD - PO Entry (posting table)
* bPOHB - PO Entry (batch table)
* vPOPendingPurchaseOrder - Pending Purchase Order
*****************************************/

CREATE view [dbo].[POUnique] as

select distinct a.POCo, a.PO, a.[Description], a.JCCo, a.Job, a.[Source]
from
	(select POCo, PO, [Description], JCCo, Job, 'bPOHD' as [Source]
	from dbo.bPOHD
	union
	select Co, PO, [Description], JCCo, Job, 'bPOHB' as [Source]
	from dbo.bPOHB
	union
	select POCo, PO, [Description], JCCo, Job, 'vPOPendingPurchaseOrder' as [Source]
	from dbo.vPOPendingPurchaseOrder) as a

GO
GRANT SELECT ON  [dbo].[POUnique] TO [public]
GRANT INSERT ON  [dbo].[POUnique] TO [public]
GRANT DELETE ON  [dbo].[POUnique] TO [public]
GRANT UPDATE ON  [dbo].[POUnique] TO [public]
GO
