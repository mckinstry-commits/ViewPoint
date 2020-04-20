SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspSLClaimSLVal]
/***********************************************************
* Created By:	GF 09/14/2012 TK-17944
* Modified By:	
*
*
* USAGE:
* validates Subcontracts from SLHD and returns the description.
* an error is returned if any of the following occurs:
* Missing SL Company
* Missing Subcontract
* Invalid Subcontract
* Subcontract Status is not open
*
*
* INPUT PARAMETERS
* SLCo   		SL Co to validate against
* SL    		Subcontract to validate
* StatusString	Comma deliminated string for status check.
*
*
* OUTPUT PARAMETERS
* @Status			Staus of subcontract
* @VendorGroup		SLHD Vendor Group
* @Vendor			SLHD Vendor
* @MaxRetgOpt		SLHD Maximum Retention Option
* @ApprovalReq		SLHD Approval Required flag
* @msg				error message if error occurs otherwise Description of Project
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@SLCo bCompany = NULL, @SL VARCHAR(30) = NULL, @StatusString varchar(20) = null,
 @Status TINYINT = 0 OUTPUT, @VendorGroup bGroup = NULL OUTPUT,
 @Vendor bVendor = NULL OUTPUT, @MaxRetgOpt CHAR(1) = 'N' OUTPUT,
 @ApprovalReq bYN = 'N' OUTPUT, @Msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT

SET @rcode = 0

if @SLCo IS NULL
	BEGIN
   	SELECT @Msg = 'Missing SL Company!', @rcode = 1
   	GOTO vspexit
   	END

if @SL IS NULL
   	BEGIN
   	SELECT @Msg = 'Missing project!', @rcode = 1
   	GOTO vspexit
   	END

---- get job information
SELECT  @Msg=Description, @Status=Status,
		@VendorGroup = VendorGroup,
		@Vendor = Vendor,
		@MaxRetgOpt = MaxRetgOpt,
		@ApprovalReq = ApprovalRequired
FROM dbo.SLHD
WHERE SLCo = @SLCo
	AND SL = @SL
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @Msg = 'Subcontract not on file!', @rcode = 1
	GOTO vspexit
	END

---- Check to see if the status on this subcontract is contained in the string passed in
IF CHARINDEX(CONVERT(VARCHAR, @Status), @StatusString) = 0
	BEGIN
	SELECT @Msg = 'Invalid status on Subcontract. Status: '
	SELECT @Msg = @Msg + CASE WHEN @Status = 0 THEN 'Open !'
		 				WHEN @Status = 1 THEN 'Completed !'
		 				WHEN @Status = 2 THEN 'Closed !'
		 				ELSE 'Pending !' END
	SET @rcode = 1
	GOTO vspexit
	END



vspexit:
	if @rcode <> 0 select @Msg = isnull(@Msg,'')
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspSLClaimSLVal] TO [public]
GO
