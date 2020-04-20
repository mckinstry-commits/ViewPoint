SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  proc [dbo].[vspPOWFPOValForPendingPO]
/*************************************
 * Created By:	GF 04/21/2012 TK-14088 B-08882
 * Modified by:
 *
 * called from POItemReviewers to validate the work flow PO for PendingPurchaseOrder sources
 *
 * Pass:
 * POCo			PO Company
 * PO			PO Pending Purchase Order
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
(@POCo bCompany, @PO varchar(30), @Msg varchar(255) output)
AS
SET NOCOUNT ON

DECLARE @rcode INT

SET @rcode = 0

---- validate that the PO exists in the work flow process for PendingPurchaseOrderItem
IF NOT EXISTS(SELECT 1 FROM dbo.WFProcessDetailForPO WHERE POCo = @POCo AND PO = @PO)
	BEGIN
	SET @Msg = 'Invalid: There are no current reviewers in work flow for this purchase order.'
	SET @rcode = 1
	GOTO vspexit
	END
	
---- validate PO and get description
SELECT @Msg = Description
FROM dbo.POPendingPurchaseOrder
WHERE POCo = @POCo
	AND PO = @PO
IF @@ROWCOUNT = 0
	BEGIN
	SET @Msg = 'Invalid Purchase Order.'
	SET @rcode = 1
	GOTO vspexit
	END


vspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPOWFPOValForPendingPO] TO [public]
GO