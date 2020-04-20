SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[vspSLClaimBalForwardCreate]
/***********************************************************
* CREATED BY:	GF 03/28/2013 TFS-45348 SL Claims Enhancement addition
* MODIFIED BY:	
* 
*
* USAGE:
* called from a script or run manually to create a balance forward claim
* for legacy subcontracts. The intent of this procedure to create a claim zero 0
* for the subcontract that will have all the AP that is not from the claim
* process. The claim item values will be loaded from AP. Doing this will allow
* new claims to be processed for subcontracts that were in progress prior to
* the claims enhancement release (6.6.0).
*
* Balance Forward Claim:
*
*
* INPUT PARAMETERS
* @SLCo				SL Company to validate
* @Subcontract		Subcontract to validate
*
*
* OUTPUT PARAMETERS
*
* @msg				error message IF error occurs during the creation of balance forward claim or item
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@SLCo bCompany = 0,
 @Subcontract varchar(30) = NULL,
 @Msg varchar(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT,  @ClaimDate bDate, @ClaimDesc bItemDesc, @SLItem bItem,
		@APRef bAPReference, @InvDesc bDesc, @InvDate bDate, @ExClaimDate bDate,
		@ClaimKeyId BIGINT



SET @rcode = 0
SET @ClaimDesc = 'Balance Forward Claim'


---------------------
-- VALIDATE VALUES --
---------------------
IF @SLCo IS NULL
	BEGIN
	SELECT @Msg = 'Missing SL Company!', @rcode = 1
	GOTO vspexit
	END

IF @Subcontract IS NULL
	BEGIN
	SELECT @Msg = 'Missing Subcontract!', @rcode = 1
	GOTO vspexit
	END

---- check if balance forward claim exists
IF EXISTS(SELECT 1 FROM dbo.vSLClaimHeader WHERE SLCo = @SLCo AND SL = @Subcontract AND ClaimNo = 0)
	BEGIN
 	SELECT @Msg = 'Balance forward claim exists for subcontract. SLCo: ' + dbo.vfToString(@SLCo) + ' SL: ' + dbo.vfToString(@Subcontract), @rcode = 1
	GOTO vspexit
	END  

---- validate subcontract
IF NOT EXISTS(SELECT 1 FROM dbo.bSLHD WHERE SLCo=@SLCo AND SL=@Subcontract)
	BEGIN
	SELECT @Msg = 'Subcontract does not exist in Subcontract Header. SLCo: ' + dbo.vfToString(@SLCo) + ' SL: ' + dbo.vfToString(@Subcontract), @rcode = 1
	GOTO vspexit
	END

---- validate subcontract status - must not be pending
IF EXISTS(SELECT 1 FROM dbo.bSLHD WHERE SLCo=@SLCo AND SL=@Subcontract AND Status = 3)
	BEGIN
	SELECT @Msg = 'Subcontract status is pending. Claims not allowed! SLCo: ' + dbo.vfToString(@SLCo) + ' SL: ' + dbo.vfToString(@Subcontract), @rcode = 1
	GOTO vspexit
	END

---- subcontract must not be in open SL Entry batch
IF EXISTS(SELECT 1 FROM dbo.bSLHB WHERE Co=@SLCo AND SL=@Subcontract)
	BEGIN
	SELECT @Msg = 'Subcontract exists in an open SL Entry Batch. Batch must be cleared or posted first! SLCo: ' + dbo.vfToString(@SLCo) + ' SL: ' + dbo.vfToString(@Subcontract), @rcode = 1
	GOTO vspexit
	END

---- subcontract must not be in open SL Entry batch
IF EXISTS(SELECT 1 FROM dbo.bSLCB WHERE Co=@SLCo AND SL=@Subcontract)
	BEGIN
	SELECT @Msg = 'Subcontract exists in an open SL Change Order Batch. Batch must be cleared or posted first! SLCo: ' + + dbo.vfToString(@SLCo) + ' SL: ' + dbo.vfToString(@Subcontract), @rcode = 1
	GOTO vspexit
	END

---- subcontract cannot be in an open AP Transaction Entry Batch
IF EXISTS(SELECT 1 FROM dbo.bAPLB WHERE Co = @SLCo AND SL = @Subcontract)
	BEGIN
  	SELECT @Msg = 'Subcontract exists in an open AP Transaction Entry batch. Batch must be cleared or posted first! SLCo: ' + dbo.vfToString(@SLCo) + ' SL: ' + dbo.vfToString(@Subcontract), @rcode = 1
	GOTO vspexit
	END  

---- Subcontract cannot be on an AP Unapproved Invoice
IF EXISTS(SELECT 1 FROM dbo.bAPUL WHERE APCo = @SLCo AND SL = @Subcontract AND SLKeyID IS NULL)
	BEGIN
  	SELECT @Msg = 'Subcontract exists on an AP Unapproved Invoice and needs to be deleted or processed first! SLCo: ' + dbo.vfToString(@SLCo) + ' SL: ' + dbo.vfToString(@Subcontract), @rcode = 1
	GOTO vspexit
	END 

---- check for APTL records for this subcontract not aasigned to a claim
---- we only want to create a claim for subcontracts in APTL not associated to a claim
IF NOT EXISTS(SELECT 1 FROM dbo.bAPTL WHERE APCo = @SLCo AND SL = @Subcontract AND SLKeyID IS NULL)
	BEGIN
	SELECT @Msg = 'Subcontract does not have any APTL entries not associated with a claim. Balance forward claim not required! SLCo: ' + dbo.vfToString(@SLCo) + ' SL: ' + dbo.vfToString(@Subcontract), @rcode = 1
	GOTO vspexit
	END
    
---- get the last AP Invoice Entry information for the subcontract. Will be used as claim header information
SELECT TOP 1 @SLItem	= APTL.SLItem
			 ,@InvDesc	= APTH.Description
			 ,@InvDate  = APTH.InvDate
			 ,@APRef	= APTH.APRef
FROM dbo.bAPTL APTL
INNER JOIN dbo.bAPTH APTH ON APTH.APCo = APTL.APCo AND APTH.Mth = APTL.Mth AND APTH.APTrans = APTL.APTrans
WHERE APTL.APCo = @SLCo
	AND APTL.SL = @Subcontract
ORDER BY APTL.Mth DESC, APTL.APTrans DESC
IF @@ROWCOUNT = 0
	BEGIN
  	SELECT @Msg = 'Error retrieving APTH/APTL information for balance forward claim! SLCo: ' + dbo.vfToString(@SLCo) + ' SL: ' + dbo.vfToString(@Subcontract), @rcode = 1
	GOTO vspexit
	END

---- get claim date for first Claim for subcontract - MAY NOT BE EXISTING
SELECT TOP 1 @ExClaimDate = ClaimDate
FROM dbo.vSLClaimHeader
WHERE SLCo = @SLCo
	AND SL = @Subcontract
ORDER BY ClaimNo ASC
IF @@ROWCOUNT = 0 SET @ExClaimDate = NULL


---- what date should we use for the balance forward claim?
---- the claim date is critical within the pervious value process
---- the claim no less than current claim AND Claim Date >= Current Claim Date is considered previous
SET @ClaimDate = NULL
IF @ExClaimDate IS NOT NULL SET @ClaimDate = @ExClaimDate
IF @ClaimDate IS NULL AND @InvDate IS NOT NULL SET @ClaimDate = @InvDate
IF @ClaimDate IS NULL SET @ClaimDate = dbo.vfDateOnly()




/*******************************************************/
/* CREATE THE BALANCE FORWARD CLAIM                    */
/* WILL BE DONE IN A TRANSACTION IN CASE ERROR OCCURS. */
/*******************************************************/


