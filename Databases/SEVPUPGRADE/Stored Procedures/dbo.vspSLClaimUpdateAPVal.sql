SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[vspSLClaimUpdateAPVal]
/****************************************************************************
* CREATED BY:	GF 10/22/2012 TK-18640 TK-18641 SL Claim Enhancement Update to AP
* MODIFIED BY:
*
*
* USAGE:
* run from SL claim update AP process form to validate a claim for update to
* AP Transaction Entry or AP Unapproved Invoices.
* 
* Validation may vary depending on process being updated.
*
* INPUT PARAMETERS:
* @SLCo				SL Company
* @Mth				AP Batch Month for update to AP Transaction Entry
* @BatchId			AP Batch ID for update to AP Transaction Entry
* @Subcontract		SL Subcontract
* @ClaimNo			SL Subcontract Claim No
* @ProcessName		SL Claim Process for update (SLClaimUpdateAPTrans or SLClaimUpdateAPUNAppr
* @PayCategory		AP Pay Catergory
* @PayType			AP Payment Type
* @UIMonth			AP Unapproved Invoice Month
*
*
* OUTPUT PARAMETERS:
* @Msg				success or error message
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@SLCo bCompany = NULL, @Mth bMonth = NULL, @BatchId bBatchID = NULL,
 @Subcontract VARCHAR(30) = NULL, @ClaimNo INT = NULL,
 @PayCategory INT = NULL, @SLPayType TINYINT = NULL,
 @ProcessName VARCHAR(128) = NULL, @UIMonth bMonth = NULL, 
 @Msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @OpenCursor INT, @PayType TINYINT, @APCoTaxbasisNetRetgYN bYN, 
		@HQCoDefaultCountry char(3), @APCoCSCMAcct bCMAcct, @APCoSubPayType TINYINT,
		@APRef bAPReference, @InvoiceDesc bDesc, @InvoiceDate bDate, @Claim_KeyId BIGINT,
		@Claim_UniqueAttchID uniqueidentifier, @VendorGroup bGroup, @Vendor bVendor,
		@JCCo bCompany, @Job bJob, @PayTerms bPayTerms, @HoldCode bHoldCode,

		@EFT CHAR(1), @V1099YN bYN, @V1099Type VARCHAR(10), @V1099Box TINYINT,
		@SeparatePayInvYN bYN, @VendorPayMethod CHAR(1), @PayMethod CHAR(1),
		@CMAcct bCMAcct, @APCoCMAcct bCMAcct, @VendorCMAcct bCMAcct, @CMCo bCompany,
		@DiscDate bDate, @DueDate bDate, @DiscRate bRate, @PayControl VARCHAR(10),
		@ErrorStart VARCHAR(100), @InUseMth bMonth, @InUseBatchId bBatchID,
		@InUseBy bVPUserName, @Source VARCHAR(30)

---- initialize flags
SET @rcode = 0
SET @OpenCursor = 0

---- must have a process
IF @ProcessName IS NULL
	BEGIN
	SET @Msg = 'Missing Process Name.'
	SET @rcode = 1
	GOTO vspexit
	END
	
---- must have required claim information
IF @SLCo IS NULL OR @Subcontract IS NULL OR @ClaimNo IS NULL
	BEGIN
	SET @Msg = 'Missing Key Fields.'
	SET @rcode = 1
	GOTO vspexit
	END

---- must have a month and batch id for AP Transaction entry
IF @ProcessName = 'SLClaimUpdateAPTrans' AND (@Mth IS NULL OR @BatchId IS NULL)
	BEGIN
	SET @Msg = 'Missing Batch Key Fields.'
	SET @rcode = 1
	GOTO vspexit
	END

---- get Company info
select  @APCoTaxbasisNetRetgYN = a.TaxBasisNetRetgYN,
		@CMCo = a.CMCo,
		@APCoCMAcct = a.CMAcct,
		@APCoCSCMAcct = a.CSCMAcct,
		@APCoSubPayType = a.SubPayType,
		@HQCoDefaultCountry = h.DefaultCountry
from dbo.bAPCO a
INNER JOIN dbo.bHQCO h ON h.HQCo=a.APCo
where APCo = @SLCo

---- get Sub Pay Type
IF @SLPayType IS NULL
	BEGIN
	SET @PayType = @APCoSubPayType
	END
ELSE
	BEGIN
	SET @PayType = @SLPayType
	END

---- build key part error message
SET @ErrorStart = 'Subcontract: ' + dbo.vfToString(@Subcontract) + ' Claim No: ' + dbo.vfToString(@ClaimNo) + ' - '


---- get subcontract and claim header information required to update to AP
select  @APRef=CLAIM.APRef, @InvoiceDesc=CLAIM.InvoiceDesc, @InvoiceDate=CLAIM.InvoiceDate,
		@Claim_UniqueAttchID=CLAIM.UniqueAttchID, @Claim_KeyId=CLAIM.KeyID,
		----SLHD
		@VendorGroup=SLHD.VendorGroup, @Vendor=SLHD.Vendor, @JCCo=SLHD.JCCo, @Job=SLHD.Job,
		@PayTerms=SLHD.PayTerms, @HoldCode=SLHD.HoldCode,
		@InUseMth=SLHD.InUseMth, @InUseBatchId=SLHD.InUseBatchId,
		----APVM
		@EFT=APVM.EFT, @V1099YN=APVM.V1099YN, @V1099Type=APVM.V1099Type, @V1099Box=APVM.V1099Box,
		@SeparatePayInvYN=APVM.SeparatePayInvYN, @VendorPayMethod=APVM.PayMethod,
		@PayControl=APVM.PayControl, @VendorCMAcct=APVM.CMAcct
from dbo.vSLClaimHeader CLAIM 
INNER JOIN dbo.SLHD SLHD ON SLHD.SLCo=CLAIM.SLCo and SLHD.SL=CLAIM.SL
INNER JOIN dbo.APVM APVM ON APVM.VendorGroup=SLHD.VendorGroup AND APVM.Vendor=SLHD.Vendor
where CLAIM.SLCo = @SLCo
	AND CLAIM.SL = @Subcontract
	AND CLAIM.ClaimNo = @ClaimNo
IF @@ROWCOUNT = 0
	BEGIN
	SET @Msg = @ErrorStart + 'Error retrieving Subcontract Claim information.'
	SET @rcode = 1
	GOTO vspexit
	END


---- CM Account
IF @VendorCMAcct IS NOT NULL
	BEGIN
	SET @CMAcct = @VendorCMAcct
	END
ELSE
	BEGIN
	SET @CMAcct = @APCoCMAcct
	END

---- set payment method variables
IF @VendorPayMethod = 'S'
	BEGIN
	SET @PayMethod='S'
	SET @SeparatePayInvYN = 'N'
	SET	@CMAcct = @APCoCSCMAcct
	END
ELSE IF @EFT='A'
	BEGIN
	SET @PayMethod='E'
	END
ELSE
	BEGIN
	SET @PayMethod='C'
	END


---- for AP Transaction Entry - need to validate pay terms
IF @ProcessName = 'SLClaimUpdateAPTrans'
	BEGIN

	---- need to check to see if the subcontract is in an open batch
	IF @InUseMth IS NOT NULL OR @InUseBatchId IS NOT NULL
		BEGIN
		IF @InUseMth <> @Mth OR @InUseBatchId <> @BatchId
			BEGIN
			SELECT @Source = [Source], @InUseBy = InUseBy
			FROM dbo.bHQBC 
			WHERE Co = @SLCo
				AND Mth = @InUseMth
				AND BatchId = @InUseBatchId 
			---- batch error message
			SET @Msg = @ErrorStart + 'already in open batch and must be processed first.'
					+  ' In Use By: ' + dbo.vfToString(@InUseBy)
					+  ', Batch Source: ' + dbo.vfToString(@Source)
					+  ', Batch Month: ' + CONVERT(VARCHAR(2),DATEPART(MONTH, @InUseMth)) + '/' + SUBSTRING(CONVERT(VARCHAR(4),DATEPART(YEAR, @InUseMth)), 3, 4)
					+  ', Batch Id: ' + dbo.vfToString(@InUseBatchId)
			SET @rcode = 1
			GOTO vspexit
			END
		END

	---- if no invoice date set to system date
	IF @InvoiceDate IS NULL SET @InvoiceDate = dbo.vfDateOnly()

	---- validate pay terms
	if @PayTerms IS NOT NULL
		BEGIN
		EXEC @rcode = dbo.bspHQPayTermsDateCalc @PayTerms, @InvoiceDate,
					@DiscDate OUTPUT, @DueDate OUTPUT, @DiscRate OUTPUT, @Msg OUTPUT
		IF @rcode = 1
			BEGIN
			SET @Msg = @ErrorStart + dbo.vfToString(@Msg)
			GOTO vspexit
			END
		END
	END
	
---- for AP Unapproved - make sure Job has at least one reviewer on it
IF @ProcessName = 'SLClaimUpdateAPUnapprove'
	BEGIN
	IF NOT EXISTS(SELECT 1 FROM dbo.vHQRD d JOIN dbo.bJCJM j ON d.ReviewerGroup=j.RevGrpInv
					WHERE j.JCCo = @JCCo AND j.Job = @Job)
		BEGIN
		IF NOT EXISTS(SELECT 1 FROM dbo.bJCJR WHERE	JCCo = @JCCo AND Job = @Job and ReviewerType IN (1,3))
			BEGIN
			SET @Msg = @ErrorStart + 'Job: ' + dbo.vfToString(@Job) + ' must have at least one reviewer assigned.'
			SET @rcode = 1
			GOTO vspexit
			END
		END
	END





	
vspexit:
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspSLClaimUpdateAPVal] TO [public]
GO
