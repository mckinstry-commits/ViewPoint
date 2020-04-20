SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE procedure [dbo].[vspSLClaimsRetTotalAmtGet]
/*************************************
* Created By:	GF 12/17/2012 TK-19583 SL Claims Retention Distribuiton
* Modified By:	GF 12/18/2012 TK-20315 SL Company Option to enforce catch up/down
*
*
* Called from SL Claims form. Calculates the retention amount to be
* distributed for the claim. There are various conditions that will
* affect the amount to distribute.
* 
* 1. The subcontract pct is calculated differently depending on the country.
*	 If country is 'AU' then this percentage is the average of the SLIT.WCRetPct for
*	 all claim items with a approved amount and WCRetPct is not zero.
*	 For all other countries we will just use the SLIT.WCRetpct to calculate the retention
* 2. We will calculate the basic retention amount to distribute using the subcontract pct for 'AU' or
*	 sum using the SLIT WCRetPct * approved amount for each claim item.
* 3. If the country is not 'AU' or the max retention is not active, then the retention from 2 is used.
* 4. If the country is 'AU' and max retention is active, then catch up/down will be included in
*	 the amount to distribute. Basically the catch up/down is the amount needed to get the retention
*	 remaining to zero if possible.
* 5. Last part is to make sure that the amount to distribute does not exceed the approve amount for
*	 the claim. 
*
* SL Company flag to enforce catch up/down. When this flag is 'N', then amount to distribution
* will work as described above when the country is not 'US'. When this flag is 'Y', then amount to distribute
* will work as described above when the country is 'AU'. This flag will override the default country,
* so when 'N' then no catch up/down. When 'Y' then catch up/down is done. Max retention limits still apply.
*
*
* Pass:
* @SLCo			SL Company
* @Subcontract	Subcontract
* @ClaimNo		Claim No
*
* OUTPUT:
* @AmtToDistribute	Claim Amount to distributie
*
* Success returns:
*	0
*
* Error returns:
*	1 and error message
**************************************/
(@SLCo bCompany, @Subcontract VARCHAR(30), @ClaimNo INT
,@AmtToDistribute bDollar = 0 OUTPUT, @Msg VARCHAR(255) OUTPUT)

AS
SET NOCOUNT ON

DECLARE @rcode INT, @SLClaimKeyID BIGINT, @APInvNotClaimAmt bDollar,
		@ClaimPrevApproveAmt bDollar, @ClaimApproveAmt bDollar,
		@MaxRetgOpt CHAR(1), @WCRetPct NUMERIC(12,8)
		----
		,@SLRetBudget bDollar, @SLRetTaken bDollar, @SLRetRemain bDollar
		,@RetentionToTake bDollar, @RetentionAmtForThisClaim bDollar
		----
		,@DefaultCountry VARCHAR(2), @TaxBasisNetRet VARCHAR(1)
		----TK-20315
		,@EnforceSLCatchup CHAR(1), @OrigContractAmt bDollar, @CurrContractAmt bDollar
  

SET @rcode = 0
SET @WCRetPct = 0
SET @SLRetBudget = 0
SET @SLRetTaken = 0
SET @SLRetRemain = 0
SET @RetentionToTake = 0
SET @RetentionAmtForThisClaim = 0
SET @AmtToDistribute = 0
SET @CurrContractAmt = 0
SET @OrigContractAmt = 0

---- if missing a key value exit procedure without doing anything for now
IF @SLCo IS NULL OR @Subcontract IS NULL OR @ClaimNo IS NULL GOTO vspexit

---- get claim heaader info use the claim totals view
SELECT @ClaimPrevApproveAmt = ISNULL(CT.PreviousApproved,0)
		,@ClaimApproveAmt = ISNULL(CT.ApproveAmount,0)
		,@SLClaimKeyID = SLClaimKeyID
FROM dbo.SLClaimHeaderTotal CT
WHERE CT.SLCo = @SLCo
	AND CT.SL = @Subcontract
	AND CT.ClaimNo = @ClaimNo
IF @@ROWCOUNT = 0 GOTO vspexit

---- if there are no claim items, then no distribution needs to occur
IF NOT EXISTS(SELECT 1 FROM dbo.vSLClaimItem WITH (NOLOCK) WHERE SLCo=@SLCo
							AND SL=@Subcontract
							AND ClaimNo=@ClaimNo) GOTO vspexit

