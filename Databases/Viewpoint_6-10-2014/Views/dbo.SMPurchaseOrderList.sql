SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMPurchaseOrderList]
AS
	SELECT DISTINCT vSMWorkOrder.SMWorkOrderID, vSMWorkOrder.SMCo, vSMWorkOrder.WorkOrder, RelatedPOs.POCo, RelatedPOs.PO,
			CASE WHEN POHD.KeyID IS NULL THEN RelatedPOs.[Status] ELSE POHD.[Status] END [Status],
			CASE WHEN POHD.KeyID IS NULL THEN RelatedPOs.OrderDate ELSE POHD.OrderDate END OrderDate,
			CASE WHEN POHD.KeyID IS NULL THEN RelatedPOs.VendorGroup ELSE POHD.VendorGroup END VendorGroup,
			CASE WHEN POHD.KeyID IS NULL THEN RelatedPOs.Vendor ELSE POHD.Vendor END Vendor,
			CASE WHEN POHD.KeyID IS NULL THEN RelatedPOs.[Description] ELSE POHD.[Description] END [Description],
			POHD.KeyID POHDKeyID
	FROM dbo.vSMWorkOrder
		INNER JOIN
		(
			SELECT RelatedBatches.SMCo, RelatedBatches.WorkOrder, bPOHB.Co POCo, bPOHB.PO, bPOHB.Mth BatchSeq,
				bPOHB.[Status], bPOHB.OrderDate, bPOHB.VendorGroup, bPOHB.Vendor, bPOHB.[Description]
			FROM dbo.bPOHB
				INNER JOIN
				(
					SELECT SMCo, WorkOrder, POCo, BatchMth, BatchId, BatchSeq
					FROM dbo.vSMWorkOrderPOHB
					UNION ALL
					SELECT SMCo, SMWorkOrder WorkOrder, Co, Mth, BatchId, BatchSeq
					FROM dbo.bPOIB
					WHERE ItemType = 6
				) RelatedBatches ON bPOHB.Co = RelatedBatches.POCo AND bPOHB.Mth = RelatedBatches.BatchMth AND bPOHB.BatchId = RelatedBatches.BatchId AND bPOHB.BatchSeq = RelatedBatches.BatchSeq
			UNION ALL
			SELECT SMCo, SMWorkOrder, POCo, PO,
				NULL, NULL, NULL, NULL, NULL, NULL
			FROM dbo.vPOItemLine
			WHERE ItemType = 6
			UNION ALL
			SELECT SMCo, WorkOrder, POCo, PO,
				NULL, NULL, NULL, NULL, NULL, NULL
			FROM dbo.vSMWorkOrderPOHD
		) RelatedPOs ON vSMWorkOrder.SMCo = RelatedPOs.SMCo AND vSMWorkOrder.WorkOrder = RelatedPOs.WorkOrder
		LEFT JOIN dbo.POHD ON RelatedPOs.POCo = POHD.POCo AND RelatedPOs.PO = POHD.PO
	WHERE POHD.KeyID IS NOT NULL OR RelatedPOs.BatchSeq IS NOT NULL
GO
GRANT SELECT ON  [dbo].[SMPurchaseOrderList] TO [public]
GRANT INSERT ON  [dbo].[SMPurchaseOrderList] TO [public]
GRANT DELETE ON  [dbo].[SMPurchaseOrderList] TO [public]
GRANT UPDATE ON  [dbo].[SMPurchaseOrderList] TO [public]
GRANT SELECT ON  [dbo].[SMPurchaseOrderList] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMPurchaseOrderList] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMPurchaseOrderList] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMPurchaseOrderList] TO [Viewpoint]
GO
