SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[vspPMPOGetItemsForWorkFlowSubmit]
/************************************************************************
* Created By:	GF 05/04/2012 TK-14088 B-08882  
* Modified By:  GPT TK-16810 Sum over the POCo and PO for the aggregateAmount.  
*
* Purpose of Stored Procedure
* 1. Validate that there are PMMF PO Items that need to be reviewed
*	 to see if a work flow process is valid.
* 2. If there are PO Items, then a data set is returned that will
*	 be used to call into the work flow class to get a process
*	 and if true add the PO Item with reviewers to the WF process detail
*    
* Called from the submit button click in PM PO Header form
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
(@poKeyId AS BIGINT, @ErrMsg VARCHAR(500) OUTPUT)
AS
SET NOCOUNT ON
   
DECLARE @rcode INT, @POCo bCompany, @PO VARCHAR(30), @POItem bItem
   
SET @rcode = 0
SET @ErrMsg = ''

---- get POHD info
SELECT @POCo = POCo
		,@PO = PO
FROM dbo.bPOHD
WHERE KeyID = @poKeyId
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @ErrMsg = 'Invalid Purchase Order.', @rcode = 1
	GOTO vspexit
	END
	
---- check PMMF and see if there are any non interfaced items
SELECT @POItem = POItem
FROM dbo.bPMMF WHERE POCo=@POCo
	AND PO=@PO
	AND InterfaceDate IS NULL
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @ErrMsg = 'There are no PO Items that are not interfaced that need to be reviewed.', @rcode = 1
	GOTO vspexit
	END

---- check bPMMF and see if there are any items with an existing WF process
--SELECT @POItem = POItem
--FROM dbo.bPMMF a
--WHERE POCo=@POCo
--	AND PO=@PO
--	AND EXISTS(SELECT 1 FROM dbo.WFProcessDetailForPMMF w WHERE w.POCo=a.POCo AND w.PO=a.PO)
--IF @@ROWCOUNT <> 0
--	BEGIN
--	SELECT @ErrMsg = 'There are PO Items that have already been submitted for approval for this purchase order.', @rcode = 1
--	GOTO vspexit
--	END
	
---- check if only PO Items for a POCO exists. We are not doing change orders in work flow yet
SELECT @POItem = POItem
FROM dbo.bPMMF
WHERE POCo=@POCo
	AND PO=@PO
	AND InterfaceDate IS NULL
	AND POCONum IS NULL
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @ErrMsg = 'Only PO Change Order items exist for this PO and work flow is not used for change orders.', @rcode = 2
	GOTO vspexit
	END



---- return a list of PO Items from PMMF
SELECT  a.KeyID		AS [PMMFKeyId]
		,a.POItem	AS [PMMFPOItem]
		---- gets the aggregate amount for a PO by POCo, PO, PMCo, and Project
		,SUM(a.Amount) OVER(PARTITION BY a.POCo, a.PO) AS [aggregateAmount]
		,SUM(a.Amount) OVER(PARTITION BY a.POCo, a.PO) as [TotalAmount]
		,a.PMCo		AS [JCCo]
		,a.Project	AS [Job]
		,a.*
FROM dbo.bPMMF a
WHERE a.POCo=@POCo
	AND a.PO = @PO
	AND a.InterfaceDate IS NULL
	AND a.POCONum IS NULL
			


vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMPOGetItemsForWorkFlowSubmit] TO [public]
GO
