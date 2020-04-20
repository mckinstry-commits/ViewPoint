SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/17/11
-- Description:	This will create a link record that will link a specific POHB batch record to a work order
--				so that we will be able to reserve POs for a work order and order needed parts against that PO.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkOrderLinkPO] 
	@POCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @BatchSeq int, @SMCo bCompany, @WorkOrder int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	INSERT INTO dbo.SMWorkOrderPOHB (POCo, BatchMth, BatchId, BatchSeq, SMCo, WorkOrder)
	VALUES (@POCo, @BatchMth, @BatchId, @BatchSeq, @SMCo, @WorkOrder)
    
END


GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderLinkPO] TO [public]
GO