---- if the claim has been sent to AP then no distribution needs to occur
---- should never happen. check each AP table using claim key id.
---- AP unapproved invoice header
IF EXISTS(SELECT 1 FROM dbo.bAPUI APUI WITH (NOLOCK) WHERE APUI.SLKeyID = @SLClaimKeyID) GOTO vspexit
---- AP Transaction Batch Header
IF EXISTS(SELECT 1 FROM dbo.bAPHB APHB WITH (NOLOCK) WHERE APHB.SLKeyID = @SLClaimKeyID) GOTO vspexit
---- AP Transaction Line
IF EXISTS(SELECT 1 FROM dbo.bAPTL APTL WITH (NOLOCK) WHERE APTL.SLKeyID = @SLClaimKeyID) GOTO vspexit

---- get default country, tax basis flag, and enforce catch up flag
select  @TaxBasisNetRet = a.TaxBasisNetRetgYN
		,@DefaultCountry = h.DefaultCountry
		----TK-20315
		,@EnforceSLCatchup = s.EnforceSLCatchup
from dbo.bAPCO a
INNER JOIN dbo.bHQCO h ON h.HQCo=a.APCo
INNER JOIN dbo.bSLCO s ON s.SLCo=a.APCo
where APCo = @SLCo
IF @@ROWCOUNT = 0
	BEGIN
	SET @TaxBasisNetRet = 'N'
	SET @DefaultCountry = 'US'
	SET @EnforceSLCatchup = 'N'
	END


---- get subcontract info
SELECT @MaxRetgOpt = MaxRetgOpt
FROM dbo.bSLHD SLHD WITH (NOLOCK)
WHERE SLHD.SLCo = @SLCo
	AND SLHD.SL = @Subcontract
IF @@ROWCOUNT = 0 GOTO vspexit

---- get subcontract totals from SL Items (SLIT)
SELECT @OrigContractAmt = ISNULL(SUM(OrigCost), 0)
	  ,@CurrContractAmt = ISNULL(SUM(CurCost), 0)
FROM dbo.bSLIT WITH (NOLOCK)
WHERE SLCo = @SLCo
	AND SL = @Subcontract


---- get APTL invoice total for the subcontract that has not been
---- entered via the claim process.
SELECT @APInvNotClaimAmt = SUM(ISNULL(APTL.GrossAmt, 0))
FROM dbo.bAPTL APTL WITH (NOLOCK)
WHERE APTL.APCo = @SLCo
	AND APTL.SL = @Subcontract
	AND (APTL.SLKeyID IS NULL
		OR NOT EXISTS(SELECT 1 FROM dbo.vSLClaimHeader CH WITH (NOLOCK)
							WHERE CH.KeyID = APTL.SLKeyID))

IF @APInvNotClaimAmt IS NULL SET @APInvNotClaimAmt = 0

---- get subcontract retention balances (what displays on the claim form)
SELECT @SLRetBudget = RetentionBudget
		,@SLRetTaken = RetentionTaken - ThisClaimRet
		,@SLRetRemain = RetentionRemain + ThisClaimRet
FROM dbo.vfSLClaimRetTotals (@SLCo, @Subcontract, @ClaimNo)


---- how retention is calculated is dependent on the enforce catchup flag in SLCo
---- when enforce catch-up is 'N' the retention to take will be the claim item approve amount * SLIT WCRetgPct
----TK-20315
IF ISNULL(@EnforceSLCatchup,'N') = 'N'
	BEGIN
	SELECT @RetentionToTake = Calc_CurRet
	FROM dbo.vSLClaimHeader CH WITH (NOLOCK)
	CROSS APPLY  
	    (
	    SELECT SUM(ISNULL(SLIT.WCRetPct, 0)  * ISNULL(CI.ApproveAmount, 0)) Calc_CurRet
		FROM dbo.vSLClaimItem CI  WITH (NOLOCK)
		INNER JOIN dbo.bSLIT SLIT WITH (NOLOCK) ON SLIT.SLCo=CI.SLCo AND SLIT.SL=CI.SL AND SLIT.SLItem=CI.SLItem
		WHERE CI.SLCo = CH.SLCo 
			 AND CI.SL = CH.SL 
			 AND CI.ClaimNo = CH.ClaimNo
			 AND ISNULL(CI.ApproveAmount, 0) <> 0
			 AND ISNULL(SLIT.WCRetPct, 0) <> 0
		 ) t

	WHERE CH.SLCo = @SLCo
		AND CH.SL = @Subcontract
		AND CH.ClaimNo = @ClaimNo

	END
