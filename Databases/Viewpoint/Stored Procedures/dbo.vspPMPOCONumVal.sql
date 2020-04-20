SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************/
CREATE  proc [dbo].[vspPMPOCONumVal]
/*************************************
 * Created By:	GF 06/15/2011 TK-06039
 * Modified by:	GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
 *
 * called from PM PCO Create PO Change Order to validate the POCO Number
 * if adding to existing.
 *
 * POCO Number must exist in PMPOCO and must be unapproved.
 *
 * Pass:
 * POCo			PO Company
 * PO			Purchase Order
 * PONum		PM PO Change Order
 *
 * Returns:
 * @Approved	Flag to indicate if the POCO Number has been approved.
 * Success returns:
 * 0 and Description from PMPOCO
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@POCo bCompany = NULL, @PO varchar(30) = NULL, @POCONum smallint = NULL,
 @Approved char(1) = 'N' OUTPUT, @msg varchar(255) output)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @POCOKeyID BIGINT, @retcode INT, @errmsg VARCHAR(255)

SET @rcode = 0

IF @POCo IS NULL
	BEGIN
	SELECT @msg = 'Missing PO Company', @rcode = 1
	GOTO vspexit
	END

IF @PO IS NULL
	BEGIN
	SELECT @msg = 'Missing PO', @rcode = 1
	GOTO vspexit
	END
	
IF @POCONum IS NULL
	BEGIN
	SELECT @msg = 'Missing POCO Number', @rcode = 1
	GOTO vspexit
	END
	
	
---- validate the POCO number to PMPOCO
SELECT @POCOKeyID = KeyID,@msg = [Description]
FROM dbo.PMPOCO
WHERE POCo = @POCo
	AND PO = @PO
	AND POCONum = @POCONum
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @msg = 'POCO Number does not exist for the Purchase order', @rcode = 1
	GOTO vspexit
	END

---- get approved status for the POCO Number
EXEC @retcode = dbo.vspPMPOChangeOrderPOCOStatus @POCOKeyID, @Approved OUTPUT, @errmsg output
---- if approved cannot add too
IF ISNULL(@Approved,'N') = 'Y'
	BEGIN
	SELECT @msg = 'The POCO Number has been approved - cannot be modified.', @rcode = 1
	GOTO vspexit
	END





vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPOCONumVal] TO [public]
GO
