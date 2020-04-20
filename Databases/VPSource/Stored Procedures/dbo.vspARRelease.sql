SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARRelease    Script Date: 06/08/05 9:34:14 AM ******/
CREATE proc [dbo].[vspARRelease]
/********************************************************
* CREATED BY: 	TJL 06/08/05 - Issue #27715, written for 6x
* MODIFIED BY:	TJL 06/18/08 - Issue #128371, ARRelease International Sales Tax
*
*
*
* USAGE:
* Initiated by ARRelease form during automatic Release Retg calculations
*
* INPUT PARAMETERS:
*
* OUTPUT PARAMETERS:
*	Error message
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
********************************************************/	

@ARCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @BatchSeq int, @TransDate bDate, @CustGroup bGroup, @Customer bCustomer,
@JCCo bCompany, @Contract bContract, @RelRetgBillThruDate bDate, @InputReleasePct bPct, @InputReleasedAmt bDollar,
@errmsg varchar(375) output

as
set nocount on
  
declare @Mth bMonth, @ARTrans bTrans, @opencursorOpenRetg tinyint, @OpenRetg bDollar, @OpenRetgTax bDollar,
	@ReleasePct bPct, @ReleasedAmt bDollar, @RelRetgTaxAmt bDollar, @DistAmt bDollar,
	@rcode int

   
select @rcode = 0, @opencursorOpenRetg = 0, @DistAmt = 0, @OpenRetg = 0, @ReleasedAmt = 0, 
	@ReleasePct = 0, @OpenRetgTax = 0, @RelRetgTaxAmt = 0

if @ARCo is null
	begin
	select @errmsg='Must supply an AR Company.', @rcode=1
	goto vspexit
	end
if @BatchMth is null
	begin
	select @errmsg='Must supply a batch month.', @rcode=1
	goto vspexit
	end
if @BatchId is null
	begin
	select @errmsg='Must supply a batchid.', @rcode=1
	goto vspexit
	end
if @BatchSeq is null
	begin
	select @errmsg='Must supply a batchseq.', @rcode=1
	goto vspexit
	end
if @CustGroup is null or @Customer is null
	begin
	select @errmsg='Missing Customer information.', @rcode=1
	goto vspexit
	end
if @InputReleasePct = 0 and @InputReleasedAmt = 0
	begin
	select @errmsg='Must supply either a Pct input value or Amount input value.', @rcode = 1
	goto vspexit
	end

/*************** Begin processing Automatic Release Retg for this Customer, JCCo, Contract ************/

/* Clear JCCo if Contract is missing. */
If @Contract is null and @JCCo is not null
	begin
	select @JCCo = null
	end

/* Get list of Transactions relative to Customer, JCCo, Contract, ReleaseDate filters.  This
   is the equivalent to Filter inputs on ARRelease Form.  */
declare bcOpenRetg cursor local fast_forward for
select h.Mth, h.ARTrans, isnull(sum(l.Retainage),0), isnull(sum(l.RetgTax),0)
from bARTH h with (nolock)
join bARTL l with (nolock) on l.ARCo = h.ARCo and l.ApplyMth = h.Mth and l.ApplyTrans = h.ARTrans
where h.ARCo = @ARCo and h.CustGroup = @CustGroup and h.Customer = @Customer 
   	and (h.JCCo = @JCCo or @JCCo is null) 
   	and (h.Contract = @Contract or @Contract is null)   
	and h.ARTransType <> 'R' and h.Source like 'AR%' 
	and ((@RelRetgBillThruDate is null) or (@RelRetgBillThruDate is not null and h.TransDate <= @RelRetgBillThruDate))
group by h.Mth, h.ARTrans
having (select isnull(sum(l.Retainage),0)) <> 0
order by h.Mth, h.ARTrans	

/* Open cursor */
open bcOpenRetg
/* Set open cursor flag to true */
select @opencursorOpenRetg = 1

GetNextInvoice:
fetch next from bcOpenRetg into @Mth, @ARTrans, @OpenRetg, @OpenRetgTax
while @@fetch_status = 0
	begin	/* Begin Invoice Loop */
	if @InputReleasedAmt <> 0
		begin
		/* Releasing based upon a Total Amount input by user.  Since we don't know how users wants this 
		   distributed for each invoice, we will distribute as much as possible and move on.  */
		if abs(@DistAmt + @OpenRetg) <= abs(@InputReleasedAmt)
			begin
			select @ReleasedAmt = @OpenRetg							--Release Total open on Invoice
			select @RelRetgTaxAmt = @OpenRetgTax					--Release Total open RetgTax on Invoice
			end
		else
			begin
			select @ReleasedAmt = @InputReleasedAmt - @DistAmt		--Release what is left
			select @RelRetgTaxAmt = Case when @OpenRetg = 0 then 0 else (@ReleasedAmt/@OpenRetg) * @OpenRetgTax end
			end

		select @ReleasePct = case when @OpenRetg = 0 then 0 else @ReleasedAmt/@OpenRetg end
		if @ReleasedAmt = 0 goto GetNextInvoice

  		/* Keep a running total of how much has been posted.  */
		select @DistAmt = @DistAmt + @ReleasedAmt
		end
	else
		begin
		/* Releasing based upon a Release Pct input by user.  We can assume this Pct value is intended
		   to be distributed as a Pct to each Transaction. */
		select @ReleasedAmt = @OpenRetg * @InputReleasePct
		select @ReleasePct = @InputReleasePct					
		select @RelRetgTaxAmt = @OpenRetgTax * @InputReleasePct

		if @ReleasedAmt = 0 goto GetNextInvoice
		end

	/* For this Invoice/Transaction, we have an Amount to be Released.  Pass this in.  It will be distributed
	   amongst each line in exactly the same way as if user were inputting from the ARRelease grid */
	exec @rcode = vspARReleaseLine @ARCo, @BatchMth, @BatchId, @BatchSeq, @Mth, @ARTrans, @ReleasePct, @ReleasedAmt, 
		@RelRetgTaxAmt, 'N', @errmsg output
	if @rcode <> 0 goto vspexit

	if @InputReleasedAmt <> 0
		begin
		/* Releasing based upon a Total Amount input by user. */
		if (@DistAmt < @InputReleasedAmt)
			begin
			/* There remains a portion of the Input Amount to be distributed/Released on the next 
			   Invoice/Transaction in line. */
			goto GetNextInvoice
			end
		else
			begin
			/* The entire input Amount value has been Released.  Exit now and avoid the unnecessary cycling
			   through of remaining transactions in the Transaction cursor. */
			goto vspexit
			end
		end
	else
		begin
		/* Releasing based upon a Release Pct input by user. */
		goto GetNextInvoice
		end

	end		/* End Invoice Loop */

vspexit:

if @opencursorOpenRetg = 1
	begin
	close bcOpenRetg
	deallocate bcOpenRetg
	select @opencursorOpenRetg = 0
	end

if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[vspARRelease]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARRelease] TO [public]
GO
