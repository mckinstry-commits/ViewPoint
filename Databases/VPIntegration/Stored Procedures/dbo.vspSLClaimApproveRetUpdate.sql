SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[vspSLClaimApproveRetUpdate]
/***********************************************************
* Created By:	GF 09/06/2012 TK-19583 SL Claims Enhancement
* Modified By:	
*
*
* USAGE:
* called from the SL Claims form after update event for the items grid
* This procedure will update the claim header approved retention to 
* the sum of the claim items approve retention.
*
*
* INPUT PARAMETERS
* SLCo   		SL Company
* SL    		Subcontract
* ClaimNo		CLaim Number
*
*
* OUTPUT PARAMETERS
*
* @msg				error message if error occurs or claim description
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@SLCo bCompany = NULL,
 @Subcontract VARCHAR(30) = NULL,
 @ClaimNo INT = NULL,
 @Msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT,
		@ClaimRetention bDollar, @ClaimItemRetention bDollar


SET @rcode = 0
SET @ClaimRetention = 0
SET @ClaimItemRetention = 0
SET @Msg = ''

---- check key values
IF @SLCo IS NULL OR @Subcontract IS NULL OR @ClaimNo IS NULL GOTO vspexit


---- claim header info
SELECT @ClaimRetention = ISNULL(ApproveRetention,0)
FROM dbo.vSLClaimHeader
WHERE SLCo = @SLCo
	AND SL = @Subcontract
	AND ClaimNo = @ClaimNo
IF @@ROWCOUNT = 0 GOTO vspexit

IF @ClaimRetention IS NULL SET @ClaimRetention = 0

---- get sum of claim item retention
SELECT @ClaimItemRetention = SUM(ISNULL(ApproveRetention,0))
FROM dbo.vSLClaimItem
WHERE SLCo = @SLCo
	AND SL = @Subcontract
	AND ClaimNo = @ClaimNo

IF @ClaimItemRetention IS NULL SET @ClaimItemRetention = 0

---- if no differenct between claim retention and sum of items then no distribution
IF @ClaimRetention = @ClaimItemRetention GOTO vspexit


---- update the SL Claim header approve retention with the sum from claim items
UPDATE dbo.vSLClaimHeader
	SET ApproveRetention = @ClaimItemRetention
WHERE SLCo = @SLCo
	AND SL = @Subcontract
	AND ClaimNo = @ClaimNo






vspexit:
	if @rcode <> 0 select @Msg = isnull(@Msg,'')
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspSLClaimApproveRetUpdate] TO [public]
GO