ELSE
	BEGIN
	---- get contract retention pct (average of WCRetgPct for claim items not zero) will use the
	---- WCRetgPct from SLIT. if we have no items than something went wrong with the check above
	SELECT @WCRetPct = AVG(SLIT.WCRetPct)
	FROM dbo.bSLIT SLIT WITH (NOLOCK)
	INNER JOIN dbo.vSLClaimItem CI WITH (NOLOCK) ON CI.SLCo=SLIT.SLCo AND CI.SL=SLIT.SL AND CI.SLItem=SLIT.SLItem
	WHERE SLIT.SLCo = @SLCo
		AND SLIT.SL = @Subcontract
		AND CI.ClaimNo = @ClaimNo
		AND ISNULL(SLIT.WCRetPct, 0) <> 0
		AND ISNULL(CI.ApproveAmount, 0) <> 0

	IF @WCRetPct IS NULL SET @WCRetPct = 0

	---- for test purposes (numbers) just do like 'AU'
	SELECT @RetentionToTake = (@WCRetPct * (@APInvNotClaimAmt + @ClaimPrevApproveAmt + @ClaimApproveAmt)) - @SLRetTaken

	END


	                           
---- Set the starting Distribution amount for countdown.  Even though distribution is based upon the 
---- calculate subcontract PCT value we still do not want to allow distributing more than the retention
---- to distribute. This will counter the effect of a rounded UP or DOWN PCT value input.
---- when max retention option is not used there will be no catch up, so the left is retention this claim
IF @MaxRetgOpt = 'N'
	BEGIN
	SET @AmtToDistribute = @RetentionToTake
	END
ELSE
	BEGIN
	SET @AmtToDistribute = @RetentionToTake
	IF ABS(@AmtToDistribute) > ABS(@SLRetRemain)
		begin
		SET @AmtToDistribute = @SLRetRemain
		END
    END
    
	--BEGIN
	------TK-20315
	--IF ISNULL(@EnforceSLCatchup,'N') = 'N' OR @OrigContractAmt = @CurrContractAmt
	--	BEGIN
	--	SET @AmtToDistribute = @RetentionToTake
	--	END
	--ELSE
	--	BEGIN
	--	 SELECT @AmtToDistribute = CASE WHEN @SLRetRemain < 0 AND @RetentionToTake < 0 AND ABS(@SLRetRemain) > ABS(@RetentionToTake)
	--										THEN @SLRetRemain
	--									WHEN @SLRetRemain > 0 AND @RetentionToTake > 0 AND ABS(@SLRetRemain) > ABS(@RetentionToTake)
	--										THEN @SLRetRemain
	--									WHEN @SLRetRemain < 0 AND @RetentionToTake > 0 AND @RetentionToTake - ABS(@SLRetRemain) > 0
	--										THEN @RetentionToTake - ABS(@SLRetRemain)
	--									WHEN @SLRetRemain > 0 AND @RetentionToTake < 0
	--										THEN 0
	--									ELSE @RetentionToTake
	--									END      
	--	END
	--END
	      

---- amount to distribute cannot exceed approved amount  
IF ABS(@AmtToDistribute) > ABS(@ClaimApproveAmt)
	BEGIN
	SET @AmtToDistribute = @ClaimApproveAmt  
	END	

---- fill message with values for testing
SELECT @Msg = dbo.vfToString(@WCRetPct) + ' WCRetPct, '
			+ dbo.vfToString(@RetentionAmtForThisClaim) + ' RetThisClaim, '
			+ dbo.vfToString(@AmtToDistribute) + ' AmtToDist, '
			+ CHAR(13) + CHAR(10)




vspexit:
	return @rcode
























GO
GRANT EXECUTE ON  [dbo].[vspSLClaimsRetTotalAmtGet] TO [public]
GO
