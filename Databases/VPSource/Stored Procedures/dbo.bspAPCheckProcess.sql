SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE            proc [dbo].[bspAPCheckProcess]
   /***********************************************************
    * CREATED BY	: SE 10/12/97
    * MODIFIED BY	: GG 06/29/99 GR 7/1/99
    * MODIFIED by : kb 8/3/99 - rem'd out a goto APPB_END in the reprint/void section which
    *                was causing problems when voiding checks.
    *               kb 8/4/99 - was not assigning checks in sort name order as it should.
    *               EN 1/22/00 - expand dimension of @beginname & @endname from 30 to 60
    *               kb 4/10/00 - Issue #6313, when specifying a begin/end seq it and a vendor
    *                 to print it wasn't really restricting by the begin/end seq.
    *               GG 05/08/00 - Fix numeric check on CMRef to avoid errors if decimal point exists
    *               kb 10/17/00 - Issue #10211
    *              kb 12/11/00 - issue #9166
    *              kb 7/25/1 - issue #13736
    *              kb 10/25/1 - issue #15047
    *              kb 1/22/2 -issue #15845
    *				 kb 1/23/2 - issue #15950
    *              kb 3/17/2 -issue #16663
    *              kb 4/1/2 -issue #16663
    *              kb 4/11/2
    *                 kb 4/29/2 - issue #15845
    *                 kb 5/15/2 - issue #15845
    *                 kb 6/4/2 - issue #17566
    *		     mv 7/3/02 - #17168 check for check range in bCMDT
    *			mv 8/26/02 - #17168 - add CMTransType to selection criteria for bCMDT
    *			mv 9/11/02 - #17344 - changed where clauses for selecting recs to print or reprint
    *			mv 09/24/02 - #18262 - increase begin check and end check to 10 digits
    *			mv 10/18/02 - 18878 quoted identifier cleanup
    *			mv 10/28/02 - #17344 rej2 fix - remove vendor number from selection criteria use name and/or seq #
    *			GG 11/15/02 - #19350 - modified input params, order by Vendor Sort Name, cleanup
    *          bc 12/08/02 - #19602 - corrected Ending Check # at the very end of the procedure
    *			mv 12/23/02 - #19732 - wasn't returning the correct endcheck# unless the 
   						user entered the exact endcheck# to begin with. 
    *          bc 01/30/03 - #20230 changed convert(numeric) to convert(float) on the CMRef value
    *			mv 02/19/03 - #20339 - prevent a blank payee from being printed
    *			mv 03/27/03 - #20857 - void insert of bAPPB failing on BatchSeq = @batchid
    *			mv 04/15/03 - #20955 - restore CMRef checking in bAPPH
    *			MV 02/19/04 - #18769 - pay category / #23061 isnull wrap
    *			MV 08/13/07 - #27755 - if reprint, get @endcheck from @endseq for check # range validation 
    *			MV 10/04/07 - #125657 - changed CMRef validation from float to bigint
	*			MV 08/05/08 - #127576 - put CMRef validation back to float for check #s with decimals.
	*			MV 10/1/08 -  #130004 - commented out code to set @endcheck for Reprint - caused problems.
	*			MV 01/21/09 - #130832 - removed void and clear processes from this sp: now in vspAPCheckClearVoid

    * Called by the AP Check Print program to remove and/or assign check numbers to sequences
    * in an AP Payment Batch.  Used just prior to printing checks using a Crystal Report.
    *
    * Beginning and ending Vendor Name, number, and sequence are used to restict processing.
    * If null, assume first through last values
    *
    * INPUT PARAMETERS
    *  @apco               AP Company #
    *  @month              Batch Month
    *  @batchid            Payment BatchId
    *  @sendcmco           CM Company
    *  @cmacct             CM Account
    *  @paiddate           Paid date for checks
    * 	@beginsortname		Beginning Vendor Sort Name - null for reprint - #19350
    *	@endsortname		Ending Vendor Sort Name - null for reprint - #19350
    *  @beginseq           Begining Payment Seq# - required for reprint
    *  @endseq             Ending Payment Seq# - required for reprint
    *  @begincheck         Beginning check #
    *  @reprint            'Y' = remove existing check #s, 'N' = skip if check # exists
    *  @void               'Y' = void check #s removed during reprint, 'N' = do not void check #s removed during reprint
    *  @voidmemo           Memo to record with voided checks
    *
    * OUTPUT PARAMETERS
    *  @endcheck           Ending Check #
    *  @overflowsexist     'Y' = Overflows exist for one or more checks, 'N' = no overflows exist
    *  @msg                error message
    *
    * RETURN VALUE
    *   0                  success
    *   1                  failure
    *****************************************************/
   	(@apco bCompany = null, @month bMonth = null, @batchid bBatchID = null,
   	 @sendcmco bCompany = null, @cmacct bCMAcct = null, @paiddate bDate = null,
   	 @beginsortname bSortName = null, @endsortname bSortName = null,
   	 @beginseq int = null, @endseq int = null, @begincheck bigint = null, @endcheck bigint output,
   	 /*@reprint bYN = 'N', @void bYN = 'N', @voidmemo varchar(255) = null,*/ @overflowsexist varchar(1) output,
   	 @needmorechks bYN output, @msg varchar(255) output)
       
   as
    
   set nocount on
    
   declare @rcode int, @checknumstring bCMRef, @opencursorAPPB tinyint, @seq int,
       @checknum bigint, @batchseq int, @chklines tinyint, @sortname bSortName,
       @overflow bYN, @opencursorAPPB1 tinyint, @expmth bMonth, @aptrans bTrans,
       @retainage bDollar, @retpaytype tinyint, @prevpaid bDollar, @batchprevpaid bDollar,
       @prevdisc bDollar, @batchprevdisc bDollar, @balance bDollar, @batchbalance bDollar,
       @disctaken bDollar, @otherbalance bDollar, @paycategory int
   
   -- parameter validation
   if @apco is null or @month is null or @batchid is null
   	begin
   	select @msg = 'Missing AP Co#, Month, and/or Batch ID#', @rcode = 1
   	goto bspexit
   	end
   -- get check related info from AP Company
   select @chklines = ChkLines, @retpaytype = RetPayType
   from bAPCO
   where APCo = @apco 
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid AP Co#', @rcode = 1
   	goto bspexit
   	end
   
   -- get Beginning Vendor Sort Name and Seq# if not provided
   if @beginsortname is null and @beginseq is null
   	begin
   	-- get first Vendor Sort Name in the Batch
   	select @beginsortname = min(v.SortName)
   	from bAPVM v with (nolock)
   	join bAPPB b on v.VendorGroup = b.VendorGroup and v.Vendor = b.Vendor
   	where b.Co = @apco and b.Mth = @month and b.BatchId = @batchid 
   	-- get first Seq for this Vendor
   	select @beginseq = min(b.BatchSeq)
   	from bAPVM v with (nolock)
   	join bAPPB b on v.VendorGroup = b.VendorGroup and v.Vendor = b.Vendor
   	where b.Co = @apco and b.Mth = @month and b.BatchId = @batchid and v.SortName = @beginsortname
   	end
   if @beginsortname is null and @beginseq is not null
   	begin
   	-- get Vendor Sort Name based on Seq
   	select @beginsortname = v.SortName
   	from bAPVM v with (nolock)
   	join bAPPB b on v.VendorGroup = b.VendorGroup and v.Vendor = b.Vendor
   	where b.Co = @apco and b.Mth = @month and b.BatchId = @batchid and b.BatchSeq = @beginseq
   	end
   if @beginsortname is not null and @beginseq is null
   	begin
   	-- get first Seq based on Sort Name
   	select @beginseq = min(b.BatchSeq)
   	from bAPVM v with (nolock)
   	join bAPPB b on v.VendorGroup = b.VendorGroup and v.Vendor = b.Vendor
   	where b.Co = @apco and b.Mth = @month and b.BatchId = @batchid and v.SortName = @beginsortname
   	end
   if @beginsortname is null or @beginseq is null
   	begin
   	select @msg = 'Unable to determine beginning Vendor Sort Name and/or Payment Seq!', @rcode = 1
   	goto bspexit
   	end
   
   -- get Ending Vendor Sort Name and Seq# if not provided
   if @endsortname is null and @endseq is null
   	begin
   	-- get last Vendor Sort Name in the Batch
   	select @endsortname = max(v.SortName)
   	from bAPVM v with (nolock)
   	join bAPPB b on v.VendorGroup = b.VendorGroup and v.Vendor = b.Vendor
   	where b.Co = @apco and b.Mth = @month and b.BatchId = @batchid 
   	-- get last Seq for this Vendor
   	select @endseq = max(b.BatchSeq)
   	from bAPVM v with (nolock)
   	join bAPPB b on v.VendorGroup = b.VendorGroup and v.Vendor = b.Vendor
   	where b.Co = @apco and b.Mth = @month and b.BatchId = @batchid and v.SortName = @endsortname
   	end
   if @endsortname is null and @endseq is not null
   	begin
   	-- get Vendor Sort Name based on Seq
   	select @endsortname = v.SortName
   	from bAPVM v with (nolock)
   	join bAPPB b on v.VendorGroup = b.VendorGroup and v.Vendor = b.Vendor
   	where b.Co = @apco and b.Mth = @month and b.BatchId = @batchid and b.BatchSeq = @endseq
   	end
   if @endsortname is not null and @endseq is null
   	begin
   	-- get last Seq based on Sort Name
   	select @endseq = max(b.BatchSeq)
   	from bAPVM v with (nolock)
   	join bAPPB b on v.VendorGroup = b.VendorGroup and v.Vendor = b.Vendor
   	where b.Co = @apco and b.Mth = @month and b.BatchId = @batchid and v.SortName = @endsortname
   	end
   if @endsortname is null or @endseq is null
   	begin
   	select @msg = 'Unable to determine ending Vendor Sort Name and/or Payment Seq!', @rcode = 1
   	goto bspexit
   	end
	
  
   select @checknum = 0, @overflowsexist = 'N', @needmorechks='N'
   
