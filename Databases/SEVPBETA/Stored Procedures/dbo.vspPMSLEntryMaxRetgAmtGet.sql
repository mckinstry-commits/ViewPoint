SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPMSLEntryMaxRetgAmtGet]
/***********************************************************
* Creadted By: GF 09/23/10 - Issue #129892, Max Retainage Enhancement
* Modified By:	
*	
*			
* Called from PM SL Header form and returns the calculated
* maximum retainage amount based upon:
*
*	SLHD Percent of Contract setup value.
*	SLHD exclude Variations from Max Retainage by % value.
*	SLIT Non-Zero Retainage Percent items
*
* Business logic for the maximum retainage amount within PM.
* 1. Get sum of PMSL detail amounts for original where interface date is null
*	 and item type equals 1 and item WCRetgPct <> 0 and Item Send Flag equals 'Y'
* 2. Get sum of PMSL detail amounts for original where interface date is null
*	 and item type equals 2 and item WCRetgPct <> 0 and Item Send Flag equals 'Y'
* 3. Get sum of SLIT current costs and original costs where item type = '1' and
*	 item WCRetgPct <> 0.
*
* Maximum Retainage amount equals:
*  1. When SL Include change orders = 'Y' then SL maximum retainage % times
*	  SLIT current cost + SLIT original cost + PMSL Original cost + PMSL Change order cost.
*  2. When SL Include change orders = 'Y' then SL maximum retainage % times
*	  SLIT original cost + PMSL Original cost
*
*
* INPUT PARAMETERS
* SLCo			SL Co to validate against
* Subcontract	Subcontract to validate
* MaxRetgPct	Maximum Retainage Percent of Contract value		
* Incl Flag		InclACOfromMaxRetgYN flag
*
* OUTPUT PARAMETERS
* @maxretgamt
* @msg			error message if error occurs otherwise Description of Contract
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@SLCO bCompany = null, @SL VARCHAR(30) = null, @maxretgpct bPct = 0, @inclchgordersinmax bYN = 'Y',
 @maxretgamt bDollar output, @msg varchar(255) output)
as
set nocount on
			 
declare @rcode int, @PMOriginalCost bDollar, @PMChangeCost bDollar,
		@PMMaxRetgByPct AS NUMERIC(20,2), @SLMaxRetgByPct AS NUMERIC(20,2),
		@SLITOrigCost bDollar, @SLITCurrCost bDollar
				
SET @rcode = 0
SET @PMOriginalCost = 0
SET @PMChangeCost = 0
SET @SLITCurrCost = 0
SET @SLITOrigCost = 0
SET @PMMaxRetgByPct = 0
SET @SLMaxRetgByPct = 0

---- key values must not be null
if @SLCO is NULL OR @SL IS NULL GOTO vspexit


---- sum of all subcontract items from PMSL - not interfaced and not change orders
SELECT @PMOriginalCost = ISNULL(SUM(i.Amount),0)
FROM dbo.bPMSL i
JOIN dbo.SLHD h ON h.SLCo=i.SLCo AND h.SL=i.SL
WHERE i.SLCo=@SLCO AND i.SL=@SL AND i.InterfaceDate IS NULL
AND i.SLItemType = 1 AND i.WCRetgPct <> 0 AND i.SendFlag = 'Y'

---- sum of all subcontract items from PMSL - not interfaced change order item types only
SELECT @PMChangeCost = ISNULL(SUM(i.Amount),0)
FROM dbo.bPMSL i
JOIN dbo.SLHD h ON h.SLCo=i.SLCo AND h.SL=i.SL
WHERE i.SLCo=@SLCO AND i.SL=@SL AND i.InterfaceDate IS NULL
AND i.SLItemType = 2 AND i.WCRetgPct <> 0 AND i.SendFlag = 'Y'

---- sum of all subcontract items from SLIT
---- May or may not exclude change order values but regardless, will always exclude any
---- contract items with a WCRetPct set to 0.0%.
SELECT @SLITCurrCost = ISNULL(sum(CurCost),0), @SLITOrigCost = ISNULL(sum(OrigCost),0)
FROM dbo.SLIT with (nolock)
WHERE SLCo = @SLCO and SL = @SL and ItemType = 1 and WCRetPct <> 0


---- calculate max retainage amount
SET @maxretgamt = 
		CASE WHEN @inclchgordersinmax = 'Y' THEN @maxretgpct * (isnull(@SLITCurrCost,0) + isnull(@SLITOrigCost,0) + ISNULL(@PMOriginalCost,0) + ISNULL(@PMChangeCost,0))
			 ELSE @maxretgpct * (isnull(@SLITOrigCost,0) + isnull(@PMOriginalCost,0))
			 END


vspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMSLEntryMaxRetgAmtGet] TO [public]
GO
