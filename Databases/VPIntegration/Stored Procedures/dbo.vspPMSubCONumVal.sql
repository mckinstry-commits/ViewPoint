SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************/
CREATE proc [dbo].[vspPMSubCONumVal]
/*************************************
 * Created By:	GF 06/15/2011 TK-06039
 * Modified by:
 *
 * called from PM PCO Create SL Change Order to validate the SubCO Number
 * if adding to existing.
 *
 * SubCO Number must exist in PMSubcontractCO and must be unapproved.
 *
 * Pass:
 * SLCo			SL Company
 * SL			Subcontract
 * SubCO		PM Subcontrct Change Order
 *
 * Returns:
 * @Approved	Flag to indicate if the SubCO has been approved.
 * Success returns:
 * 0 and Description from PMSubcontractCO
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@SLCo bCompany = NULL, @SL VARCHAR(30) = NULL, @SubCO smallint = NULL,
 @Approved char(1) = 'N' OUTPUT, @msg varchar(255) output)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @SubCOKeyID BIGINT, @retcode INT, @errmsg VARCHAR(255)

SET @rcode = 0

IF @SLCo IS NULL
	BEGIN
	SELECT @msg = 'Missing SL Company', @rcode = 1
	GOTO vspexit
	END

IF @SL IS NULL
	BEGIN
	SELECT @msg = 'Missing Subcontract', @rcode = 1
	GOTO vspexit
	END
	
IF @SubCO IS NULL
	BEGIN
	SELECT @msg = 'Missing SubCO Number', @rcode = 1
	GOTO vspexit
	END
	
	
---- validate the SubCO number to PMSubcontractCO
SELECT @SubCOKeyID = KeyID,@msg = [Description]
FROM dbo.PMSubcontractCO
WHERE SLCo = @SLCo
	AND SL = @SL
	AND SubCO = @SubCO
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @msg = 'SubCO Number does not exist for the Subcontract', @rcode = 1
	GOTO vspexit
	END

---- get approved status for the SubCO Number
EXEC @retcode = dbo.vspPMSubcontractChangeOrderSCOStatus @SubCOKeyID, @Approved OUTPUT, @errmsg output
---- if approved cannot add too
IF ISNULL(@Approved,'N') = 'Y'
	BEGIN
	SELECT @msg = 'The SubCO Number has been approved - cannot be modified.', @rcode = 1
	GOTO vspexit
	END





vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSubCONumVal] TO [public]
GO
