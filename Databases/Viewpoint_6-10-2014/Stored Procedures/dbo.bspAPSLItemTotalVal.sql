SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPSLItemTotalVal    Script Date: 8/28/99 9:34:05 AM ******/
   CREATE       proc [dbo].[bspAPSLItemTotalVal]
    /********************************************************
    * CREATED BY: 	SE 10/7/97
    * MODIFIED BY:  GG 06/22/99
    *               GR 09/01/99 - Added an additional check to see if CurrCost is less than or greater than zero in order to compare
    *                             with Total Current Cost and changed the warning message accordingly
    *               GR 10/11/99 - modified - to check whether the subcontracts item's amount exceed the
    *                             invoiced amounts for positive and negative amounts
    *               GR 08/18/00 - #8026 added the check to see if the total of invoiced for all items exceeds
    *                             the subcontract's total amount
    *              kb 10/29/2 - issue #18878 - fix double quotes
    *				MV 09/11/03 - #22441 SL Item error message gets overridden by Subcontract total error msg if both are true
    *				MV 12/12/03 - #23225 don't include misc amt in checking invoice cost against current cost.
    *				ES 03/12/04 - #23061 isnull wrapping
    *				MV 08/25/04 - #21649 - include AP batch and other UI amounts when validating Unapproved
    *				MV 09/07/04 - #24728 - back out old taxamt from slinvcost
    *				MV 01/16/09 - #126613 - for negative SL Items check abs(value)
    *				GP 6/28/10 - #135813 change bSL to varchar(30) 
    * USAGE:
    * Used by the AP Transaction Entry, Unapproved Invoice Entry,
    * and AP Expense Batch validation procedure to determine if a
    * Subcontract Item's Invoiced Amount exceeds its Current Total Cost.
    *
    * When used to validate amounts from a data entry program, pass in
    * the current line and amount.  These are needed because validation
    * occurs before the tables are updated.
    *
    * INPUT PARAMETERS:
    *   @co         AP Co#
    *   @mth        Batch Month
    *   @batchid    Batch ID
    *	@sl         Subcontract
    *   @slitem     Subcontract Item
    *   @source     'U' = Unapproved Invoice, 'E' = AP Transaction
    *   @uiseq      Unapproved Invoice Sequence #
    *   @line       Current line # of Unapproved or Transaction Entry
    *   @amt        Amount to be invoiced with current line
    *
    * OUTPUT PARAMETERS:
    *	@msg        Error message
    *
    * RETURN VALUE:
    * 	0               Invoiced <= Current Total Cost
    *	1               Invoiced > Current Total Cost
    **********************************************************/
    	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
    	 @sl varchar(30) = null, @slitem bItem = null, @source char(1) = null, @uiseq smallint = null,
    	 @line smallint = null, @amt bDollar = null,@msg varchar(500) output)
    as
    set nocount on
   
    declare @rcode int, @slinvcost bDollar, @slcurrcost bDollar, @freightnew bDollar,
    @freightold bDollar, @oldgross bDollar, @newgross bDollar, @sltotalcurcost bDollar,
    @sltotalinvcost bDollar, @freightslnew bDollar, @freightslold bDollar, @oldslgross bDollar,
    @newslgross bDollar,@uigross bDollar,@uislgross bDollar, @oldtaxamt bDollar, @oldsltaxamt bDollar,
    @taxamt bDollar, @sltaxamt bDollar
   
    select @rcode = 0
   
    if @source not in ('E','U')
        begin
        select @msg = 'Invalid source.  Must be (E) or (U)!', @rcode = 1
        goto bspexit
        end
   
    -- get current amounts from SL Item
    select @slinvcost = InvCost, @slcurrcost = CurCost
    from bSLIT
    where SLCo = @co and SL = @sl and SLItem = @slitem
    if @@rowcount = 0
        begin
        select @msg = 'Subcontract: ' + isnull(@sl, '') + ' and Item: ' 
   			+ isnull(convert(varchar(6),@slitem), '') + ' not found!', @rcode=1  --#23061
        goto bspexit
        end
   
    -- get subcontract's current amount
    select @sltotalcurcost = isnull(sum(CurCost), 0), @sltotalinvcost = isnull(sum(InvCost), 0)
    from bSLIT
    where SLCo= @co and SL = @sl
    if @@rowcount = 0
        begin
        select @msg = 'Subcontract: ' + isnull(@sl, '') +  ' not found!', @rcode=1 --#23061
        goto bspexit
        end
   
    if @source = 'E'   -- AP Transaction Entry
        begin
    	-- get old amounts from changed and deleted entries
    	select @oldgross = isnull(sum(OldGrossAmt),0), @oldtaxamt = isnull(sum(OldTaxAmt),0)
   		/*,@freightold= isnull(sum (CASE WHEN OldMiscYN = 'Y' THEN OldMiscAmt ELSE 0 END),0)*/ --23225
    	from bAPLB
    	where Co = @co and Mth = @mth and BatchId = @batchid
        and OldSL = @sl and OldSLItem = @slitem and BatchTransType in ('C','D')
   
    	-- get new amounts from added and changed entries
    	select @newgross = isnull(sum(GrossAmt),0)
   	   /*, @freightnew= isnull(sum(CASE WHEN MiscYN = 'Y' THEN MiscAmt ELSE 0 END),0)*/ --23225
    	from bAPLB
    	where Co = @co and Mth = @mth and BatchId = @batchid and APLine <> isnull(@line,0) -- skip current line
            and SL = @sl and SLItem = @slitem and BatchTransType in ('C', 'A')
   
       -- get old subcontract's amounts from changed and deleted entries
    	select @oldslgross = isnull(sum(OldGrossAmt),0), @oldsltaxamt = isnull(sum(OldTaxAmt),0)
   		/*,@freightslold= isnull(sum (CASE WHEN OldMiscYN = 'Y' THEN OldMiscAmt ELSE 0 END),0)*/
    	from bAPLB
    	where Co = @co and Mth = @mth and BatchId = @batchid
        and OldSL = @sl and BatchTransType in ('C','D')
   
    	-- get new subcontract's amounts from added and changed entries
    	select @newslgross = isnull(sum(GrossAmt),0)
   		/*,@freightslnew= isnull(sum(CASE WHEN MiscYN = 'Y' THEN MiscAmt ELSE 0 END),0)*/  --23225
    	from bAPLB
    	where Co = @co and Mth = @mth and BatchId = @batchid and APLine <> isnull(@line,0) -- skip current line
            and SL = @sl and BatchTransType in ('C', 'A')
       -- end of issue# 8026
    	end
   
    if @source = 'U'   -- Unapproved Invoices  
        begin
   	-- get amounts from this UImth and UIseq for SL Item
    	select @uigross= isnull(sum(GrossAmt),0)
    	 from bAPUL
    	  where APCo = @co and SL = @sl and SLItem = @slitem and
   			(UIMth <> @mth or UISeq <> @uiseq or Line <> isnull(@line,0)) 
   
       --get amounts from this UImth and UISeq for SL
    	select @uislgross = isnull(sum(GrossAmt),0)
   	from bAPUL
    	  where APCo = @co and SL = @sl and (UIMth <> @mth or UISeq <> @uiseq or Line <> isnull(@line,0)) 
   
   	-- get old amounts from changed and deleted entries in AP batches for SL Item
    	select @oldgross = isnull(sum(OldGrossAmt),0), @oldtaxamt = isnull(sum(OldTaxAmt),0)
    	from bAPLB
    	where Co = @co and OldSL = @sl and OldSLItem = @slitem and BatchTransType in ('C','D')
   
    	-- get new amounts from added and changed entries in AP batches for SL Item
    	select @newgross = isnull(sum(GrossAmt),0)
    	from bAPLB
    	where Co = @co and SL = @sl and SLItem = @slitem and BatchTransType in ('C', 'A')
   
       -- get old amounts from changed and deleted entries in AP batches for SL
    	select @oldslgross = isnull(sum(OldGrossAmt),0), @oldsltaxamt = isnull(sum(OldTaxAmt),0)
    	from bAPLB
    	where Co = @co and OldSL = @sl and BatchTransType in ('C','D')
   
    	-- get new amounts from added and changed entries in AP batches for SL
    	select @newslgross = isnull(sum(GrossAmt),0)
    	from bAPLB
    	where Co = @co and SL = @sl and BatchTransType in ('C', 'A')
   
   	-- add gross and tax amounts
   	select @newgross = @newgross + @uigross, @newslgross = @newslgross + @uislgross
   
    	end
   
    -- check to see if item's Total Current Cost has been exceeded
   
       if @slcurrcost >= 0
   	    begin
   	    if ((@newgross - @oldgross) + (isnull(@amt,0)) + (@slinvcost - @oldtaxamt)) > @slcurrcost 
   	        select @msg='Invoiced amounts exceed the total cost for Subcontract: ' 
   				+ isnull(@sl, '') + ' Item: ' + isnull(convert(varchar(5),@slitem), ''), @rcode=1 --#23061
   			if @rcode = 1 goto bspexit	--22441 exit so this error message is returned
   	    else
   	        select @msg = 'Invoiced amount OK!', @rcode=0
   	    end
       else
   	    begin
   	    if isnull(@amt, 0) > 0
   	        select @msg='Subcontract: ' + isnull(@sl, '') + ' Item: ' 
   			+ isnull(convert(varchar(5),@slitem), '') + ' has a negative amount', @rcode=1  --#23061
   	    else
   	        begin
   	        if abs(((@newgross - @oldgross) + (isnull(@amt,0)) + (@slinvcost - @oldtaxamt))) > abs(@slcurrcost) 
   	            select @msg='Invoiced amounts exceed the total cost for Subcontract: ' + isnull(@sl, '') 
   					+ ' Item: ' + isnull(convert(varchar(5),@slitem), ''), @rcode=1
   				if @rcode = 1 goto bspexit	--22441 exit so this error message is returned
   	        else
   	            select @msg = 'Invoiced amount OK!', @rcode=0
   	        end
       end
   
    -- check to see if subcontract's total current cost has been exceeded
       if abs(((@newslgross - @oldslgross)+ (isnull(@amt,0)) + (@sltotalinvcost - @oldsltaxamt))) > abs(@sltotalcurcost)
           select @msg='Invoiced amounts exceed the total cost for Subcontract: ' + isnull(@sl, ''), @rcode=1  --#23061
   
           /*select @msg='newslgross - oldslgross) + (freightslnew - freightslold) + isnull(amt,0) + sltotalinvcost) ' +
               convert(varchar(12),@newslgross) + '-' + convert(varchar(12),@oldslgross) + '-' +
               convert(varchar(12),@freightslnew) + '-' +
               convert(varchar(12),@freightslold) + '-' + convert(varchar(12),@amt) + '-' +
               convert(varchar(12),@sltotalinvcost) + '-' + convert(varchar(12),@sltotalcurcost)
           ,@rcode=1*/
    bspexit:
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPSLItemTotalVal] TO [public]
GO
