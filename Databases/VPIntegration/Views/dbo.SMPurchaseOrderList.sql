SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMPurchaseOrderList]
AS

--With this CTE we get all the related data for the POs based on whether they are in a batch or not
WITH ExisitingRelatedPOs
AS
 (
	SELECT SMRelatedPOs.*, POHD.[Status], POHD.OrderDate, POHD.VendorGroup, POHD.Vendor, POHD.[Description], POHB.Mth, POHB.BatchId, POHB.BatchSeq
	FROM
	(
		SELECT SMCo, WorkOrder, POCo, PO
			FROM dbo.SMWorkOrderPOHD
		UNION
		SELECT POItemLine.SMCo, POItemLine.SMWorkOrder WorkOrder, POIT.POCo, POIT.PO
			FROM dbo.POIT
			LEFT JOIN dbo.POItemLine 
				ON POItemLine.POCo=POIT.POCo
				AND POItemLine.PO=POIT.PO
				AND POItemLine.POItem=POIT.POItem
		WHERE POItemLine.ItemType = 6
		--UNION -- Used for finding out if a Job is related TK-14417
		--SELECT SMWorkOrder.SMCo, SMWorkOrder.WorkOrder, POItemLine.POCo, POItemLine.PO
		--FROM SMWorkOrder
		--	INNER JOIN POItemLine ON POItemLine.JCCo = SMWorkOrder.JCCo AND POItemLine.Job = SMWorkOrder.Job
		--UNION 
		--SELECT SMWorkOrder.SMCo, SMWorkOrder.WorkOrder, POHD.POCo, POHD.PO
		--FROM SMWorkOrder
		--	INNER JOIN POHD ON POHD.JCCo = SMWorkOrder.JCCo AND POHD.Job = SMWorkOrder.Job
	) SMRelatedPOs
		INNER JOIN dbo.POHD ON SMRelatedPOs.POCo = POHD.POCo AND SMRelatedPOs.PO = POHD.PO
		LEFT JOIN dbo.POHB ON POHD.POCo = POHB.Co AND POHD.InUseMth = POHB.Mth AND POHD.InUseBatchId = POHB.BatchId
),
AllSMRelatedPOsWithRelatedData
AS
(
	SELECT SMRelatedPOBatches.SMCo, SMRelatedPOBatches.WorkOrder, SMRelatedPOBatches.POCo, POHB.PO, POHB.[Status], POHB.OrderDate, POHB.VendorGroup, POHB.Vendor, POHB.[Description], 1 AS IsFromBatch
	FROM
	(
		SELECT SMCo, WorkOrder, POCo, Mth, BatchId, BatchSeq
		FROM ExisitingRelatedPOs
		WHERE Mth IS NOT NULL AND BatchId IS NOT NULL AND BatchSeq IS NOT NULL
		UNION
		SELECT SMCo, WorkOrder, POCo, BatchMth, BatchId, BatchSeq
		FROM dbo.SMWorkOrderPOHB
		UNION
		SELECT SMCo, SMWorkOrder, Co, Mth, BatchId, BatchSeq
		FROM POIB
		WHERE ItemType = 6
	) SMRelatedPOBatches
		INNER JOIN POHB ON SMRelatedPOBatches.POCo = POHB.Co AND SMRelatedPOBatches.Mth = POHB.Mth AND SMRelatedPOBatches.BatchId = POHB.BatchId
	UNION
	SELECT ExisitingRelatedPOs.SMCo, ExisitingRelatedPOs.WorkOrder, ExisitingRelatedPOs.POCo, ExisitingRelatedPOs.PO, ExisitingRelatedPOs.[Status], ExisitingRelatedPOs.OrderDate, ExisitingRelatedPOs.VendorGroup, ExisitingRelatedPOs.Vendor, ExisitingRelatedPOs.[Description], 0 AS IsFromBatch
	FROM ExisitingRelatedPOs
)

--The POs may have duplicates from our CTE so to make sure we display a PO only once use a select distinct
--Then in order to get related PO data we use a select top 1 from our CTE. We order it by the IsFromBatch so
--that if a PO is in a batch we show the POHD data before showing the batch data. There is the possibility that
--a PO is in multiple batches (this shouldn't happen but the database doesn't prevent it.) so by using a top 1
--it will retrieve the first instance of that PO that it comes across.
SELECT * 
FROM
	(SELECT DISTINCT SMCo, WorkOrder, POCo, PO
	FROM AllSMRelatedPOsWithRelatedData) DistinctPOs
CROSS APPLY 
	(SELECT TOP 1 [Status], OrderDate, VendorGroup, Vendor, [Description], IsFromBatch
	FROM AllSMRelatedPOsWithRelatedData
	WHERE DistinctPOs.SMCo = AllSMRelatedPOsWithRelatedData.SMCo AND DistinctPOs.WorkOrder = AllSMRelatedPOsWithRelatedData.WorkOrder
		AND DistinctPOs.POCo = AllSMRelatedPOsWithRelatedData.POCo AND DistinctPOs.PO = AllSMRelatedPOsWithRelatedData.PO
	ORDER BY IsFromBatch) PORelatedData







GO
GRANT SELECT ON  [dbo].[SMPurchaseOrderList] TO [public]
GRANT INSERT ON  [dbo].[SMPurchaseOrderList] TO [public]
GRANT DELETE ON  [dbo].[SMPurchaseOrderList] TO [public]
GRANT UPDATE ON  [dbo].[SMPurchaseOrderList] TO [public]
GO