/* Moved this code to vspAPCheckClearVoid for issue #130832*/
   -- Reprint - checks may be voided
--   if @reprint = 'Y' 
--   	begin
--       -- create a cursor to process range of Payment Seq#s
--       declare bcAPPBr cursor local fast_forward for
--   	select b.BatchSeq 
--   	from bAPPB b with (nolock)
--   	join bAPVM v on v.VendorGroup = b.VendorGroup and v.Vendor = b.Vendor
--   	where b.Co = @apco and b.Mth = @month and b.BatchId = @batchid 
--       	and b.CMAcct = @cmacct and b.PayMethod = 'C' and b.ChkType = 'C'
--   		and b.CMRef is not null and b.VoidYN = 'N' and (b.Name is not null or b.Name <> '')
--   		and ((v.SortName > @beginsortname ) or (v.SortName = @beginsortname and BatchSeq >= @beginseq))
--    		and ((v.SortName < @endsortname) or (v.SortName = @endsortname and BatchSeq <= @endseq))
--   	order by v.SortName, b.BatchSeq		-- order must match check # assignment
--   
--   	-- open cursor
--   	open bcAPPBr
--   	select @opencursorAPPB = 1
--   
--   	void_loop:	-- process each payment to be voided
--   		fetch next from bcAPPBr into @batchseq
--   
--   		if @@fetch_status <> 0 goto void_end
--   
--   		if @void = 'Y'	-- check # will not be reused, must be added to payment batch as 'void'
--   			begin
--   	     	-- get next available Batch Seq#
--   			select @seq = isnull(max(BatchSeq),0) + 1
--   	        	from bAPPB with (nolock)
--   	        	where Co = @apco and Mth = @month and BatchId = @batchid
--   	
--   	        -- add void entry
--   	        	insert bAPPB(Co, Mth, BatchId, BatchSeq, CMCo, CMAcct, PayMethod,
--   	        	CMRef, CMRefSeq, ChkType, VendorGroup, Vendor, Name, Address,
--   	            City, State, Zip, PaidDate, Amount, Supplier, VoidYN, VoidMemo, ReuseYN, Overflow)
--   			select Co, Mth, BatchId, @seq, CMCo, CMAcct, PayMethod,
--   				CMRef, CMRefSeq, ChkType, VendorGroup, Vendor, Name, Address,
--   				City, State, Zip, PaidDate, Amount, Supplier, 'Y', @voidmemo, 'N', 'N'
--   			from bAPPB
--   			where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq /*@batchid*/ --20857
--   	        	if @@rowcount <> 1
--   				begin
--   				select @msg = 'Unable to add voided check entry into Payment Batch.', @rcode = 1
--   				goto bspexit
--   				end
--   			end
--   		-- remove existing CM Reference #
--       	update bAPPB
--       	set CMRef = null, CMRefSeq = null
--       	where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq
--   		if @@rowcount <> 1
--   			begin
--   			select @msg = 'Unable to remove Check # from voided entry.', @rcode = 1
--   			goto bspexit
--   			end
--   
--   		goto void_loop
--   
--   	void_end:	-- finished with voided checks
--       	close bcAPPBr
--           deallocate bcAPPBr
--   		select @opencursorAPPB = 0
--    end 			
    
    
  -- validate Check # range in Payment Batch
	   if exists(select 1 from bAPPB with (nolock) where PayMethod = 'C' and CMCo = @sendcmco and CMAcct = @cmacct
            and case isNumeric(CMRef) WHEN 1 THEN convert(float,CMRef) ELSE 0 END >= @begincheck
   		    and case isNumeric(CMRef) WHEN 1 THEN convert(float,CMRef) ELSE 9999999999 END <= @endcheck)
		begin
		   select @msg = 'Entries in a Payment Batch have already been assigned Check#s in the selected range!', @rcode = 1
		   goto bspexit
		end

      
   -- validate Check # range in Payment History
	   if exists(select 1 from bAPPH where PayMethod='C' and CMCo=@sendcmco and CMAcct=@cmacct
                   and case isNumeric(CMRef) when 1 THEN convert(float,CMRef) ELSE 0 END >= @begincheck
                   and case isNumeric(CMRef) WHEN 1 THEN convert(float,CMRef) ELSE 9999999999 END <= @endcheck)
        begin
          select @msg='Entries in AP Payment History already exist in selected range!', @rcode=1
          goto bspexit
        end
   
   --  validate Check # range in CM Detail - #17168 
   if exists(select 1 from bCMDT with (nolock) where CMCo = @sendcmco and CMAcct = @cmacct and CMTransType = 1	-- checks
                and case isNumeric(CMRef) WHEN 1 THEN convert(float,CMRef) ELSE 0 END >= @begincheck
                and case isNumeric(CMRef) WHEN 1 THEN convert(float,CMRef) ELSE 9999999999 END <= @endcheck)
    	begin
    	select @msg = 'Check #s in the selected range already exist as CM Detail!', @rcode = 1
       goto bspexit
    	end
    
   -- create a cursor to process Payment Batch entries for payment
   declare bcAPPB1 cursor local fast_forward for
   select b.BatchSeq
   from bAPPB b with (nolock)
   join bAPVM v on v.VendorGroup = b.VendorGroup and v.Vendor = b.Vendor
   where b.Co = @apco and b.Mth = @month and b.BatchId = @batchid 
       and b.CMAcct = @cmacct and b.PayMethod = 'C' and b.ChkType = 'C' 
   	and b.CMRef is null and b.Amount > 0 and (b.Name is not null or b.Name <> '')
   	and ((v.SortName > @beginsortname ) or (v.SortName = @beginsortname and BatchSeq >= @beginseq))
    	and ((v.SortName < @endsortname) or (v.SortName = @endsortname and BatchSeq <= @endseq))
   order by v.SortName, b.BatchSeq		
   
   -- open cursor  
   open bcAPPB1
   select @opencursorAPPB1 = 1, @checknum = @begincheck
    
   payment_loop:	-- process each payment
   	fetch next from bcAPPB1 into @batchseq
    
       if @@fetch_status <> 0 goto payment_end
    
       -- update APTB fields Retainage,PrevPaid,PrevDisc,Balance,DiscTaken
       select @expmth = min(ExpMth)	-- first month
   	from bAPTB with (nolock)
   	where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq
       while @expmth is not null
       	begin
           select @aptrans = min(APTrans)	-- first transaction
   		from bAPTB with (nolock)
   		where Co = @apco and Mth = @month  and BatchId = @batchid and BatchSeq = @batchseq and ExpMth = @expmth
         	while @aptrans is not null
         		begin
   			-- get transaction balance
            	select @balance = isnull(sum(Amount),0)
   			from bAPTD with (nolock)
   			where APCo = @apco and Mth = @expmth and APTrans = @aptrans and Status < 3
   
    			-- get transaction batch balance 
            	select @batchbalance = isnull(sum(Amount),0)
   			from bAPDB with (nolock)
   			where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq
             		and ExpMth = @expmth and APTrans = @aptrans
   
    			-- adjust transaction balance by batch amount
            	select @balance = @balance - @batchbalance
   
    			-- get transaction retainage
            	select @retainage = sum(d.Amount)from bAPTD d with (nolock)
   				where d.APCo = @apco and d.Mth = @expmth and d.APTrans = @aptrans and d.Status = 2
   				and ((d.PayCategory is null and d.PayType = @retpaytype) 
   					 or (d.PayCategory is not null and d.PayType = (select c.RetPayType from bAPPC c with (nolock)
   						 where c.APCo=@apco and c.PayCategory = d.PayCategory)))
   			/*where APCo = @apco and Mth = @expmth and APTrans = @aptrans and PayType = @retpaytype and Status = 2*/
   
   			-- get transaction previously paid  and discount amounts
            	select @prevpaid = sum(Amount) - sum(DiscTaken),  @prevdisc = sum(DiscTaken)
              	from bAPTD with (nolock)
   			where APCo = @apco and Mth = @expmth and APTrans = @aptrans and Status > 2
   
   			-- get transaction batch previous discount and paid amounts
            	select @batchprevdisc = sum(DiscTaken), @batchprevpaid = sum(Amount) - sum(DiscTaken)
              	from bAPDB with (nolock)
   			where Co = @apco and ExpMth = @expmth and APTrans = @aptrans and BatchId = @batchid
   				and Mth = @month and BatchSeq < @batchseq
   
   			-- get transaction batch discount taken
               select @disctaken = sum(DiscTaken)
   			from bAPDB with (nolock)
   			where Co = @apco and ExpMth = @expmth and APTrans = @aptrans and Mth = @month
               	and BatchId = @batchid and BatchSeq = @batchseq
   
   			-- final transaction amounts
               select @disctaken = isnull(@disctaken,0), @retainage = isnull(@retainage,0),
                    @prevpaid = isnull(@prevpaid,0) + isnull(@batchprevpaid,0),
                    @prevdisc = isnull(@prevdisc,0) + isnull(@batchprevdisc,0)
                    
               select @balance = @balance - isnull(@batchprevpaid,0) - isnull(@batchprevdisc,0)
   
   			-- update transaction batch amounts
               update bAPTB
   			set Retainage = @retainage, PrevPaid = @prevpaid, PrevDisc = @prevdisc,
     				Balance = @balance - @retainage, DiscTaken = @disctaken
               from bAPTB
      			where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq
   				and ExpMth = @expmth and APTrans = @aptrans
   			if @@rowcount <> 1
   				begin
   				select @msg = 'Unable to update Payment Batch transaction totals!',@rcode = 1
   				goto bspexit
   				end
   
   			-- next transaction
               select @aptrans = min(APTrans)
   			from bAPTB with (nolock)
   			where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq
   				and ExpMth = @expmth and APTrans > @aptrans
               end
   
   		-- next month
   		select @expmth = min(ExpMth)
   		from bAPTB with (nolock)
   		where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq and ExpMth > @expmth
           end
    
   	--  do not assign a check number to sequences with no lines - kb 1/7/99 */
       if not exists(select 1 from bAPTB where Co = @apco and Mth = @month and BatchId = @batchid
                   and BatchSeq = @batchseq) goto payment_loop	-- skip to next payment batch entry
    
      -- right justify check #
      select @checknumstring = space(10-datalength(isnull(convert(varchar(10),@checknum), ''))) + isnull(convert(varchar(10),@checknum), '') --#23061
   	-- check for stub overflow
   	select @overflow = 'N'
   	if(select count(*) from bAPTB with (nolock) where Co = @apco and Mth = @month and BatchId = @batchid
       	and BatchSeq = @batchseq) > @chklines  select @overflow = 'Y', @overflowsexist = 'Y'
            
   	-- make sure we haven't run out of check #s
       if @checknum > @endcheck
       	begin
      		select @msg = 'Please select additional check numbers to complete check print.', 
           	@needmorechks = 'Y', @endcheck = @checknum - 1   -- pass back flag and last printed check#
      		goto bspexit
      		end
   
       -- update Check # to Payment Batch Header
       update bAPPB
       set CMRef = @checknumstring, CMRefSeq = 0, PaidDate = @paiddate, Overflow = @overflow, CMCo = @sendcmco
       where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq
       select @checknum = @checknum + 1    -- increment check #
    
   	goto payment_loop	-- process next payment batch entry
    
   payment_end:	-- finished with payments 
   	close bcAPPB1
      	deallocate bcAPPB1
       select @opencursorAPPB1 = 0           
    
   
   /* 19732 - set endcheck# - works if either the exact endcheck# is entered or any larger # like the default */
   if @checknum = @begincheck	
   	begin
   	select @msg = 'No checks were processed in this selected range.', @rcode = 1
   	end
   if @checknum > @begincheck
   	begin
   	select @endcheck = @checknum - 1
   	end
    
   /*if @checknum = @endcheck			--this only works if the exact endcheck# is entered
       begin
       select @endcheck = @checknum - 1
       end
   
 
   if @endcheck = @begincheck - 1	--this only works if the exact endcheck# is entered
   	begin
   	select @msg = 'No checks were processed in this selected range.', @rcode = 1
   	end*/
    
   bspexit:
   	if @opencursorAPPB = 1
      		begin
      		close bcAPPBr
      	    deallocate bcAPPBr
      		end
       if @opencursorAPPB1 = 1
      		begin
      		close bcAPPB1
      	    deallocate bcAPPB1
      		end
    
   	if @rcode <> 0 select @msg = isnull(@msg,'') --+ char(13) + char(10) + '[bspAPCheckProcess]'
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPCheckProcess] TO [public]
GO
