SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvSMOpenPurchaseOrder]

/***
 CREATED:  10/17/11 DH
 MODIFIED:  
 
 USAGE:  View returns Open (Status=0) PO's related to SM Work Orders (ItemType6).  
 Received Cost must be updated from SM Work Orders.
 
***/

AS 

SELECT 
	
	POItem.SMCo,
	POItem.SMWorkOrder,
	POItem.PO,
	POHeader.OrderDate,
	POHeader.VendorGroup,
	POHeader.Vendor,
	APVM.Name as VendorName,
	POItem.POItem,
	POItem.TotalCost,
	POItem.RecvdCost,
	POItem.TotalCost - POItem.RecvdCost as Balance
FROM POIT POItem WITH (NOLOCK)
		INNER JOIN
	 POHD POHeader WITH (NOLOCK)
		ON  POHeader.POCo = POItem.POCo
		AND	POHeader.PO = POItem.PO
		INNER JOIN
			APVM WITH (NOLOCK)
		ON	APVM.VendorGroup=POHeader.VendorGroup
		AND APVM.Vendor=POHeader.Vendor
		
WHERE	POHeader.Status=0  --Open work order
		AND POItem.ItemType=6 --SM Work Order 
	  	
	  	
	  	
	
	


GO
GRANT SELECT ON  [dbo].[vrvSMOpenPurchaseOrder] TO [public]
GRANT INSERT ON  [dbo].[vrvSMOpenPurchaseOrder] TO [public]
GRANT DELETE ON  [dbo].[vrvSMOpenPurchaseOrder] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMOpenPurchaseOrder] TO [public]
GRANT SELECT ON  [dbo].[vrvSMOpenPurchaseOrder] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSMOpenPurchaseOrder] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSMOpenPurchaseOrder] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSMOpenPurchaseOrder] TO [Viewpoint]
GO
