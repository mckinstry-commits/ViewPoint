SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPBPrePaid    Script Date: 8/28/99 9:34:02 AM ******/
    
    CREATE        proc [dbo].[bspAPPBPrePaid]
    /***********************************************************
     * CREATED BY: kf 10/21/97
     * MODIFIED By : GG 4/30/99
     *               EN 1/22/00 - expand dimension of @payname, @name & @pbname to varchar(60)
     *                  and include AddnlInfo when adding to bAPPB
     *              GG 11/27/00 - changed datatype from bAPRef to bAPReference
     *			 MV 10/28/02 - #18037 set pay address info
     *			 MV 10/28/02 - #188878 quoted identifier cleanup.
     *			 MV 02/19/04 - #18769 Pay Category / performance enhancements
     *			 ES 03/11/04 - #23061 isnull wrapping
     *			 MV 07/08/04 - #25051 added @paycategory to (Status=2 and @paytype <> @retpaytype)
	 *			 MV 12/29/05 - #27761 6X recode - removed @endseq and @source - they aren't used
	 *			 MV 03/13/08 - #127347 International addresses
     * USAGE:
     * Called from AP Prepaid Check Processing form to add or remove
     * unprocessed prepaid transactions to a payment batch.
     *
     * INPUT PARAMETERS
     *  @co             AP Company
     *  @mth            Batch month - will match paid month on checks
     *  @batchid        BatchId
     *  @source         'P' = prepaid - removed
    
     *  @sendcmco       CM Company - used to restrict
     *  @sendcmacct     CM Account - used to restrict
     *  @postedby       Name of user who posted transaction - used to restrict
     *  @mode           'A' = adding entries, 'D' = deleting entries
     *  @batchseq       Payment Batch Sequence - used to remove a single entry, null for all
     *  @endseq         Ending sequence - removed
     *
     * OUTPUT PARAMETERS
     *  @count          # of entries added or deleted from batch
     *  @msg            error message
     *
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
        (@co bCompany, @mth bMonth, @batchid bBatchID,@sendcmco bCompany = null,
        @sendcmacct bCMAcct = null, @postedby bVPUserName = null, @mode char(1)= null,
        @batchseq int = null, @count int output, @msg varchar(255) output)
    
    as
    
    set nocount on
    
    declare @rcode int, @retpaytype tinyint, @openPrepaid tinyint, @expmth bMonth, @aptrans bTrans,
    @vendorgroup bGroup, @vendor bVendor, @apref bAPReference, @description bDesc, @invdate bDate,
    @cmco bCompany, @cmacct bCMAcct, @prepaiddate bDate, @prepaidchk bCMRef, @prepaidseq tinyint,
    @payoverrideyn bYN, @payname varchar(60), @payaddinfo varchar(60), @payaddress varchar(60), @paycity varchar(30), @paystate varchar(4),
    @payzip bZip, @supplier bVendor, @name varchar(60), @addnlinfo varchar(60), @address varchar(60), @city varchar(30), @state varchar(4),
    @zip bZip, @pbseq int, @pbvendor bVendor, @pbname varchar(60), @pbaddinfo varchar(60), @pbaddress varchar(60), @pbpaiddate bDate,
    @pbamount bDollar, @pbsupplier bVendor, @openDetail tinyint, @apline smallint, @apseq tinyint, @status tinyint,
    @paytype tinyint, @disctaken bDollar, @amount bDollar, @retainage bDollar, @prevpaid bDollar, @prevdisc bDollar,
    @balance bDollar, @disc bDollar, @addressseq tinyint, @paycategory int,@paycountry char(2),@country char(2)
    
    select @rcode = 0, @count = 0
    
    -- get Retainage Pay Type
    select @retpaytype = RetPayType
    from bAPCO where APCo = @co
    if @@rowcount = 0
        begin
        select @msg = 'Missing AP Company.', @rcode = 1
        goto bspexit
        end
    

    if @sendcmacct is null select @sendcmco = null    -- if not restricting by CM Account, don't restrict by CM Co#
	if @postedby = '' select @postedby = null
    
    -- delete Prepaids from the Payment Batch
    if @mode = 'D'
     	begin
		if @batchseq = 0 select @batchseq = null
        -- delete Payment Batch Detail
        delete from bAPDB
        from bAPDB, bAPPB
        where bAPDB.Co = bAPPB.Co and bAPDB.Mth = bAPPB.Mth and bAPDB.BatchId = bAPPB.BatchId
            and bAPDB.BatchSeq = bAPPB.BatchSeq and bAPPB.Co = @co and bAPPB.Mth = @mth
            and bAPPB.BatchId = @batchid and bAPPB.BatchSeq = isnull(@batchseq, bAPPB.BatchSeq)
            and bAPPB.ChkType = 'P' and bAPPB.VoidYN = 'N'
    
        -- delete Payment Batch Transactions
        delete from bAPTB
        from bAPTB, bAPPB
        where bAPTB.Co = bAPPB.Co and bAPTB.Mth = bAPPB.Mth and bAPTB.BatchId = bAPPB.BatchId
            and bAPTB.BatchSeq = bAPPB.BatchSeq and bAPPB.Co = @co and bAPPB.Mth = @mth
            and bAPPB.BatchId = @batchid and bAPPB.BatchSeq = isnull(@batchseq, bAPPB.BatchSeq)
            and bAPPB.ChkType = 'P' and bAPPB.VoidYN = 'N'
    
        -- delete Payment Batch Header
        delete from bAPPB
        where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = isnull(@batchseq, BatchSeq)
        and ChkType = 'P' and VoidYN = 'N'
    
        select @count = @@rowcount
        goto bspexit
        end
    
    -- add unprocessed Prepaids to Payment Batch
    if @mode = 'A'
        begin
        -- create a cursor on all unprocessed prepaid transactions - may be restricted by CM Account or User
    	declare bcPrepaid cursor for
        select h.Mth, h.APTrans, h.VendorGroup, h.Vendor, h.APRef, h.Description, h.InvDate,
            h.CMCo, h.CMAcct, h.PrePaidDate, h.PrePaidChk, h.PrePaidSeq, h.PayOverrideYN, h.PayName,
            h.PayAddInfo, h.PayAddress, h.PayCity, h.PayState, h.PayZip, h.AddressSeq,h.PayCountry
        from bAPTH h
        join bHQBC b on b.Co = h.APCo and b.Mth = h.Mth and b.BatchId = h.BatchId
        where h.APCo = @co and h.CMCo = isnull(@sendcmco, h.CMCo) and h.CMAcct = isnull(@sendcmacct, h.CMAcct)
            and h.PrePaidYN = 'Y' and h.PrePaidMth = @mth and h.PrePaidProcYN = 'N'
            and h.InUseMth is null and h.InUseBatchId is null and h.InPayControl = 'N'
            and b.CreatedBy = isnull(@postedby, b.CreatedBy)
		
        open bcPrepaid
	
     	select @openPrepaid = 1
    
      	Prepaid_loop:     -- get next prepaid transaction
            fetch next from bcPrepaid into @expmth, @aptrans, @vendorgroup, @vendor, @apref, @description,
                @invdate, @cmco, @cmacct, @prepaiddate, @prepaidchk, @prepaidseq, @payoverrideyn, @payname,
                @payaddinfo, @payaddress, @paycity, @paystate, @payzip, @addressseq,@paycountry
    		
     	 	if @@fetch_status <> 0 goto Prepaid_end
    		
            -- check for open transaction detail
            if not exists(select * from bAPTD where APCo = @co and Mth = @expmth
                        and APTrans = @aptrans and Status = 1) goto Prepaid_loop    -- nothing open
    		
    	    -- get 1st non null Supplier on this transaction - will be used for payment information
            select @supplier = null
            select @supplier = Supplier
            from bAPTL
            where APCo = @co and Mth = @expmth and APTrans = @aptrans and Supplier is not null
    
            -- convert Prepaid Check # to CM Reference - should not be needed Prepaid Chk and CM Ref are same datatype
     		-- select @cmref = space(10-datalength(convert(varchar(10),@prepaidchk))) + convert(varchar(10),@prepaidchk)
    
            -- if Prepaid Check Sequence is null, change it to 0
            if @prepaidseq is null select @prepaidseq = 0
    
            -- get Vendor info
            select @name = null, @addnlinfo = null, @address = null, @city = null, @state = null, @zip = null, @country = null
            select @name = Name, @addnlinfo = AddnlInfo, @address = Address, @city = City, @state = State,
			@zip = Zip, @country = Country
            from bAPVM
            where VendorGroup = @vendorgroup and Vendor = @vendor
            if @@rowcount = 0
                begin
                select @msg = 'Missing Vendor ' + isnull(convert(varchar(12),@vendor), ''), @rcode = 1  --#23061
                goto bspexit
                end
    
    	
            -- set payment information
            if @payoverrideyn = 'Y'
                begin
                select @name = @payname, @addnlinfo = @payaddinfo, @address = @payaddress,
    				 @city = @paycity, @state = @paystate, @zip = @payzip, @country=@paycountry
                end
    	   if @payoverrideyn = 'N' and @addressseq is not null -- #18037 use address from bAPAA additional addresses
    		begin
    		select @addnlinfo = Address2, @address = Address,@city = City, @state = State, @zip = Zip, @country=Country 
    		from bAPAA with (nolock) where VendorGroup= @vendorgroup and Vendor = @vendor and AddressSeq=@addressseq
     		if @@rowcount = 0
                begin
                select @msg = 'Missing Address Seq: ' + isnull(convert(varchar(3),@addressseq), ''), @rcode = 1  --#23061
                goto bspexit
                end
    		end
    
    
            -- see if Check # already in current Payment batch
            select @pbseq = BatchSeq, @pbvendor = Vendor, @pbname = Name, @pbaddinfo = AddnlInfo, @pbaddress = Address,
                @pbpaiddate = PaidDate, @pbamount = Amount, @pbsupplier = Supplier
            from bAPPB
            where Co = @co and Mth = @mth and BatchId = @batchid and CMCo = @cmco and CMAcct = @cmacct
                and PayMethod = 'C' and CMRef = @prepaidchk and CMRefSeq = @prepaidseq
            if @@rowcount = 0
                begin
    
                -- add Payment Batch Header
                select @pbseq = isnull(max(BatchSeq),0) + 1
                from bAPPB where Co = @co and Mth = @mth and BatchId = @batchid
    
     		    insert bAPPB(Co, Mth, BatchId, BatchSeq, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq,
     			    ChkType, VendorGroup, Vendor, Name, AddnlInfo, Address, City, State, Zip, PaidDate,
     			    Amount, Supplier, VoidYN, VoidMemo, ReuseYN, Overflow,Country)
     		    values (@co, @mth, @batchid, @pbseq, @cmco, @cmacct, 'C', @prepaidchk, @prepaidseq, null,
     			    'P', @vendorgroup, @vendor, @name, @addnlinfo, @address, @city, @state, @zip, @prepaiddate,
     			    0, @supplier, 'N', null, 'N', 'N',@country)
    
                select @count = @count + 1      -- accum # of prepaid checks added to batch
                end
    
            else
                begin
                -- make sure prepaid information matches existing Payment Batch Header
                if @pbvendor <> @vendor or @pbname <> @name or @pbaddinfo <> @addnlinfo
                    or @pbaddress <> @address or @pbpaiddate <> @prepaiddate
                    or (@pbsupplier is null and @supplier is not null) or (@pbsupplier is not null and @supplier is null)
                    or (@pbsupplier is not null and @supplier is not null and @pbsupplier <> @supplier)
                    begin
                    select @msg = 'Unable to process Trans#: ' +  isnull(convert(varchar(12),@aptrans), '') + ' posted in '
                        + isnull(convert(varchar(12),@expmth), '') + char(13) + 'A check already exists in your Payment Batch'
                        + ' with information that differs from the prepaid transaction.', @rcode = 1  --#23061
                    goto bspexit
                    end
                end
    
            -- add prepaid transaction to existing batch entry - trigger locks bAPTH
            insert bAPTB (Co, Mth, BatchId, BatchSeq, ExpMth, APTrans, APRef, Description, InvDate, Gross,
                Retainage, PrevPaid, PrevDisc, Balance, DiscTaken)
            values (@co, @mth, @batchid, @pbseq, @expmth, @aptrans, @apref, @description, @invdate, 0, 0, 0, 0, 0, 0)
    
            -- create a cursor to process transaction lines and detail
     		declare bcDetail cursor for
     		select APLine, APSeq, Status, Amount, PayType, DiscTaken, PayCategory
            from bAPTD
     		where APCo = @co and Mth = @expmth and APTrans = @aptrans
    
     		open bcDetail
     		select @openDetail = 1
    
     		Detail_loop:     -- loop through all transaction detail
                fetch next from bcDetail into @apline, @apseq, @status, @amount, @paytype, @disctaken, @paycategory
    
     		    if @@fetch_status <> 0 goto Detail_end
    
                -- if 'open', add to Payment Batch Detail
                if @status = 1
     			    begin
     				insert bAPDB(Co, Mth, BatchId, BatchSeq, ExpMth, APTrans, APLine, APSeq,
                        PayType, Amount, DiscTaken, PayCategory)
     				values (@co, @mth, @batchid, @pbseq, @expmth, @aptrans, @apline, @apseq,
                        @paytype, @amount, @disctaken, @paycategory)
     				end
    
                -- accumulate amounts to update Payment Batch Transaction
                select @retainage = 0, @prevpaid = 0, @prevdisc = 0, @balance = 0, @disc = 0
    
                -- accumulate 'retaingage' on hold
                if @status = 2 /*and @paytype = @retpaytype*/
    			and ((@paycategory is null and @paytype = @retpaytype)
    				 or (@paycategory is not null and @paytype = (select RetPayType from bAPPC with (nolock)
    						where APCo=@co and PayCategory=@paycategory)))
    			begin
    				select @retainage = @amount
    			end
    
                -- accumulate 'previously paid' or cleared amounts
                if @status > 2 select @prevpaid = @amount, @prevdisc = @disctaken
    
                -- accumulate 'balance' on hold
     			if @status = 2 /*and @paytype <> @retpaytype*/
    			and ((@paycategory is null and @paytype <> @retpaytype) --#25051 added @paycategory 
    				 or (@paycategory is not null and @paytype <> (select RetPayType from bAPPC with (nolock)
    					 where APCo=@co and PayCategory=@paycategory)))
    			begin
    				select @balance = @amount
    			end
    
                -- accumulate 'discount taken'
                if @status = 1 select @disc = @disctaken
    
                -- update transaction totals to Payment Batch Transaction - trigger will update Amount in bAPPB
     			update bAPTB set Gross = Gross + @amount, Retainage = Retainage + @retainage,
                    PrevPaid = PrevPaid + @prevpaid, PrevDisc = PrevDisc + @prevdisc,
     				Balance = Balance + @balance, DiscTaken = DiscTaken + @disc
                where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @pbseq
                    and ExpMth = @expmth and APTrans = @aptrans
     			if @@rowcount <> 1
                    begin
                    select @msg = 'Unable to update Payment Batch Transaction.', @rcode = 1
                    goto bspexit
                    end
    
                goto Detail_loop
    
            Detail_end:     -- finished with this transaction
                close bcDetail
                deallocate bcDetail
                select @openDetail = 0
                goto Prepaid_loop   -- next prepaid transaction
    
        Prepaid_end:        -- finished with prepaid transactions
            close bcPrepaid
            deallocate bcPrepaid
            select @openPrepaid = 0
        end
    
    bspexit:
        if @openDetail = 1
            begin
            close bcDetail
            deallocate bcDetail
            end
        if @openPrepaid = 1
            begin
            close bcPrepaid
            deallocate bcPrepaid
            end
    
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPBPrePaid] TO [public]
GO
