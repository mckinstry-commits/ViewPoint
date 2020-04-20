SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[vspSLClaimNoTotalsGet]
/***********************************************************
* Created By:	GF 09/06/2012 TK-17944
* Modified By:	GF 03/29/2013 TFS-45348 balance forward claim changes
*				AW 6/20/13 TFS-53578 Return PayTerms from SLHD if available
*				AW 6/24/13 TFS-53580 Return Contract totals
*				AW 8/27/13 TFS-59945 Only include On Hold Transactions for @PymtRetNotPaidAmt
*				AW 8/27/13 TFS-59994 Do not include GST when calcuting total retention on hold
*
*
* USAGE:
* gets subcontract totals, subcontract claim totals, and subcontract previous claim totals
* this procedure is not used for validation.
*  Previous Values Assume SLClaimHeader.ClaimNo are Sequential order
*
*
* INPUT PARAMETERS
* SLCo   		SL Company
* SL    		Subcontract
* ClaimNo		CLaim Number
*
*
* OUTPUT PARAMETERS
* @OrigContractAmt	Subcontract - Original Cost
* @CurrContractAmt	Subcontract - Current Cost
* @VariationAmt		Current Cost minus Original Cost
*
* @PriorAmtClaimed
* @ThisClaim
* @TimsClaimRet
* @SLTotalClaimed	
* @SLTotalClaimedRet
* @PriorAmtApproved
* @ApprovedAmount
* @ApprovedAmountRet
* @SLTotalApproved
* @SLTotalApprovedRet
*
* @PriorRetClaimed
* @PriorRetApproved
* @PriorTaxAmount
* @SLTotalTaxAmount
*
* @RetentionBudget
* @RetentionTaken
* @RetentionRemain
*
* ----invoice details
* @InvoiceNo
* @InvoiceTotal
* @InvoiceTax
* @InvoiceDate
* @InvoiceDueDate
* @InvoiceType
* @ApprovalStatus
*
* ----payment details
* @PymtCheckNo 
* @PymtCheckDate
* @PymtPaidAmt 
* @PymtRetCheckNo 
* @PymtRetCheckDate 
* @PymtRetPaidAmt
* @SLPayTerms bPayTerms = NULL OUTPUT,
* @PriorContractAmt bDollar = 0 OUTPUT,
* @ThisContractAmt bDollar = 0 OUTPUT,
* @PymtRetNotPaidAmt
*
*
* @msg				error message if error occurs or claim description
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@SLCo bCompany = NULL, @SL VARCHAR(30) = NULL, @ClaimNo INT = NULL,
 ----SL totals
 @OrigContractAmt bDollar = 0 OUTPUT,
 @CurrContractAmt bDollar = 0 OUTPUT,
 @VariationAmt bDollar = 0 OUTPUT,
 ----claim totals
 @PriorAmtClaimed bDollar = 0 OUTPUT,
 @ThisClaim bDollar = 0 OUTPUT,
 @ThisClaimRet bDollar = 0 OUTPUT,
 @SLTotalClaimed bDollar = 0 OUTPUT,
 @SLTotalClaimedRet bDollar = 0 OUTPUT,
 @PriorAmtApproved bDollar = 0 OUTPUT,
 @ApprovedAmount bDollar = 0 OUTPUT,
 @ApprovedAmountRet bDollar = 0 OUTPUT,
 @SLTotalApproved bDollar = 0 OUTPUT,
 @SLTotalApprovedRet bDollar = 0 OUTPUT,
 @PriorRetClaimed bDollar = 0 OUTPUT,
 @PriorRetApproved bDollar = 0 OUTPUT,
 @PriorTaxAmount bDollar = 0 OUTPUT,
 @SLTotalTaxAmount bDollar = 0 OUTPUT,
 ----SL retention
 @RetentionBudget bDollar = 0 OUTPUT,
 @RetentionTaken bDollar = 0 OUTPUT,
 @RetentionRemain bDollar = 0 OUTPUT,
 ----invoice details
 @InvoiceNo VARCHAR(20) = NULL OUTPUT,
 @InvoiceTotal bDollar = 0 OUTPUT,
 @InvoiceTax bDollar = 0 OUTPUT,
 @InvoiceDate VARCHAR(20) = NULL OUTPUT,
 @InvoiceDueDate VARCHAR(20) = NULL OUTPUT,
 @InvoiceType VARCHAR(50) = NULL OUTPUT,
 @ApprovalStatus VARCHAR(50) = NULL OUTPUT,
 ----payment details
 @PymtCheckNo VARCHAR(10) = NULL OUTPUT,
 @PymtCheckDate	VARCHAR(20) = NULL OUTPUT,
 @PymtPaidAmt bDollar = 0 OUTPUT,
 @PymtRetCheckNo VARCHAR(10) = NULL OUTPUT,
 @PymtRetCheckDate VARCHAR(20) = NULL OUTPUT,
 @PymtRetPaidAmt bDollar = 0 OUTPUT, 
 @SLPayTerms bPayTerms = NULL OUTPUT,
 --contract details
 @PriorContractAmt bDollar = 0 OUTPUT,
 @ThisContractAmt bDollar = 0 OUTPUT,
 @PymtRetNotPaidAmt bDollar = 0 OUTPUT, 
 @Msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @UIStatus INTEGER, @AppCount INTEGER,
		@RejCount INTEGER, @TtlCount INTEGER, @CMRefCount INTEGER,
		@ClaimKeyId BIGINT,
		@APTDKeyId BIGINT, @InvDate SMALLDATETIME, @DueDate SMALLDATETIME


SET @rcode = 0
SET @OrigContractAmt = 0
SET @CurrContractAmt = 0
SET @VariationAmt = 0
SET @SLTotalClaimed	= 0
SET @SLTotalClaimedRet  = 0
SET @SLTotalApproved = 0
SET @SLTotalApprovedRet = 0
SET @SLTotalTaxAmount = 0
SET @PriorAmtClaimed = 0
SET @PriorRetClaimed = 0
SET @PriorAmtApproved = 0
SET @PriorRetApproved = 0
SET @PriorTaxAmount = 0
SET @ThisClaim = 0
SET @ThisClaimRet = 0
SET @ApprovedAmount = 0
SET @ApprovedAmountRet = 0
SET	@RetentionBudget = 0
SET @RetentionTaken = 0
SET @RetentionRemain = 0

SET @InvoiceNo = NULL
SET @InvoiceTotal = 0
SET @InvoiceTax = 0
set @InvoiceDate = NULL
SET @InvoiceDueDate = NULL
SET @InvoiceType = NULL
SET @ApprovalStatus = NULL
SET @UIStatus = 10
SET @AppCount = 0
SET @RejCount = 0
SET @TtlCount = 0
SET @PymtCheckNo = NULL
SET @PymtCheckDate = NULL
SET @PymtPaidAmt = 0
SET @PymtRetCheckNo = NULL
SET @PymtRetCheckDate = NULL
SET @PymtRetPaidAmt = 0 
SET @PymtRetNotPaidAmt = 0 
SET @CMRefCount = 0
SET @ClaimKeyId = NULL
SET @APTDKeyId = NULL
SET @InvDate = NULL
SET @DueDate = NULL
SET @SLPayTerms = NULL
SET @PriorContractAmt = 0
SET @ThisContractAmt = 0
SET @PymtRetNotPaidAmt = 0
 
---- check key values
IF @SLCo IS NULL OR @SL IS NULL OR @ClaimNo IS NULL GOTO vspexit

---- claim header info
SELECT @Msg = [Description]
		,@ClaimKeyId = KeyID
FROM dbo.vSLClaimHeader
WHERE SLCo = @SLCo
	AND SL = @SL
	AND ClaimNo = @ClaimNo
IF @@ROWCOUNT = 0 SET @ClaimKeyId = 0

--get payterms 
SELECT @SLPayTerms = SLHD.PayTerms
FROM SLHD
WHERE SLCo = @SLCo
	AND SL = @SL


---- get subcontract totals from SL Items (SLIT)
SELECT @OrigContractAmt = ISNULL(SUM(OrigCost), 0)
	  ,@CurrContractAmt = ISNULL(SUM(CurCost), 0)
	  ,@RetentionBudget = RetentionBudget
	  ,@RetentionTaken = RetentionTaken
	  ,@RetentionRemain = RetentionRemain
FROM dbo.bSLIT
OUTER APPLY dbo.vfSLClaimRetTotals (@SLCo, @SL, @ClaimNo)
WHERE SLCo = @SLCo
	AND SL = @SL
GROUP BY RetentionBudget, RetentionTaken, RetentionRemain

---- variation amount is current minus original
SET @VariationAmt = @CurrContractAmt - @OrigContractAmt

-- Get Current Contract Amounts
SELECT @ThisContractAmt = CurCost
FROM dbo.vSLClaimHeader
WHERE SLCo = @SLCo
	AND SL = @SL
	AND ClaimNo = @ClaimNo

-- Get Prev Contract Amounts
SELECT @PriorContractAmt = CurCost
FROM dbo.vSLClaimHeader
WHERE SLCo = @SLCo
	AND SL = @SL
	AND ClaimNo = (SELECT max(ClaimNo)
					FROM dbo.vSLClaimHeader
					WHERE SLCo = @SLCo
						AND SL = @SL
						AND ClaimNo < @ClaimNo)

---- claim amounts
SELECT @ThisClaim		  = ISNULL(SUM(i.ClaimAmount), 0)
	  ,@ApprovedAmount	  = ISNULL(SUM(i.ApproveAmount), 0)
	  ,@ApprovedAmountRet = ISNULL(SUM(i.ApproveRetention), 0)
FROM dbo.vSLClaimItem i
INNER JOIN dbo.vSLClaimHeader h ON h.SLCo = i.SLCo AND h.SL = i.SL AND h.ClaimNo=i.ClaimNo
WHERE i.SLCo = @SLCo
	AND i.SL = @SL
	AND i.ClaimNo = @ClaimNo	

---- subcontract claim totals
SELECT @SLTotalClaimed	   = ISNULL(SUM(i.ClaimAmount), 0)
	  ,@SLTotalApproved	   = ISNULL(SUM(i.ApproveAmount), 0)
	  ,@SLTotalApprovedRet = ISNULL(SUM(i.ApproveRetention), 0)
	  ,@SLTotalTaxAmount   = ISNULL(SUM(i.TaxAmount), 0)
FROM dbo.vSLClaimItem i
INNER JOIN dbo.vSLClaimHeader h ON h.SLCo = i.SLCo AND h.SL = i.SL AND h.ClaimNo=i.ClaimNo
WHERE i.SLCo = @SLCo
	AND i.SL = @SL
	AND h.ClaimStatus <> 20 ----denied

---- subcontract claim prior totals
SELECT @PriorAmtClaimed  = ISNULL(SUM(i.ClaimAmount), 0)
	  ,@PriorAmtApproved = ISNULL(SUM(i.ApproveAmount), 0)
	  ,@PriorRetApproved = ISNULL(SUM(i.ApproveRetention), 0)
	  ,@PriorTaxAmount   = ISNULL(SUM(i.TaxAmount), 0)
FROM dbo.vSLClaimItem i
INNER JOIN dbo.vSLClaimHeader h ON h.SLCo = i.SLCo AND h.SL = i.SL AND h.ClaimNo=i.ClaimNo
WHERE i.SLCo = @SLCo
	AND i.SL = @SL
	---- HOW DO WE APPLY CLAIM DATE FOR NEW CLAIMS???
	AND i.ClaimNo < @ClaimNo
	AND h.ClaimStatus <> 20 ----denied


---- TFS-45348 claim 0 (balance forward) invoice details
IF @ClaimNo = 0 AND  (SELECT COUNT(*) FROM dbo.bAPTH WHERE SLKeyID = @ClaimKeyId) > 1
	BEGIN
		SET @InvoiceType = 'AP Posted Transaction'
		SET @InvoiceNo = 'Multiple'
		SET @InvDate = NULL
		SET @DueDate = NULL
        
		SELECT @InvoiceTotal = SUM(ISNULL(APTL.GrossAmt,0))
			   ,@InvoiceTax = SUM(ISNULL(APTL.TaxAmt,0))
		FROM dbo.bAPTL APTL
		WHERE APTL.SLKeyID = @ClaimKeyId
	END      
ELSE
	BEGIN
	---- Invoice Type
	SELECT @InvoiceType = 
			CASE WHEN APHB.BatchSeq IS NOT NULL	THEN 'AP Entry Batch'
					WHEN APUI.UISeq IS NOT NULL	THEN 'AP Unapproved Invoices'
					WHEN APTL.APTrans IS NOT NULL THEN 'AP Posted Transaction'
					ELSE NULL
					END
	FROM dbo.vSLClaimHeader h
	LEFT JOIN dbo.bAPHB APHB ON h.KeyID = APHB.SLKeyID
	LEFT JOIN dbo.bAPUI APUI ON h.KeyID = APUI.SLKeyID
	LEFT JOIN dbo.bAPTL APTL ON h.KeyID = APTL.SLKeyID
	WHERE h.KeyID = @ClaimKeyId


	---- AP Entry Batch Info
	IF @InvoiceType = 'AP Entry Batch'
		BEGIN
		SELECT  @InvoiceNo = APHB.APRef,
				@InvDate = APHB.InvDate,
				@DueDate = APHB.DueDate,
				@InvoiceTotal = ISNULL(APHB.InvTotal,0),
				@InvoiceTax = SUM(ISNULL(APLB.TaxAmt,0))
		FROM dbo.bAPHB APHB
		INNER JOIN dbo.bAPLB APLB ON APLB.SLKeyID=APHB.SLKeyID
		WHERE APHB.SLKeyID = @ClaimKeyId
		GROUP BY APHB.APRef, APHB.InvDate, APHB.DueDate, APHB.InvTotal
		END

	---- AP Posted Transaction Info
	IF @InvoiceType = 'AP Posted Transaction'
		BEGIN
		SELECT TOP 1 @InvoiceNo	= APTH.APRef,
				@InvDate	= APTH.InvDate,
				@DueDate	= APTH.DueDate,
				@InvoiceTotal	= ISNULL(APTH.InvTotal, 0),
				@InvoiceTax		= SUM(ISNULL(APTL.TaxAmt,0))
		FROM dbo.bAPTH APTH
		INNER JOIN dbo.bAPTL APTL ON APTH.APCo=APTL.APCo AND APTH.Mth=APTL.Mth AND APTH.APTrans=APTL.APTrans
		WHERE APTL.SLKeyID = @ClaimKeyId
		GROUP BY APTH.APRef, APTH.InvDate, APTH.DueDate, APTH.InvTotal
		END

	---- AP Unapproved Invoice Info
	IF @InvoiceType = 'AP Unapproved Invoices'
		BEGIN

		---- get unapproved invoice info
		SELECT TOP 1 @InvoiceNo	= APUI.APRef
					,@InvDate = APUI.InvDate
					,@DueDate = APUI.DueDate
					,@InvoiceTotal = ISNULL(APUI.InvTotal, 0)
					,@InvoiceTax = SUM(ISNULL(APUL.TaxAmt,0))
		FROM dbo.bAPUI APUI
		INNER JOIN dbo.bAPUL APUL ON APUL.APCo=APUI.APCo AND APUL.UIMth=APUI.UIMth AND APUL.UISeq=APUI.UISeq
		WHERE APUI.SLKeyID = @ClaimKeyId
		GROUP BY APUI.APRef, APUI.InvDate, APUI.DueDate, APUI.InvTotal      

		---- set default status
		SET @ApprovalStatus = 'Unapproved'
		---- get AP Unapproved Invoice Status
		SELECT @TtlCount = ISNULL(COUNT(DISTINCT TTL.KeyID),0)
				,@AppCount = ISNULL(COUNT(DISTINCT APP.KeyID),0)
				,@RejCount = ISNULL(COUNT(DISTINCT REJ.KeyID),0)
				,@ApprovalStatus = CASE WHEN @RejCount = 1 THEN 'Rejected'
										WHEN @AppCount = @TtlCount THEN 'Approved'
										WHEN @AppCount > 0 AND @RejCount = 0 AND @AppCount < @TtlCount THEN 'Partially Approved'
										ELSE 'Unapproved'
										END
		FROM dbo.bAPUI APUI
		LEFT  JOIN dbo.bAPUR TTL ON APUI.APCo=TTL.APCo AND APUI.UIMth=TTL.UIMth AND APUI.UISeq=TTL.UISeq
		LEFT  JOIN dbo.bAPUR REJ ON APUI.APCo=REJ.APCo AND APUI.UIMth=REJ.UIMth AND APUI.UISeq=REJ.UISeq AND REJ.Rejected = 'Y'
		LEFT  JOIN dbo.bAPUR APP ON APUI.APCo=APP.APCo AND APUI.UIMth=APP.UIMth AND APUI.UISeq=APP.UISeq AND APP.ApprvdYN = 'Y'
		WHERE APUI.SLKeyID = @ClaimKeyId  
		END
	END
  
  
  
        
---- format invoice dates for international
IF @InvDate IS NOT NULL
	BEGIN
	SET @InvoiceDate = dbo.vfDateOnlyAsStringUsingStyle(@InvDate, @SLCo, DEFAULT)
	END

IF @DueDate IS NOT NULL
	BEGIN
	SET @InvoiceDueDate = dbo.vfDateOnlyAsStringUsingStyle(@DueDate, @SLCo, DEFAULT)
	END


SET @PymtCheckNo = NULL
SET @PymtCheckDate = NULL
SET @PymtPaidAmt = 0
---- payment details - invoice
SELECT @APTDKeyId = MAX(CMRefCount)
	FROM (
		 SELECT (CASE WHEN d.PayCategory IS NULL
	 				THEN (CASE WHEN d.PayType <> c.RetPayType AND ISNULL(COUNT(DISTINCT d.CMRef),0) = 1
							   THEN d.KeyID WHEN ISNULL(COUNT(DISTINCT d.CMRef),0) > 1 THEN -999 ELSE 0 END)
					ELSE (CASE WHEN d.PayType <> p.RetPayType AND ISNULL(COUNT(DISTINCT d.CMRef),0) = 1
							   THEN d.KeyID WHEN ISNULL(COUNT(DISTINCT d.CMRef),0) > 1 THEN -999 ELSE 0 END)
				END) CMRefCount

			FROM dbo.bAPTD d WITH (NOLOCK)
			INNER JOIN dbo.bAPTL l ON l.APCo=d.APCo AND l.Mth=d.Mth AND l.APTrans=d.APTrans AND l.APLine=d.APLine
			INNER JOIN dbo.bAPCO c WITH (NOLOCK) ON c.APCo = d.APCo
			LEFT  JOIN dbo.bAPPC p WITH (NOLOCK) ON p.APCo=d.APCo AND p.PayCategory=d.PayCategory
			WHERE l.SLKeyID = @ClaimKeyId
				AND d.[Status] = 3 ----paid
			GROUP BY d.PayCategory, d.PayType, c.RetPayType, p.RetPayType, d.KeyID
			) xx

---- if the key id = -999 then we have more than one distinct CM Reference
IF ISNULL(@APTDKeyId,0) = -999
	BEGIN
	SET @PymtCheckNo = 'Multiple'
	SET @PymtCheckDate = 'Multiple'
	END
ELSE
	BEGIN
	SELECT  @PymtCheckNo = APTD.CMRef,
			@PymtCheckDate = dbo.vfDateOnlyAsStringUsingStyle(APTD.PaidDate, @SLCo, DEFAULT)
	FROM dbo.bAPTD APTD WITH (NOLOCK)
	WHERE APTD.KeyID = @APTDKeyId
	END

---- get invoice paid amount
SELECT @PymtPaidAmt	= SUM(ISNULL(APTD.Amount,0))
FROM dbo.bAPTD APTD
INNER JOIN dbo.bAPTL APTL ON APTL.APCo=APTD.APCo AND APTL.Mth=APTD.Mth AND APTL.APTrans=APTD.APTrans AND APTL.APLine = APTD.APLine
INNER JOIN dbo.bAPCO APCO WITH (NOLOCK) ON APCO.APCo = APTD.APCo
LEFT  JOIN dbo.bAPPC APPC WITH (NOLOCK) ON APPC.APCo=APTD.APCo AND APPC.PayCategory=APTD.PayCategory
WHERE APTL.SLKeyID = @ClaimKeyId
	AND APTD.Status = 3 ----paid
	AND (
		(APTD.PayCategory IS NULL AND APTD.PayType <> APCO.RetPayType)
		OR (APTD.PayCategory IS NOT NULL AND APTD.PayType <> APPC.RetPayType)
		)



SET @PymtRetCheckNo = NULL
SET @PymtRetCheckDate = NULL
SET @PymtRetPaidAmt = 0
SET @PymtRetNotPaidAmt = 0
---- payment details - retention
SELECT @APTDKeyId = MAX(CMRefCount)
	FROM (
		 SELECT (CASE WHEN d.PayCategory IS NULL
	 				THEN (CASE WHEN d.PayType = c.RetPayType AND ISNULL(COUNT(DISTINCT d.CMRef),0) = 1
							   THEN d.KeyID WHEN ISNULL(COUNT(DISTINCT d.CMRef),0) > 1 THEN -999 ELSE 0 END)
					ELSE (CASE WHEN d.PayType = p.RetPayType AND ISNULL(COUNT(DISTINCT d.CMRef),0) = 1
							   THEN d.KeyID WHEN ISNULL(COUNT(DISTINCT d.CMRef),0) > 1 THEN -999 ELSE 0 END)
				END) CMRefCount

			FROM dbo.bAPTD d WITH (NOLOCK)
			INNER JOIN dbo.bAPTL l ON l.APCo=d.APCo AND l.Mth=d.Mth AND l.APTrans=d.APTrans AND l.APLine=d.APLine
			INNER JOIN dbo.bAPCO c WITH (NOLOCK) ON c.APCo = d.APCo
			LEFT  JOIN dbo.bAPPC p WITH (NOLOCK) ON p.APCo=d.APCo AND p.PayCategory=d.PayCategory
			WHERE l.SLKeyID = @ClaimKeyId
				AND d.[Status] = 3 ----paid
			GROUP BY d.PayCategory, d.PayType, c.RetPayType, p.RetPayType, d.KeyID
			) xx

---- if the key id = -999 then we have more than one distinct CM Reference
IF ISNULL(@APTDKeyId,0) = -999
	BEGIN
	SET @PymtRetCheckNo = 'Multiple'
	SET @PymtRetCheckDate = 'Multiple'
	END
ELSE
	BEGIN
	SELECT  @PymtRetCheckNo = APTD.CMRef,
			@PymtRetCheckDate = dbo.vfDateOnlyAsStringUsingStyle(APTD.PaidDate, @SLCo, DEFAULT)
	FROM dbo.bAPTD APTD WITH (NOLOCK)
	WHERE APTD.KeyID = @APTDKeyId
	END

---- get invoice paid amount
SELECT @PymtRetPaidAmt	= SUM(ISNULL(APTD.Amount,0))
FROM dbo.bAPTD APTD
INNER JOIN dbo.bAPTL APTL ON APTL.APCo=APTD.APCo AND APTL.Mth=APTD.Mth AND APTL.APTrans=APTD.APTrans AND APTL.APLine = APTD.APLine
INNER JOIN dbo.bAPCO APCO WITH (NOLOCK) ON APCO.APCo = APTD.APCo
LEFT  JOIN dbo.bAPPC APPC WITH (NOLOCK) ON APPC.APCo=APTD.APCo AND APPC.PayCategory=APTD.PayCategory
WHERE APTL.SLKeyID = @ClaimKeyId
	AND APTD.Status = 3 ----paid
	AND (
		(APTD.PayCategory IS NULL AND APTD.PayType = APCO.RetPayType)
		OR (APTD.PayCategory IS NOT NULL AND APTD.PayType = APPC.RetPayType)
		)

--get outstanding retention
SELECT @PymtRetNotPaidAmt	= SUM(ISNULL(APTD.Amount,0)) - 
	SUM(CASE WHEN APCO.TaxBasisNetRetgYN = 'Y' THEN APTD.GSTtaxAmt ELSE 0 END)
FROM dbo.bAPTD APTD
INNER JOIN dbo.bAPTL APTL ON APTL.APCo=APTD.APCo AND APTL.Mth=APTD.Mth AND APTL.APTrans=APTD.APTrans AND APTL.APLine = APTD.APLine
INNER JOIN dbo.bAPCO APCO WITH (NOLOCK) ON APCO.APCo = APTD.APCo
LEFT  JOIN dbo.bAPPC APPC WITH (NOLOCK) ON APPC.APCo=APTD.APCo AND APPC.PayCategory=APTD.PayCategory
WHERE APTL.APCo = @SLCo 
	AND APTL.SL = @SL
	--AND APTL.SLKeyID is not null -- ignore whether its claim related or not
	AND APTD.Status = 2 ----OnHold
	AND (
		(APTD.PayCategory IS NULL AND APTD.PayType = APCO.RetPayType)
		OR (APTD.PayCategory IS NOT NULL AND APTD.PayType = APPC.RetPayType)
		)
IF @PymtRetNotPaidAmt IS NULL SET @PymtRetNotPaidAmt = 0

vspexit:
	if @rcode <> 0 select @Msg = isnull(@Msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLClaimNoTotalsGet] TO [public]
GO
