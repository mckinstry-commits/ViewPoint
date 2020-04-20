SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARAutoWriteOffByLine    Script Date: 01/14/02 11:36:41 AM ******/
   
CREATE proc [dbo].[bspARAutoWriteOffByLine]

/********************************************************
* CREATED BY: 	TJL 1/14/02
* MODIFIED BY:  TJL 3/25/02 - Issue #16747, Insert value in FinanceChg column
*		TJL 05/24/02 - Issue #5212, Add TaxAmount to WriteOff by Invoice or Account
*		TJL 07/21/03 - Issue #21890, Performance Mods - Add (with (nolocks), Convert to True Cursor
*		TJL 09/12/03 - Issue #22435, Fix problem with ARLine numbering in bARBL
*		TJL 10/31/03 - Issue #22898, Allow for Partial Finance Charge WriteOffs, incorporate Unposted Batch Values
*		TJL 04/25/05 - Issue #28508, Add MatlGroup, Material, UM, ECM, MatlUnits = 0, ContractUnits = 0 to Insert statement
*		TJL 02/28/08 - Issue #125289:  Remove unposted batch values from consideration
*		TJL 06/02/08 - Issue #128286, ARInvoiceEntry International Sales Tax
*
*
* USAGE:
* 	Automatically create writeoff entries at the line level for Invoice 
*	transactions older than a given date.  This procedure will 
*	create writeoff entries against Line amounts for the entire invoice
*	or for FinanceChg amounts only.
*	This stored procedure is called from bspARAutoWriteOffs.
*	
*
* INPUT PARAMETERS:
* 	@ARCo,@BatchMth,@BatchId,@BatchSeq
* 	@ApplyMth, @ApplyTrans - The Apply transaction to be written off against
*	@AmtLeft - Either Total/Partial Finance Chg amount or Invoice amountdue whichever is smaller
* 	@ApplyAllYN - 'Y' By Invoice, By Account, or By FinChg if total FC can be written off
*	@ApplyAllYN - 'N' By FinChg during partial FC writeoff
*	@ApplyAllYN - 'P' By FinChg when Percent of FC is to be written off
* 	@rtGLCo, @rtGLFCWriteOffAcct - GLCo and proper writeoff account from the invoice RecType
*	@WrtOffOpt - Either 'AcctBal', 'InvBal', or 'FinChg'
*	@FCPct - Finance Charge percentage to be written off on each line
*	
*
* OUTPUT PARAMETERS:
*	Error message
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@ARCo bCompany = null, @BatchMth bMonth = null, @BatchId bBatchID = null,
    @BatchSeq int = null, @ApplyMth bMonth = null, @ApplyTrans bTrans = null,
    @AmtLeft bDollar = null, @ApplyAllYN bYN = null, @rtRecType int,
    @rtGLCo bCompany, @rtGLFCWriteOffAcct bGLAcct, @WrtOffOpt varchar(10),
    @FCPct bPct, @InvFlag char(1) = 'O', @msg varchar(255) output)
   
As
   
set nocount on
   
declare @rcode int, @lineamtdue bDollar, @lineretgdue bDollar,
	@lineFCamtdue bDollar, @linetaxdue bDollar, @lineretgtaxdue bDollar, @lineamount bDollar,
   	@ARLine smallint, @numrows int, 
   	@postamt bDollar, @postretg bDollar, @posttax bDollar, @postretgtax bDollar, @postfc bDollar,
   	@lastline smallint, @openarlinecursor int
   
   -- @nextARLine smallint, 
   
IF @ARCo is null
   	begin
   	select @rcode=1,@msg='AR Company is missing'
   	goto bspexit
   	end
IF @BatchMth is null
   	begin
   	select @rcode=1,@msg='AR Batch Month is missing'
   	goto bspexit
   	end
IF @BatchId is null
   	begin
   	select @rcode=1,@msg='AR Batch ID is missing'
   	goto bspexit
   	end
IF @BatchSeq is null
   	begin
   	select @rcode=1,@msg='AR Batch Seq is missing'
   	goto bspexit
   	end
IF @ApplyMth is null
   	begin
   	select @rcode=1,@msg='AR Transaction ApplyMth is missing'
   	goto bspexit
   	end
IF @ApplyTrans is null
   	begin
   	select @rcode=1,@msg='AR Transaction ApplyTrans is missing'
   	goto bspexit
   	end
IF @AmtLeft is null
   	begin
   	select @rcode=1,@msg='Amount to WriteOff has not been determined'
   	goto bspexit
   	end
IF @ApplyAllYN is null
   	begin
   	select @ApplyAllYN ='N'
   	end
   
select @rcode = 0, @openarlinecursor = 0
select @lineFCamtdue = 0, @lineamtdue = 0
   
/* Process each line for this Invoice Transaction */
declare bcarline cursor local fast_forward for
select ARLine
from bARTL with (nolock)
where ARCo= @ARCo and Mth = @ApplyMth and ARTrans = @ApplyTrans
   