BEGIN TRY
	---- start a transaction, commit after fully processed
    BEGIN TRANSACTION;

		---- insert SL Claim header record - the approved retention will be set to zero
		---- and we will update after the SL Claim Items are added
		INSERT INTO dbo.vSLClaimHeader
				( SLCo, SL, ClaimNo, Description, ClaimDate, RecvdClaimDate, InvoiceDate, APRef,
				  CertifyDate, ClaimStatus, InvoiceDesc, CertifiedBy, ApproveRetention
				)
		SELECT @SLCo, @Subcontract, 0, @ClaimDesc, @ClaimDate, NULL, @InvDate, @APRef, NULL, 10, @InvDesc, NULL, 0

		---- get claim key id for AP updates
		SET @ClaimKeyId = SCOPE_IDENTITY()


		---- create claim items from APTL - one record per subcontract item
		INSERT INTO dbo.vSLClaimItem
		        (
				 SLCo, SL, ClaimNo, SLItem, ClaimToDateUnits, ClaimToDateAmt, ClaimUnits, ClaimAmount,
				 ApproveUnits, ApproveAmount, ApproveRetPct, ApproveRetention, TaxAmount, Description,
				 UM, CurUnitCost, CurUnits, CurCost, TaxGroup, TaxCode, TaxType
				)
		SELECT @SLCo, @Subcontract, 0, SLIT.SLItem, ISNULL(InvUnitTotal, 0), ISNULL(InvGrossTotal,0), ISNULL(InvUnitTotal, 0), ISNULL(InvGrossTotal,0)
				, ISNULL(InvUnitTotal, 0), ISNULL(InvGrossTotal,0)
				, SLIT.WCRetPct, ISNULL(InvRetTotal, 0), ISNULL(InvTaxTotal, 0), NULL
				, SLIT.UM, SLIT.CurUnitCost, 0, 0
				, SLIT.TaxGroup, SLIT.TaxCode, SLIT.TaxType
		FROM dbo.bSLIT SLIT

			CROSS APPLY  
				(
				SELECT  SUM(ISNULL(APTL.Retainage, 0)) InvRetTotal
					   ,SUM(ISNULL(APTL.TaxAmt, 0)) InvTaxTotal
					   ,SUM(ISNULL(APTL.GrossAmt, 0)) InvGrossTotal
					   ,SUM(ISNULL(APTL.Units, 0)) InvUnitTotal
				 FROM dbo.bAPTL APTL WITH (NOLOCK)
				 WHERE APTL.APCo = SLIT.SLCo 
				 AND APTL.SL = SLIT.SL 
				 AND APTL.SLItem = SLIT.SLItem
				 AND APTL.SLKeyID IS NULL
				 HAVING (
						 SUM(ISNULL(APTL.GrossAmt, 0)) <> 0
							OR SUM(ISNULL(APTL.TaxAmt, 0)) <> 0
							OR SUM(ISNULL(APTL.Retainage, 0)) <> 0
						)
				 ) APTL

		WHERE SLIT.SLCo = @SLCo
			AND SLIT.SL = @Subcontract


		---- update invoice date in claim header if none existed
		update dbo.vSLClaimHeader
			SET ApproveRetention = ISNULL(ItemRetentionTotal, 0)
		FROM dbo.vSLClaimHeader HEAD
			CROSS APPLY  
				(
				 SELECT  SUM(ISNULL(ITEM.ApproveRetention, 0)) ItemRetentionTotal
				 FROM dbo.vSLClaimItem ITEM
				 WHERE ITEM.SLCo = HEAD.SLCo 
				 AND ITEM.SL = HEAD.SL
				 AND ITEM.ClaimNo = HEAD.ClaimNo
				 ) ITEM    
		where SLCo = @SLCo
			AND SL = @Subcontract
			AND ClaimNo = 0


		---- update APTL with the claim key id for invoices associated with this subcontract
		---- update APTL
		UPDATE dbo.bAPTL
				SET SLKeyID = @ClaimKeyId
		WHERE APCo = @SLCo
			AND SL = @Subcontract
			AND SLKeyID IS NULL
		      
		---- update APTH with the claim key id for invoices associated with this subcontract
		---- update APTH
		UPDATE dbo.bAPTH
			SET SLKeyID = @ClaimKeyId
   		FROM dbo.bAPTH APTH
		WHERE APTH.APCo = @SLCo
			AND APTH.SLKeyID IS NULL
			AND EXISTS(SELECT 1 FROM dbo.bAPTL APTL WHERE APTL.APCo = APTH.APCo AND APTL.Mth = APTH.Mth
							AND APTL.APTrans = APTH.APTrans AND APTL.SLKeyID = @ClaimKeyId)
 
		    

	---- update to AP has completed. commit transaction
	COMMIT TRANSACTION
    


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
		SET @Msg = CAST(ERROR_MESSAGE() + ' SLCo: ' + dbo.vfToString(@SLCo) + ' SL: ' + dbo.vfToString(@Subcontract) AS VARCHAR(200)) 
		SET @rcode = 1
		END
END CATCH






vspexit:
	RETURN @rcode




GO
GRANT EXECUTE ON  [dbo].[vspSLClaimBalForwardCreate] TO [public]
GO
