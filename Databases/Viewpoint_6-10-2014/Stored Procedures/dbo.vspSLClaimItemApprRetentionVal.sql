SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[vspSLClaimItemApprRetentionVal]
/***********************************************************
* CREATED BY:	GF 10/03/2012 TK-18302
* MODIFIED BY:	
* 
*
* USAGE:
* called from SL Subcontract Claim Items to validate the Approved
* Retention does not exceed maximum retention limits if applicable.
* We can assume that if the retention amount is changed that the claim
* nas not been sent to AP yet and needs to be validated against limits.
*
* 1. checks subcontract to see if maximum retention limits apply.
* 2. gets the maximum retention allowed for the subcontract
* 3. gets the retention taken amount from AP.
* 4. gets the old claim item retention amount
* 5. Does the math to see if the maximum retention limit has been exceeded.
* 
*
* INPUT PARAMETERS
* @SLCo				SL Company
* @Subcontract		Subcontract
* @ClaimNo			Subcontract Claim No
* @SLItem			Subcontract Ite
* @ItemNewRetention	Current SL item claim retention amount to validate against maximum allowed
*
*
* OUTPUT PARAMETERS
*
* @msg				error message returns error if maximum retention limits exceeded else nothing
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@SLCo bCompany = 0,
 @Subcontract varchar(30) = NULL,
 @ClaimNo INT = NULL,
 @SLItem SMALLINT = NULL,
 @ItemNewRetention bDollar = 0,
 @DisplayMsg VARCHAR(255) = NULL OUTPUT,
 @Msg varchar(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT,
		@SLRetBudget bDollar, @SLRetTaken bDollar, @SLRetRemain bDollar,
		@ClaimItemOldApprovedRet bDollar

SET @rcode = 0
SET @ClaimItemOldApprovedRet = 0

---- check if value changed
IF EXISTS(SELECT 1 FROM dbo.vSLClaimItem WHERE SLCo=@SLCo AND SL=@Subcontract
				AND ClaimNo=@ClaimNo AND ApproveRetention=@ItemNewRetention)
	BEGIN
	GOTO vspexit
	END


---- is subcontract maximum retention applicable - 'N' is none and we are done
IF EXISTS(SELECT 1 FROM dbo.bSLHD WITH (NOLOCK) WHERE SLCo = @SLCo AND SL = @Subcontract
				AND MaxRetgOpt = 'N')
	BEGIN
	GOTO vspexit
	END
	
---- get subcontract retention balances
SELECT @SLRetBudget = RetentionBudget
		,@SLRetTaken = RetentionTaken
		,@SLRetRemain = RetentionRemain
FROM dbo.vfSLClaimRetTotals (@SLCo, @Subcontract, @ClaimNo)

---- get old approved retention value for item if changing
SELECT @ClaimItemOldApprovedRet = ApproveRetention
FROM dbo.vSLClaimItem
WHERE SLCo = @SLCo
	AND SL = @Subcontract
	AND	ClaimNo = @ClaimNo
	AND SLItem = @SLItem

---- validate the claim item retention amount does not exceed limit
IF @SLRetTaken + @ItemNewRetention - @ClaimItemOldApprovedRet > @SLRetBudget
	BEGIN
	SET @SLRetRemain = ABS((@SLRetTaken + @ItemNewRetention - @ClaimItemOldApprovedRet) - @SLRetBudget)
	SET @DisplayMsg = 'Warning: You have exceeded the maximum retention limit for this subcontract by: $ ' + dbo.vfToString(@SLRetRemain) + '.' + CHAR(13) + CHAR(10)
	----SET @rcode = 1
	GOTO vspexit
	END




vspexit:
	RETURN @rcode




GO
GRANT EXECUTE ON  [dbo].[vspSLClaimItemApprRetentionVal] TO [public]
GO