/* Open cursor */
open bcarline
select @openarlinecursor = 1

fetch next from bcarline into @ARLine
   
/* Spin through lines */
while @@fetch_status = 0
   	Begin
   	select @postamt = 0, @posttax = 0, @postretg = 0, @postfc = 0, @postretgtax = 0
   
   	/* Get Line Amount Due, this includes Retainage and Finance Chg amounts. */
   	select @lineamount = IsNull(sum(bARTL.Amount),0),
   		@lineretgdue = IsNull(sum(bARTL.Retainage),0),
   		@lineFCamtdue = IsNull(sum(bARTL.FinanceChg),0),
   		@linetaxdue = IsNull(sum(bARTL.TaxAmount),0),
		@lineretgtaxdue = IsNull(sum(bARTL.RetgTax),0)
	from bARTL with (nolock)
	where bARTL.ARCo = @ARCo and bARTL.ApplyMth = @ApplyMth and bARTL.ApplyTrans = @ApplyTrans and bARTL.ApplyLine = @ARLine
   
--   	/* Add in any relative amounts from unposted batches */
--   	select @lineamount = @lineamount + IsNull(sum(case bARBL.TransType when 'D'
--      						then case when bARBH.ARTransType in ('I','A','F','R')
--        					then -IsNull(bARBL.oldAmount,0) else IsNull(bARBL.oldAmount,0)
--        					end
--   		else
--   						case when bARBH.ARTransType in ('I','A','F','R')
--        					then IsNull(bARBL.Amount,0) - IsNull(bARBL.oldAmount,0)
--        					else -IsNull(bARBL.Amount,0) + IsNull(bARBL.oldAmount,0)
--   						end
--   		end),0),
--   
--   		@lineretgdue = @lineretgdue + IsNull(sum(case bARBL.TransType when 'D'
--   						then case when bARBH.ARTransType in ('I','A','F','R')
--   						then -IsNull(bARBL.oldRetainage,0) else IsNull(bARBL.oldRetainage,0)
--   						end
--   		else
--    						case when bARBH.ARTransType in ('I','A','F','R')
--   						then IsNull(bARBL.Retainage,0) - IsNull(bARBL.oldRetainage,0)
--   						else -IsNull(bARBL.Retainage,0) + IsNull(bARBL.oldRetainage,0)
--   						end
--   		end),0),
--   
--   		@lineFCamtdue = @lineFCamtdue + IsNull(sum(case bARBL.TransType when 'D'
--   						then case when bARBH.ARTransType in ('I','A','F','R')
--   						then -IsNull(bARBL.oldFinanceChg,0) else IsNull(bARBL.oldFinanceChg,0)
--   						end
--   		else
--   						case when bARBH.ARTransType in ('I','A','F','R')
--   						then IsNull(bARBL.FinanceChg,0) - IsNull(bARBL.oldFinanceChg,0)
--   						else -IsNull(bARBL.FinanceChg,0) + IsNull(bARBL.oldFinanceChg,0)
--   						end
--   		end),0),
--   
--   		@linetaxdue = @linetaxdue + IsNull(sum(case bARBL.TransType when 'D' then
--             				case when bARBH.ARTransType in ('I','A','F','R')
--             				then -IsNull(bARBL.oldTaxAmount,0) else IsNull(bARBL.oldTaxAmount,0)
--             				end
--      		else
--   						case when bARBH.ARTransType in ('I','A','F','R') 
--             				then IsNull(bARBL.TaxAmount,0) - IsNull(bARBL.oldTaxAmount,0)
--             				else -IsNull(bARBL.TaxAmount,0) + IsNull(bARBL.oldTaxAmount,0)
--   						end
--   			end),0)
--
--   		@lineretgtaxdue = @lineretgtaxdue + IsNull(sum(case bARBL.TransType when 'D' then
--             				case when bARBH.ARTransType in ('I','A','F','R')
--             				then -IsNull(bARBL.oldRetgTax,0) else IsNull(bARBL.oldRetgTax,0)
--             				end
--      		else
--   						case when bARBH.ARTransType in ('I','A','F','R') 
--             				then IsNull(bARBL.RetgTax,0) - IsNull(bARBL.oldRetgTax,0)
--             				else -IsNull(bARBL.RetgTax,0) + IsNull(bARBL.oldRetgTax,0)
--   						end
--   			end),0)
--   
--   	from bARBL with (nolock)
--   	join bARBH with (nolock) on bARBH.Co=bARBL.Co and bARBH.Mth=bARBL.Mth and bARBH.BatchId = bARBL.BatchId and bARBH.BatchSeq = bARBL.BatchSeq
--   	where bARBL.Co = @ARCo and bARBL.ApplyMth = @ApplyMth and bARBL.ApplyTrans = @ApplyTrans and bARBL.ApplyLine = @ARLine
   
	select @lineamtdue = @lineamount - @lineretgdue
	   
	if @WrtOffOpt = 'FinChg'	/* (GET LINE POSTING AMOUNTS) */
		begin	/* Begin Finance Charge line processing */
		/* You have entered AR Programming twilight zone. 

   		Reason for use of ABS:  When comparing negative line values to determine
   		which value to use as a reference, we want -15 to be larger than -10.  Once this
   		comparison is made, we then want the program to treat these numbers
   		normally.  It is possible to get in real trouble here, so think it through.*/
		if @ApplyAllYN = 'Y'
			begin
			select @postamt = @lineFCamtdue
			end

		if @ApplyAllYN = 'N' 
			begin
			if ((@lineamtdue > 0 and @lineFCamtdue > 0 and @InvFlag = 'P') or
				(@lineamtdue < 0 and @lineFCamtdue < 0 and @InvFlag = 'N')) 
				begin
				/* Line amounts are either all positive or all negative */
				select @postamt = case
					when abs(@lineamtdue) >= abs(@lineFCamtdue) then
						case when abs(@lineFCamtdue) <= abs(@AmtLeft) then @lineFCamtdue
						when abs(@lineFCamtdue) > abs(@AmtLeft) then @AmtLeft
						else 0 end
					else
						case when abs(@lineamtdue) <= abs(@AmtLeft) then @lineamtdue
						when abs(@lineamtdue) > abs(@AmtLeft) then @AmtLeft
						else 0 end
					end
				end
			else
				begin 
				/* FinanceChg may be negative when the line is positive if user has
				   over credited the FinanceChg amount when improperly doing a Write-Off
				   manually.  In this case, post whatever negative FinanceChg amount
				   exists on this line regardless of AmtDue value or polarity.  In my
				   testing this has worked pretty well. */
				select @postamt = @lineFCamtdue
				end
			end

   		if @ApplyAllYN = 'P' 
   			begin
   			if ((@lineamtdue > 0 and @lineFCamtdue > 0) or
   				(@lineamtdue < 0 and @lineFCamtdue < 0)) 
   				begin
   				/* Line amounts are either all positive or all negative */
   				select @postamt = case
   					when abs(@lineamtdue) >= abs(@lineFCamtdue * @FCPct) then
   						(@lineFCamtdue * @FCPct) else @lineamtdue end
   				end
   			else
   				begin
   				/* FinanceChg may be negative when the line is positive if user has
   				   over credited the FinanceChg amount when improperly doing a Write-Off
   				   manually.  In this case, post whatever negative FinanceChg amount
   				   exists on this line regardless of AmtDue value or polarity.  In my
   				   testing this has worked pretty well. */
   				select @postamt = (@lineFCamtdue * @FCPct)
   				end
   			end
   		end		/* End Finance Charge line processing */
   
   	if @WrtOffOpt = 'InvBal' or @WrtOffOpt = 'AcctBal'	/* (GET LINE POSTING AMOUNTS) */
   		begin	/* Begin MinBal line processing */
   
   		/* These transactions have already met the filtering requirements
   		   input by the user.  Therefore, any line amount due, regardless of
   		   value or polarity, will be written off in its entirety. */
   		select @postamt = @lineamount, @postretg = @lineretgdue, @postfc = @lineFCamtdue, @posttax = @linetaxdue, 
			@postretgtax = @lineretgtaxdue
   		end		/* End MinBal line processing */
   
   	/* Insert into Batch table bARBL */
   	if isnull(@postamt,0) <> 0 or isnull(@postretg,0) <> 0 or isnull(@postfc,0) <> 0 or isnull(@posttax,0) <> 0
		or isnull(@postretgtax,0) <> 0
    	begin
    	insert into bARBL(Co, Mth, BatchId, BatchSeq, ARLine, TransType, ARTrans, RecType,
			LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode,
			Amount, TaxBasis, TaxAmount, RetgTax, RetgPct, Retainage, DiscOffered, DiscTaken,
			FinanceChg, ApplyMth, ApplyTrans, ApplyLine, JCCo, Contract, Item, ContractUnits, UM,
			INCo, Loc, MatlGroup, Material, ECM, MatlUnits, CustJob)
    	select bARTL.ARCo, @BatchMth, @BatchId, @BatchSeq, @ARLine, 'A', null, @rtRecType,
			case when bARTL.LineType = 'A' then 'O' else bARTL.LineType end, 
			bARTL.Description, @rtGLCo, @rtGLFCWriteOffAcct, bARTL.TaxGroup, bARTL.TaxCode,
			@postamt, 0, 
			case when @WrtOffOpt = 'FinChg' then 0 else @posttax end,
			case when @WrtOffOpt = 'FinChg' then 0 else @postretgtax end, 
			0, 
			case when @WrtOffOpt = 'FinChg' then 0 else @postretg end, 0, 0,
			case when @WrtOffOpt = 'FinChg' then @postamt else @postfc end,
			@ApplyMth, @ApplyTrans, bARTL.ApplyLine,  bARTL.JCCo, bARTL.Contract, bARTL.Item, 0, bARTL.UM,
			bARTL.INCo, bARTL.Loc, bARTL.MatlGroup, bARTL.Material, bARTL.ECM, 0, bARTL.CustJob
    	from bARTL with (nolock)
    	where bARTL.ARCo = @ARCo and bARTL.Mth = @ApplyMth and bARTL.ARTrans = @ApplyTrans and bARTL.ARLine = @ARLine
    	end
   
   	/* The following in this list deal with Total WriteOff amounts where a running total is
   	   not required. */
   	if (@WrtOffOpt = 'InvBal' and @ApplyAllYN = 'Y') or (@WrtOffOpt = 'AcctBal' and @ApplyAllYN = 'Y') 
   		or (@WrtOffOpt = 'FinChg' and @ApplyAllYN in ('Y','P')) goto GetNextLine
   
	/* @WrtOffOpt = 'FinChg' and @ApplyAllYN = 'N' Only.  Update the running totals */
   	select @AmtLeft = @AmtLeft - @postamt
	if @AmtLeft = 0 goto bspexit
   
	/* The last line is used to apply any leftover amounts - Won't happen! */ 
   	select @lastline = @ARLine
    
	/* get next line. */
GetNextLine:
   	fetch next from bcarline into @ARLine
   
	End   /* End Spinning through lines */
   
   /* WILL NEVER HAPPEN IF 'FinanceChg' COLUMN IS ACCURATE. LEFTOVER FROM PRE-5.71 CODE */
   /*
      If the customer pays the entire line, including the FinChg, then no amount will
      be written off for that line.  However we must write off Finance Charges somewhere.
      Any amounts still not written off will be written off against the last line.
      This will mainly occur on old data, before cash receipts allowed excluding 
      Finance Charges. */
   if @lastline is not null and (@AmtLeft <> 0)
    	begin
    	update bARBL
    	set Amount = Amount + @AmtLeft, FinanceChg = FinanceChg + @AmtLeft 
      	where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq and
		ApplyMth = @ApplyMth and ApplyTrans = @ApplyTrans and ApplyLine = @lastline
   		end
   
bspexit:
   
if @openarlinecursor = 1
   	begin
   	close bcarline
   	deallocate bcarline
   	select @openarlinecursor = 0
   	end
   
if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[bspARAutoWriteOffByLine]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARAutoWriteOffByLine] TO [public]
GO
