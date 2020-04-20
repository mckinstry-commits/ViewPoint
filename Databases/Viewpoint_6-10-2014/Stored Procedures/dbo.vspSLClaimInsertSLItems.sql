SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[vspSLClaimInsertSLItems]          
/***********************************************************
* CREATED BY:	GF 09/17/2012 TK-16947
* MODIFIED By:
*
*			
* USAGE:
* Called by the SL Claims form when a new claim is added to initialize
* SL Items with zero values for claimed and approved from SLIT.
*
*
* INPUT PARAMETERS
* @SLCo				SL Company
* @Subcontract		Subcontract
* @ClaimNo			Subcontract Claim Number
* @ProcessType		'I' initializing SL Items for a new claim
*					'U' adding new SL Items to an existing claim
*
*
*
* OUTPUT PARAMETERS
* @Msg      	error message if error occurs
*
* RETURN VALUE
*   	0        	success
*   	1         	Failure
*****************************************************/
(@SLCo bCompany, @Subcontract VARCHAR(30), @ClaimNo INT,
 @ProcessType CHAR(1) = 'I', @Msg varchar(255) output)
AS
SET NOCOUNT ON
	
DECLARE @rcode INT, @ClaimDate bDate

SET @rcode = 0

---- validate subcontract
IF NOT EXISTS(SELECT 1 FROM dbo.bSLHD WHERE SLCo=@SLCo AND SL=@Subcontract)			
	BEGIN
	SELECT @Msg = 'Not a valid subcontract.', @rcode = 1
	GOTO vspexit
	END

---- validate subcontract claim
SELECT @ClaimDate = ClaimDate
FROM dbo.vSLClaimHeader
WHERE SLCo=@SLCo
	AND SL=@Subcontract
	AND ClaimNo=@ClaimNo
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @Msg = 'Not a valid subcontract claim.', @rcode = 1
	GOTO vspexit
	END

--- if no claim date set to system date
IF @ClaimDate IS NULL SET @ClaimDate = dbo.vfDateOnly()

---- check if we have any SL Items to initialize
IF NOT EXISTS(SELECT 1 FROM dbo.bSLIT WHERE SLCo=@SLCo AND SL=@Subcontract)
	BEGIN
	GOTO vspexit
	END

---- if initializing claim do not insert if claim items already exists 
IF @ProcessType = 'I' AND EXISTS(SELECT 1 FROM dbo.vSLClaimItem
				WHERE SLCo=@SLCo AND SL=@Subcontract AND ClaimNo=@ClaimNo)
	BEGIN
	GOTO vspexit
	END



BEGIN TRY
	---- start a transaction, commit after fully processed
    BEGIN TRANSACTION;

	---- initializing SL Items for a new claim
	IF @ProcessType = 'I'
		BEGIN
		
		---- insert SL Items into SLClaimItem Table
		INSERT INTO dbo.vSLClaimItem
			(SLCo, SL, ClaimNo, SLItem, Description, UM, CurUnitCost, CurUnits, CurCost,
				ClaimToDateUnits, ClaimToDateAmt, ClaimUnits, ClaimAmount, 
				ApproveUnits, ApproveAmount, ApproveRetPct, ApproveRetention,
				TaxGroup, TaxCode, TaxType, TaxAmount, ApproveToDateAmt, ApproveToDateUnits)
		SELECT @SLCo, @Subcontract, @ClaimNo, a.SLItem, NULL, a.UM, a.CurUnitCost, a.CurUnits, a.CurCost
				, ISNULL(p.PrevClaimUnits,0), ISNULL(p.PrevClaimAmt, 0), 0, 0
				, 0, 0, a.WCRetPct, 0, a.TaxGroup, a.TaxCode, a.TaxType, 0,ISNULL(p.PrevApproveAmt,0),ISNULL(p.PrevApproveUnits,0)
		FROM dbo.bSLIT a
			OUTER APPLY dbo.vfSLClaimItemPriorTotals(@SLCo, @Subcontract, @ClaimNo, a.SLItem, @ClaimDate) p
		WHERE a.SLCo = @SLCo
			AND a.SL = @Subcontract

		END

	IF @ProcessType = 'U'
		BEGIN
        ---- insert SL Items into SLClaimItem Table
		INSERT INTO dbo.vSLClaimItem
			(SLCo, SL, ClaimNo, SLItem, Description, UM, CurUnitCost, CurUnits, CurCost,
				ClaimToDateUnits, ClaimToDateAmt, ClaimUnits, ClaimAmount,
				ApproveUnits, ApproveAmount, ApproveRetPct, ApproveRetention,
				TaxGroup, TaxCode, TaxType, TaxAmount)
		SELECT @SLCo, @Subcontract, @ClaimNo, a.SLItem, NULL, a.UM, a.CurUnitCost, a.CurUnits, a.CurCost
				, ISNULL(p.PrevClaimUnits,0), ISNULL(p.PrevClaimAmt, 0), 0, 0
				, 0, 0, a.WCRetPct, 0, a.TaxGroup, a.TaxCode, a.TaxType, 0
		FROM dbo.bSLIT a
			OUTER APPLY dbo.vfSLClaimItemPriorTotals(@SLCo, @Subcontract, @ClaimNo, a.SLItem, @ClaimDate) p
		WHERE a.SLCo = @SLCo
			AND a.SL = @Subcontract
			AND NOT EXISTS(SELECT 1 FROM dbo.vSLClaimItem v WHERE v.SLCo = @SLCo AND v.SL = @Subcontract
									AND v.ClaimNo = @ClaimNo AND v.SLItem = a.SLItem)

		END
        

	---- initialize / update has completed. commit transaction
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
		SET @Msg = CAST(ERROR_MESSAGE() AS VARCHAR(200)) 
		SET @rcode = 1
		END
END CATCH




     
vspexit:   
	RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspSLClaimInsertSLItems] TO [public]
GO
