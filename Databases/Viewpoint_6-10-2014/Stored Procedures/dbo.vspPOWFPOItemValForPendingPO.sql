SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  proc [dbo].[vspPOWFPOItemValForPendingPO]
/*************************************
 * Created By:	GF 04/21/2012 TK-14088 B-08882
 * Modified by:
 *
 * called from POItemReviewers to validate the work flow PO for PendingPurchaseOrderItem sources
 *
 * Pass:
 * POCo			PO Company
 * PO			PO Pending
 * POItem		PO Item
 *
 * Returns:
 *
 *
 * Success returns:
 *	0 or 1 and error message
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@POCo bCompany, @PO varchar(30), @POItem bItem, @Msg varchar(255) output)
AS
SET NOCOUNT ON

DECLARE @rcode INT

SET @rcode = 0

---- validate that the PO Item exists in the work flow for PendingPurchaseOrderItem
IF NOT EXISTS(SELECT 1 FROM dbo.WFProcessDetailForPO WHERE POCo = @POCo
				AND PO = @PO AND POItem = @POItem)
	BEGIN
	SET @Msg = 'Invalid: There are no current reviewers in work flow for this purchase order item.'
	SET @rcode = 1
	GOTO vspexit
	END
	
---- validate PO Item and get description
SELECT @Msg = [Description]
FROM dbo.POPendingPurchaseOrderItem
WHERE POCo = @POCo
	AND PO = @PO
	AND POItem = @POItem
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @Msg = 'Invalid Purchase Order Item.', @rcode = 1
	GOTO vspexit
	END


vspexit:
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspPOWFPOItemValForPendingPO] TO [public]
GO
