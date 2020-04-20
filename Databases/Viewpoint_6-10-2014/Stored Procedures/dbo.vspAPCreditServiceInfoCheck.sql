SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspAPCreditServiceInfoCheck]
/***************************************************
* CREATED BY    : KK 04/09/12
* Modified by	: 
*
* Usage: Checks that all necessary information needed for valid AP Payment Method has been 
*		 entered in AP Company and AP Vendor and returns various possible warnings to frmCreditServiceExportFileGen
*
* Input:
*	@apco         AP Company
*	@vendorgrp	  Vendor Group
*	@vendor		  Vendor Code
*
* Output:
*   @msg          error message
*
* Returns:
*	0             success
*   1             error
*************************************************/
(@cmco bCompany = 0,
 @cmacct bCMAcct = NULL,
 @apco bCompany = NULL,
 @mth bMonth = NULL,
 @batchid bBatchID = NULL, 
 @msg varchar(255) OUTPUT)
 
AS
SET NOCOUNT ON

--Get the vendor information from the parameters received

DECLARE @vendor bVendor,
		@vendorgrp bGroup
		
SELECT @vendor = Vendor,
	   @vendorgrp = VendorGroup
FROM APPB
WHERE CMCo = @cmco 
  AND CMAcct = @cmacct 
  AND Co = @apco 
  AND Mth = @mth 
  AND BatchId = @batchid
  
IF @@rowcount = 0 
BEGIN
	SELECT @msg = 'No credit service sequences were processed.'
	RETURN 1
END

--Final Credit Service Validation of Vendor and Company setup

DECLARE	@returncode int,
		@paymethod char(1),
		@paymethodvalerror varchar(255)

--Set Pay Method type to Credit Service
SELECT @paymethod = 'S'

--Perform validation
EXEC	@returncode = [dbo].[vspAPPayMethodInfoCheck]
		@apco,
		@vendorgrp,
		@vendor,
		@paymethod,
		@msg = @paymethodvalerror OUTPUT

--Returned error message is only important if an error was returned
IF @returncode = 0 SELECT @paymethodvalerror = NULL 

--Error detected, Send back the message
IF @paymethodvalerror IS NOT NULL
BEGIN
	SELECT @msg = @paymethodvalerror
	RETURN 1
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspAPCreditServiceInfoCheck] TO [public]
GO
