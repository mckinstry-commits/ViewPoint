SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[vspSLClaimUpdateAP]
/****************************************************************************
* CREATED BY:	GF 10/22/2012 TK-18640 TK-18641 SL Claim Enhancement Update to AP
* MODIFIED BY:
*
*
* USAGE:
* run from SL claim update process forms to update AP Transaction Entry or AP Unapproved Invoices
* with claim information.
*
* INPUT PARAMETERS:
* @SLCo				SL Company
* @Mth				AP Batch Month for update to AP Transaction Entry
* @BatchId			AP Batch ID for update to AP Transaction Entry
* @Subcontract		SL Subcontract
* @ClaimNo			SL Subcontract Claim No
* @ProcessName		SL Claim Process for update (SLClaimUpdateAPTrans or SLClaimUpdateAPUnapprove
* @PayCategory		AP Pay Catergory
* @PayType			AP Payment Type
* @UIMonth			AP Unapproved Invoice Month
*
*
* OUTPUT PARAMETERS:
* @APHBKeyId			APHB.KeyId needed to copy claim attachments
* @APUIKeyId			APUI.KeyId needed to copy claim attachments
* @ClaimUniqueAttchId	SL Claim Header attachment id for attachment copy
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
 @Claim_KeyId BIGINT = NULL OUTPUT,
 @APHB_KeyId BIGINT = NULL OUTPUT,
 @APUI_KeyId BIGINT = NULL OUTPUT,
 @ClaimUniqueAttchId VARCHAR(500) = NULL OUTPUT,
 @Msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @OpenCursor INT, @PayType TINYINT, @APCoTaxbasisNetRetgYN bYN, 
		@HQCoDefaultCountry char(3), @APCoCSCMAcct bCMAcct, @APCoSubPayType TINYINT,
		@APRef bAPReference, @InvoiceDesc bDesc, @InvoiceDate bDate,
		@VendorGroup bGroup, @Vendor bVendor, @JCCo bCompany, @Job bJob,
		@PayTerms bPayTerms, @HoldCode bHoldCode, @ClaimDate bDate,

		@EFT CHAR(1), @V1099YN bYN, @V1099Type VARCHAR(10), @V1099Box TINYINT,
		@SeparatePayInvYN bYN, @VendorPayMethod CHAR(1), @PayMethod CHAR(1),
		@CMAcct bCMAcct, @APCoCMAcct bCMAcct, @VendorCMAcct bCMAcct, @CMCo bCompany,
		@DiscDate bDate, @DueDate bDate, @DiscRate bRate, @PayControl VARCHAR(10),
		@ReviewerGroup VARCHAR(10), @ErrorStart VARCHAR(100), @ClaimNotes VARCHAR(MAX),
		
		@Seq INT, @UISeq INT, @InvoiceTotal bDollar, @TotalApprove bDollar,
		@TotalTax bDollar, @TotalRetention bDollar,

		@SLItem bItem, @CurUnitCost bUnitCost, @ApproveUnits bUnits, @ApproveAmount bDollar,
		@ApproveRetention bDollar, @TaxAmount bDollar, @TaxBasis bDollar, @TaxRate bRate,
		@InvLineDesc bDesc, @ClaimItem_KeyId BIGINT, @TaxGroup bGroup, @TaxType TINYINT,
		@TaxCode bTaxCode, @ClaimItemNotes VARCHAR(MAX), @UM bUM, @ItemJCCo bCompany,
		@ItemJob bJob, @PhaseGroup bGroup, @Phase bPhase, @JCCType bJCCType, @GLCo bCompany,
		@GLAcct bGLAcct, @SupplierVendorGroup bGroup, @Supplier bVendor, @JCGLAcct bGLAcct,
		@GLCostOverride bYN, @APLine SMALLINT, @APLB_KeyId BIGINT, @APUL_KeyId BIGINT



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

---- set error start 
SELECT @ErrorStart = 'Subcontract: ' + dbo.vfToString(@Subcontract) + ' Claim No: ' + dbo.vfToString(@ClaimNo) + ' - '

---- get subcontract and claim header information required to update to AP
select  @APRef=CLAIM.APRef, @InvoiceDesc=CLAIM.InvoiceDesc,
		@InvoiceDate=CLAIM.InvoiceDate, @Claim_KeyId=CLAIM.KeyID,
		@ClaimUniqueAttchId = CLAIM.UniqueAttchID, @ClaimDate = CLAIM.ClaimDate,
		----SLHD
		@VendorGroup=SLHD.VendorGroup, @Vendor=SLHD.Vendor, @JCCo=SLHD.JCCo, @Job=SLHD.Job,
		@PayTerms=SLHD.PayTerms, @HoldCode=SLHD.HoldCode,
		----APVM
		@EFT=APVM.EFT, @V1099YN=APVM.V1099YN, @V1099Type=APVM.V1099Type, @V1099Box=APVM.V1099Box,
		@SeparatePayInvYN=APVM.SeparatePayInvYN, @VendorPayMethod=APVM.PayMethod,
		@PayControl=APVM.PayControl, @VendorCMAcct=APVM.CMAcct
from dbo.vSLClaimHeader CLAIM 
INNER JOIN dbo.bSLHD SLHD ON SLHD.SLCo=CLAIM.SLCo and SLHD.SL=CLAIM.SL
INNER JOIN dbo.bAPVM APVM ON APVM.VendorGroup=SLHD.VendorGroup AND APVM.Vendor=SLHD.Vendor
where CLAIM.SLCo = @SLCo
	AND CLAIM.SL = @Subcontract
	AND CLAIM.ClaimNo = @ClaimNo
	--AND SLHD.InUseMth IS NULL
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

		
---- update to AP Transaction Entry
---- if invoice date is null use system date
IF @InvoiceDate IS NULL SET @InvoiceDate = dbo.vfDateOnly()

---- validate pay terms
if @PayTerms IS NOT NULL
	BEGIN
	EXEC @rcode = dbo.bspHQPayTermsDateCalc @PayTerms, @InvoiceDate,
				@DiscDate OUTPUT, @DueDate OUTPUT, @DiscRate OUTPUT, @Msg OUTPUT
	IF @rcode = 1
		BEGIN
		SELECT @Msg = @ErrorStart + dbo.vfToString(@Msg)
		GOTO vspexit
		END
	END

---- if due date is null use system date
IF @DueDate IS NULL SET @DueDate = @InvoiceDate
	

---- update to AP Unapproved invoices
IF @ProcessName = 'SLClaimUpdateAPUnapprove'
	BEGIN
	---- make sure Job has at least one reviewer on it
	IF NOT EXISTS(SELECT 1 FROM dbo.vHQRD d JOIN dbo.bJCJM j ON d.ReviewerGroup=j.RevGrpInv
					WHERE j.JCCo = @JCCo AND j.Job = @Job)
		BEGIN
		IF NOT EXISTS(SELECT 1 FROM dbo.bJCJR WHERE	JCCo = @JCCo AND Job = @Job
						AND ReviewerType IN (1,3))
			BEGIN
			SELECT @Msg = @ErrorStart + 'must have at least one reviewer assigned.'
			SET @rcode = 1
			GOTO vspexit
			END
		END
		
	---- get reviewer group from job
	SELECT @ReviewerGroup = RevGrpInv
	FROM dbo.bJCJM 
	WHERE JCCo = @JCCo
		AND Job = @Job
	END


---- Invoice Total is the sum of approved amount + Tax
---- unless international tlen less retention
---- Tax Amount is only valid when tax type <> 2 - use
---- get tax amount
SELECT @TotalTax = ISNULL(SUM(TaxAmount),0)
FROM dbo.vSLClaimItem 
WHERE SLCo = @SLCo
	AND SL = @Subcontract
	AND ClaimNo = @ClaimNo
	AND TaxCode IS NOT NULL
	AND TaxType <> 2

---- get approve amount and retention amount
SELECT @TotalApprove = ISNULL(SUM(ApproveAmount),0)
	  ,@TotalRetention = ISNULL(SUM(ApproveRetention),0)
FROM dbo.vSLClaimItem 
WHERE SLCo = @SLCo
	AND SL = @Subcontract
	AND ClaimNo = @ClaimNo
	
---- set invoice total
IF @HQCoDefaultCountry = 'US'
	BEGIN
	SELECT @InvoiceTotal = ISNULL(@TotalApprove,0) + ISNULL(@TotalTax,0)
	END
ELSE
	BEGIN
	SELECT @InvoiceTotal = ISNULL(@TotalApprove,0) - ISNULL(@TotalRetention,0) + ISNULL(@TotalTax,0)
	END




BEGIN TRY
	---- start a transaction, commit after fully processed
    BEGIN TRANSACTION;

	---- insert AP Transaction Batch Header (APHB)
	IF @ProcessName = 'SLClaimUpdateAPTrans'
		BEGIN
		
		---- get next available sequence # for the batch
		SELECT @Seq = isnull(max(BatchSeq), 0) + 1
		FROM dbo.bAPHB
		WHERE Co = @SLCo
			AND Mth = @Mth
			AND BatchId = @BatchId
	     		
		---- insert APHB
		INSERT dbo.bAPHB (Co, Mth, BatchId, BatchSeq, BatchTransType, VendorGroup, Vendor, APRef,
				[Description], InvDate, DiscDate, DueDate, InvTotal, HoldCode, PayControl,
				PayMethod, CMCo, CMAcct, PrePaidYN, V1099YN, V1099Type, V1099Box, PayOverrideYN,
				SLKeyID, SeparatePayYN, Notes)
		VALUES (@SLCo ,@Mth, @BatchId, @Seq, 'A', @VendorGroup, @Vendor, @APRef,
				@InvoiceDesc, @InvoiceDate, @DiscDate, @DueDate, @InvoiceTotal, @HoldCode, @PayControl,
				@PayMethod, @CMCo, @CMAcct, 'N', @V1099YN, @V1099Type, @V1099Box, 'N',
				@Claim_KeyId, @SeparatePayInvYN, @ClaimNotes)

		---- get key id
		SET @APHB_KeyId = SCOPE_IDENTITY()	
		
		---- update user memos from SLClaimHeader to APHB
		exec @rcode = dbo.bspBatchUserMemoUpdate @SLCo , @Mth , @BatchId , @Seq, 'SLClaim', @Msg OUTPUT
		if @rcode <> 0 
			BEGIN
			SELECT @Msg = @ErrorStart + dbo.vfToString(@Msg)
			IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
			GOTO vspexit
			END

		END

	---- insert AP Unapproved Invoice (APUI)
	IF @ProcessName = 'SLClaimUpdateAPUnapprove'
		BEGIN
		
		---- Get next AP UISeq
		EXEC @rcode = dbo.vspAPUIGetNextSeq @SLCo, @UIMonth, @UISeq OUTPUT, @Msg OUTPUT								

		----Check if header already exists.
		IF NOT EXISTS(SELECT 1 FROM dbo.bAPUI WHERE APCo = @SLCo AND UIMth = @UIMonth AND UISeq = @UISeq)
			BEGIN
			INSERT dbo.bAPUI(APCo, UIMth, UISeq, VendorGroup, Vendor, InvTotal, CMCo, V1099YN,
					SeparatePayYN, V1099Type, V1099Box, PayOverrideYN, PayControl, PayMethod, APRef,
					[Description], InvDate, DiscDate, DueDate, CMAcct, HoldCode, Notes, SLKeyID)
			VALUES (@SLCo, @UIMonth, @UISeq, @VendorGroup, @Vendor, @InvoiceTotal, @CMCo, @V1099YN,
					@SeparatePayInvYN, @V1099Type, @V1099Box, 'N', @PayControl, @PayMethod, @APRef,
					@InvoiceDesc, @InvoiceDate, @DiscDate, @DueDate, @CMAcct, @HoldCode, @ClaimNotes, @Claim_KeyId)

			---- get key id
			SET @APUI_KeyId = SCOPE_IDENTITY()	
		
			---- update user memos from SLClaimHeader to APUI
			exec @rcode = dbo.bspBatchUserMemoUpdate @SLCo, NULL, NULL, NULL, 'SLClaimAPUnapprove', @Msg OUTPUT
			if @rcode <> 0 
				BEGIN
				SELECT @Msg = @ErrorStart + dbo.vfToString(@Msg)
				IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
				GOTO vspexit
				END	
			END

		END




	/*****************************************/
	/*		SL CLAIM ITEM SECTION            */
	/*****************************************/


	---- declare cursor on vSLClaimItem
	DECLARE cSLClaimItem CURSOR LOCAL FAST_FORWARD FOR
		SELECT ci.SLItem, ci.CurUnitCost, ci.ApproveUnits, ci.ApproveAmount,
				ci.ApproveRetention, ci.TaxAmount, ci.[Description], ci.KeyID, ci.TaxGroup,
				ci.TaxType, ci.TaxCode, ci.Notes,
				----SLIT
				i.UM, i.JCCo, i.Job, i.PhaseGroup, i.Phase, i.JCCType, i.GLCo,
				i.GLAcct, i.VendorGroup, i.Supplier
			
	FROM dbo.vSLClaimItem ci
	INNER JOIN dbo.vSLClaimHeader ch ON ch.SLCo=ci.SLCo AND ch.SL=ci.SL AND ch.ClaimNo=ci.ClaimNo
	INNER JOIN dbo.bSLHD h ON h.SLCo=ci.SLCo AND h.SL=ci.SL
	INNER JOIN dbo.bSLIT i ON i.SLCo=ci.SLCo AND i.SL=ci.SL AND i.SLItem=ci.SLItem
	WHERE ci.SLCo = @SLCo
		AND ci.SL = @Subcontract
		AND ci.ClaimNo = @ClaimNo
		AND ci.ApproveAmount <> 0 ---- exclude claim items with zero values

	----open
	OPEN cSLClaimItem
	SET @OpenCursor = 1

	----loop through all claim items
	cSLClaimItem_loop:
	FETCH NEXT FROM cSLClaimItem INTO @SLItem, @CurUnitCost, @ApproveUnits, @ApproveAmount,
				@ApproveRetention, @TaxAmount, @InvLineDesc, @ClaimItem_KeyId, @TaxGroup,
				@TaxType, @TaxCode, @ClaimItemNotes,
				----SLIT
				@UM, @ItemJCCo, @ItemJob, @PhaseGroup, @Phase, @JCCType, @GLCo, @GLAcct,
				@SupplierVendorGroup, @Supplier


	IF @@fetch_status <> 0 GOTO cSLClaimItem_end

	---- set error start 
	SELECT @ErrorStart = 'Subcontract: ' + dbo.vfToString(@Subcontract) + ' Claim No: ' + dbo.vfToString(@ClaimNo) + ' SL Item: ' + dbo.vfToString(@SLItem) + ' - '


	---- validate tax code and get rates
	IF ISNULL(@TaxCode,'') <> ''			
		BEGIN
		EXEC @rcode = dbo.bspHQTaxRateGetAll @TaxGroup, @TaxCode, @InvoiceDate, NULL, @TaxRate OUTPUT,
					NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @Msg OUTPUT 
		END

		   
	---- insert SL or JC GLAcct based on GLCostOverride
	---- get JC GL Account default
	EXEC @rcode = dbo.bspJCCAGlacctDflt @ItemJCCo, @ItemJob, @PhaseGroup, @Phase,
					@JCCType, 'N', @JCGLAcct OUTPUT, @Msg OUTPUT
	IF @rcode = 1
		BEGIN
		SELECT @Msg = @ErrorStart + dbo.vfToString(@Msg)
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
		GOTO vspexit
		END

	---- get cost JC Company override flag
	select @GLCostOverride = GLCostOveride
	FROM dbo.bJCCO
	WHERE JCCo=@ItemJCCo
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @Msg = @ErrorStart + ' JC Company: ' + dbo.vfToString(@ItemJCCo) + ' invalid JC Company.'
		SET @rcode = 1
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
		GOTO vspexit
		END
		
		   					
	IF @ApproveUnits <> 0 OR @ApproveAmount <> 0 OR @ApproveRetention <> 0
		BEGIN

		IF ISNULL(@TaxCode,'') <> ''
			BEGIN
			IF @HQCoDefaultCountry <> 'US'
				BEGIN
				---- calculate tax basis for international
				IF ISNULL(@APCoTaxbasisNetRetgYN, 'N') = 'N'
					BEGIN
					SET @TaxBasis = @ApproveAmount
					END
				ELSE
					BEGIN
					SELECT @TaxBasis = @ApproveAmount - @ApproveRetention
					END
				END
			ELSE
				---- calculate tax basis for US
				BEGIN
				SET @TaxBasis = @ApproveAmount 
				END					
			END	
											
		---- insert AP Transaction Batch line (APLB)
		IF @ProcessName = 'SLClaimUpdateAPTrans'
			BEGIN

			---- get next APLB line
			SELECT @APLine = ISNULL(MAX(APLine), 0) + 1
			FROM dbo.bAPLB
			WHERE Co = @SLCo
				AND Mth = @Mth
				AND BatchId = @BatchId
				AND BatchSeq = @Seq

			---- insert AP Line Batch record
			INSERT dbo.bAPLB (Co, Mth, BatchId, BatchSeq, APLine, BatchTransType, LineType,
					SL, SLItem, JCCo, Job, PhaseGroup, Phase, JCCType, GLCo, GLAcct,
					[Description], UM, Units, UnitCost, ECM, VendorGroup, Supplier,
					PayCategory, PayType, GrossAmt, MiscYN, MiscAmt, Retainage, Discount,
					TaxAmt, TaxBasis, TaxGroup, TaxType, TaxCode, Notes,
					SLDetailKeyID, SLKeyID)
					
			VALUES (@SLCo, @Mth, @BatchId, @Seq, @APLine, 'A', 7,
					@Subcontract, @SLItem, @ItemJCCo, @ItemJob, @PhaseGroup, @Phase, @JCCType, @GLCo,
					CASE @GLCostOverride WHEN 'Y' THEN @GLAcct
						ELSE CASE WHEN @JCGLAcct IS NULL THEN @GLAcct
						ELSE @JCGLAcct END
						END,
					@InvLineDesc, @UM, @ApproveUnits, @CurUnitCost,
					CASE @UM WHEN 'LS' THEN NULL ELSE 'E' END,
					@SupplierVendorGroup, @Supplier, @PayCategory, @PayType, @ApproveAmount, 'Y', 0,
					@ApproveRetention, 0, @TaxAmount,
					CASE ISNULL(@TaxCode,'')  WHEN '' THEN 0 ELSE @TaxBasis END,
					@TaxGroup, @TaxType, @TaxCode, @ClaimItemNotes,
					@ClaimItem_KeyId, @Claim_KeyId)
					
			---- get key id
			SET @APLB_KeyId = SCOPE_IDENTITY()	

			---- update user memos from SLClaimHeader to APUI
			EXEC @rcode = dbo.bspBatchUserMemoUpdate @SLCo, @Mth , @BatchId , @Seq, 'SLClaimItem' , @Msg OUTPUT
			if @rcode <> 0 
				BEGIN
				SELECT @Msg = @ErrorStart + dbo.vfToString(@Msg)
				IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
				GOTO vspexit
				END	
			END	


		---- insert AP Unapprove Invoice line (APUL)
		IF @ProcessName = 'SLClaimUpdateAPUnapprove'
			BEGIN
				
			---- get next APUL line
			SELECT @APLine = ISNULL(MAX(Line), 0) + 1
			FROM dbo.bAPUL
			WHERE APCo = @SLCo
				AND UIMth = @UIMonth
				AND UISeq = @UISeq

			---- insert AP Line Batch record
			INSERT dbo.bAPUL (APCo, Line, UIMth, UISeq, LineType, SL, SLItem, JCCo, Job, PhaseGroup,
						Phase, JCCType, GLCo, GLAcct, [Description], UM, Units, UnitCost, ECM,
						VendorGroup, Supplier, PayCategory, PayType, GrossAmt, MiscAmt, MiscYN,
						TaxBasis, TaxAmt, Retainage, Discount, TaxGroup, TaxType, TaxCode,
						InvOriginator, ReviewerGroup, Notes, SLDetailKeyID, SLKeyID)
					
			VALUES (@SLCo, @APLine, @UIMonth, @UISeq, 7, @Subcontract, @SLItem, @ItemJCCo, @ItemJob, @PhaseGroup,
					@Phase, @JCCType, @GLCo,
					CASE @GLCostOverride WHEN 'Y' THEN @GLAcct
						ELSE CASE WHEN @JCGLAcct IS NULL THEN @GLAcct
						ELSE @JCGLAcct END
						END,
					@InvLineDesc, @UM, @ApproveUnits, @CurUnitCost,
					CASE @UM WHEN 'LS' THEN NULL ELSE 'E' END,
					@SupplierVendorGroup, @Supplier, @PayCategory, @PayType, @ApproveAmount, 0, 'Y',
					CASE ISNULL(@TaxCode,'')  WHEN '' THEN 0 ELSE @TaxBasis END,
					@TaxAmount, @ApproveRetention, 0, @TaxGroup, @TaxType, @TaxCode,
					SUSER_SNAME(), @ReviewerGroup, @ClaimItemNotes, @ClaimItem_KeyId, @Claim_KeyId)
					
			---- get key id
			SET @APUL_KeyId = SCOPE_IDENTITY()	

			---- update user memos from SLClaimItem to APUL
			EXEC @rcode = dbo.bspBatchUserMemoUpdate @SLCo, NULL , NULL , NULL, 'SLClaimItemAPUnapprove' , @Msg OUTPUT
			if @rcode <> 0 
				BEGIN
				SELECT @Msg = @ErrorStart + dbo.vfToString(@Msg)
				IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
				GOTO vspexit
				END	
			END
			
		END

	---- next claim item
	GOTO cSLClaimItem_loop


	---- no more claim items to process
	cSLClaimItem_end:
		IF @OpenCursor = 1
			BEGIN
			CLOSE cSLClaimItem
			DEALLOCATE cSLClaimItem
			SET @OpenCursor = 0
			END

	---- update invoice date in claim header if none existed
	update dbo.vSLClaimHeader Set InvoiceDate = @InvoiceDate
	where SLCo = @SLCo
		AND SL = @Subcontract
		AND ClaimNo = @ClaimNo
		AND InvoiceDate IS NULL

	---- update to AP has completed. commit transaction
	COMMIT TRANSACTION
    
	---- when updating to AP Unapprove Invoices
	---- add threshold reviewers to the UI Seq
	IF @ProcessName = 'SLClaimUpdateAPUnapprove'
		BEGIN
		EXEC dbo.vspAPUnappThresholdReviewers @SLCo, @UIMonth, @UISeq
		END

END TRY
BEGIN CATCH
    -- Test XACT_STATE:
        -- If 1, the transaction is committable.
        -- If -1, the transaction is uncommittable and should 
        --     be rolled back.
        -- XACT_STATE = 0 means that there is no transaction and
        --     a commit or rollback operation would generate an error.
	IF XACT_STATE() <> 0
		BEGIN
		ROLLBACK TRANSACTION
		SET @Msg = CAST(ERROR_MESSAGE() AS VARCHAR(200)) 
		SET @rcode = 1
		END
END CATCH








	
vspexit:
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspSLClaimUpdateAP] TO [public]
GO
