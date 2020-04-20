SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE procedure [dbo].[vspPOGetItemsForWorkFlowSubmit]
/************************************************************************
* Created By:	GF 04/21/2012 TK-14088 B-08882
* Modified By:  GP 4/27/2012 TK-14583 Added sum of entire PO  
*				GF 05/29/2012 TK-15146
*				GPT 08/02/2012 TK-16810 Sum over just the ItemType for AggregateAmount
*
* Purpose of Stored Procedure
* 1. Validate that there are Pending PurchaseOrder Items that need to be reviewed
*	 to see if a work flow process is valid.
* 2. If there are PO Items, then a data set is returned that will
*	 be used to call into the work flow class to get a process
*	 and if true add the PO Item with reviewers to the WF process detail
*    
* Called from the submit button click in PO Pending PUrchase Order form
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
(@POCo bCompany, @PO VARCHAR(30), @ListOnly VARCHAR(1), @ErrMsg VARCHAR(500) OUTPUT)
AS
SET NOCOUNT ON
   
DECLARE @rcode INT, @POItem bItem
   
SET @rcode = 0
SET @ErrMsg = ''
 
IF @POCo IS NULL
	BEGIN
   	select @ErrMsg = 'Missing PO Company!', @rcode = 1
   	GOTO vspexit
   	END
   
if @PO is null
	BEGIN
	SELECT @ErrMsg = 'Missing Purchase Order!', @rcode = 1
	GOTO vspexit
	END
 
---- validate PO
IF NOT EXISTS(SELECT 1 FROM dbo.vPOPendingPurchaseOrder WHERE POCo=@POCo AND PO=@PO)
	BEGIN
	SELECT @ErrMsg = 'Invalid Purchase order!', @rcode = 1
	GOTO vspexit
	END
   
---- check vPOPendingPurchaseOrderItem and see if there are any non interfaced items
---- this check is only needed if we are going to insert approvers into work flow
IF ISNULL(@ListOnly,'N') = 'N'
	BEGIN
	SELECT @POItem = POItem
	FROM dbo.vPOPendingPurchaseOrderItem a
	WHERE a.POCo=@POCo
		AND a.PO=@PO
		AND a.ItemType <> 6
		AND EXISTS(SELECT 1 FROM dbo.WFProcessDetailForPO w WHERE w.POCo=a.POCo AND w.PO=a.PO)
	IF @@ROWCOUNT <> 0
		BEGIN
		SELECT @ErrMsg = 'There are Pending PO Items that have already been submitted for approval for this purchase order.', @rcode = 1
		GOTO vspexit
		END
	END
	
---- return a list of PO Items from PMMF
SELECT  a.KeyID		AS [POPendingItemKeyId]
		,a.POItem	AS [POPendingItem]
		,a.ItemType AS [POPendingItemType]
		---- gets the aggregate amount for a PO by POCo, PO, and Item Type key parts
		, SUM(a.OrigCost) OVER(PARTITION BY a.POCo, a.PO, a.ItemType) AS [aggregateAmount]
		, SUM(a.OrigCost) OVER(PARTITION BY a.POCo, a.PO) as [TotalAmount]
		, a.*
FROM dbo.vPOPendingPurchaseOrderItem a
WHERE a.POCo=@POCo
	AND a.PO = @PO
	AND a.ItemType <> 6
ORDER BY a.POItem





vspexit:
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspPOGetItemsForWorkFlowSubmit] TO [public]
GO
