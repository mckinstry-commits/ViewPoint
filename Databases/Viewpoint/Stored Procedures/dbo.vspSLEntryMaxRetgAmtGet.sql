SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspSLEntryMaxRetgAmtGet]
/***********************************************************
* Creadted By: DC	02/02/10 - Issue #129892, Max Retainage Enhancement
* Modified By: GF 06/29/2010 - issue #135813 expanded subcontract to 30 characters
*	
*			
* Called from SL Entry form and returns the calculated
* maximum retainage amount based upon:
*
*	SLHD Percent of Contract setup value.
*	SLHD exclude Variations from Max Retainage by % value.
*	SLIT Non-Zero Retainage Percent items
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
(@slco bCompany = 0, @subcontract VARCHAR(30) = null, @maxretgpct bPct = 0, @inclchgordersinmax bYN = 'Y',
 @maxretgamt bDollar output, @msg varchar(255) output)
as
set nocount on

declare @rcode int,
		@slitcurcost bDollar,
		@slitorigcost bDollar,
		@sliborigcost bDollar
				
select @rcode = 0, @maxretgamt = 0

if @slco is null
  	begin
  	select @msg = 'Missing SL Company!', @rcode = 1
  	goto vspexit
  	end

if @subcontract is null
  	begin
  	select @msg = 'Missing Subcontract!', @rcode = 1
  	goto vspexit
  	end

/* May or may not exclude change order values but regardless, will always exclude any
   contract items with a WCRetPct set to 0.0%. */
SELECT @slitcurcost = sum(isnull(CurCost,0)), @slitorigcost = sum(isnull(OrigCost,0))
FROM bSLIT with (nolock)
WHERE SLCo = @slco and SL = @subcontract and InUseMth is null and InUseBatchId is null and ItemType = 1 and WCRetPct <> 0

SELECT @sliborigcost = case when @inclchgordersinmax = 'Y' then sum(isnull(t.CurCost, 0)) - sum(isnull(b.OldOrigCost, 0)) + sum(isnull(b.OrigCost,0)) 
		else sum(isnull(b.OrigCost, 0)) end
FROM bSLHB h with (nolock)
	JOIN bSLIB b with (nolock) on b.Co = h.Co and h.Mth = b.Mth and h.BatchId = b.BatchId and h.BatchSeq = b.BatchSeq
	LEFT JOIN dbo.bSLIT t with (nolock) on h.Co = t.SLCo and h.SL = t.SL and b.SLItem = t.SLItem
		and t.InUseMth is not null and t.InUseBatchId is not null and t.ItemType = 1 and t.WCRetPct <> 0	
WHERE b.ItemType = 1 and b.BatchTransType in ('A','C') and b.WCRetPct <> 0 and h.Co = @slco and h.SL = @subcontract
GROUP BY h.Co, h.Mth, h.BatchId, h.BatchSeq, h.InclACOinMaxYN
	
SELECT @maxretgamt = case when @inclchgordersinmax = 'Y' then @maxretgpct * (isnull(@slitcurcost,0) + isnull(@sliborigcost,0))
	else @maxretgpct * (isnull(@slitorigcost,0) + isnull(@sliborigcost,0)) end


vspexit:

return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspSLEntryMaxRetgAmtGet] TO [public]
GO
