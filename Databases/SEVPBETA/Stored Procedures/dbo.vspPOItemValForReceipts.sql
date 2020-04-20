SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.vspPOItemValForReceipts    Script Date: 8/28/99 9:35:46 AM ******/
CREATE   proc [dbo].[vspPOItemValForReceipts]
/***********************************************************
* CREATED BY:	GF 08/21/2011 TK-07150 ??
* MODIFIED BY:
*
* Used by PO Receipts form to validate PO Item
*
* INPUT PARAMETERS
* @POCo        PO Company
* @POo         PO to validate
* @POItem      PO Item to validate
*
* OUTPUT PARAMETERS
* @POItemLine	Default for PO Item. Will be 1 or NULL.
* @Msg          Item description or error message
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/   
(@POCo bCompany = NULL, @PO VARCHAR(30) = NULL, @POItem bItem = NULL, 
 @POItemLine INT = NULL OUTPUT, @Msg varchar(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @RecvYN CHAR(1)

SET @rcode = 0
SET @POItemLine = NULL

IF @POCo IS NULL
 	BEGIN
 	SELECT @Msg = 'Missing PO Company!', @rcode = 1
 	GOTO vspexit
 	END
 	
IF @PO IS NULL
 	BEGIN
 	SELECT @Msg = 'Missing PO!', @rcode = 1
 	GOTO vspexit
 	END
 	
IF @POItem IS NULL
 	BEGIN
 	SELECT @Msg = 'Missing po Item#!', @rcode = 1
 	GOTO vspexit
 	END


---- validate PO Item and get info
SELECT @RecvYN = RecvYN, @Msg = Description
FROM dbo.POIT
WHERE POCo = @POCo
	AND PO = @PO
	AND POItem = @POItem
IF @@ROWCOUNT = 0
 	BEGIN
 	SELECT @Msg = 'invalid PO Item ', @rcode = 1
 	GOTO vspexit
 	END

IF @RecvYN = 'N'
	BEGIN
	SELECT @Msg = 'PO Item is not flagged to be received.', @rcode = 1
	GOTO vspexit
	END

---- check if we only have one line for the item and if so return 1 as default
IF (SELECT COUNT(POItemLine) FROM dbo.POItemLine WHERE POCo=@POCo AND PO=@PO AND POItem=@POItem) = 1
	BEGIN
	SET @POItemLine = 1
	END

 	

vspexit:  
	RETURN @rcode
     	
     	
GO
GRANT EXECUTE ON  [dbo].[vspPOItemValForReceipts] TO [public]
GO
