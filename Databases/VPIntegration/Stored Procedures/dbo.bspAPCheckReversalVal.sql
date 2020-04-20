SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPCheckReversalVal    Script Date: 8/28/99 9:33:57 AM ******/
    CREATE         proc [dbo].[bspAPCheckReversalVal]
     /***********************************************************
      * CREATED BY: GG 04/27/99
      * MODIFIED By : MV 7/3/02 - #16368 allow check rev in prior open month
      *			   MV 09/18/02 - #16368 don't allow check rev in same month as batch month
      *			   MV 10/18/02 - 18878 quoted identifier cleanup 
      *			   MV 01/20/03 - #19851 validate PO/SL header not in use
      *			   MV 10/21/03 - #22160 rej 1 fix - restrict select from APPH to paymethod 'C'
      *			   MV 11/26/03 - #23061 isnull wrap
      *			   MV 01/05/04 - #23254 validate for unprocessed prepaids in bAPTH 
      *				GP 6/28/10 - #135813 change bSL to varchar(30)
      *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
      * USAGE:
      * Called to validate an AP check entered for reversal.  Must be
      * validated within an AP expense batch.
      *
      *  INPUT PARAMETERS
      *   @apco             AP Company
      *   @batchmth         Batch Month - open month for new entries
      *   @batchid          BatchId
      *   @cmco             CM Company
      *   @cmacct           CM Account - payment was made on this account
      *   @cmref            CM Reference - check number to be reversed
      *   @cmrefseq         CM Reference Seq # of payment to be reversed
      *
      * OUTPUT PARAMETERS
      *   @msg      error message if error occurs
      *
      * RETURN VALUE
      *   0         success
      *   1         failure
      ************************************************************/
        (@apco bCompany, @batchmth bMonth, @batchid bBatchID, @cmco bCompany, @cmacct bCMAcct,
     	@cmref bCMRef, @cmrefseq tinyint, @msg varchar(255) output)
    as
    
    declare @rcode int, @paidmth bMonth, @paidamt bDollar, @voidyn bYN, @inusemth bMonth,
    @inusebatchid bBatchID, @stmtdate bDate, @lastmthsubclsd bMonth, @detailamt bDollar,
    @po varchar(30), @sl varchar(30),@source bSource, @apthco bCompany,@apthmth bMonth, @aptrans int
    
    set nocount on
    
    select @rcode = 0
    
    -- make sure original check exists in AP Payment History
    select @paidmth = PaidMth, @paidamt = Amount, @voidyn = VoidYN, @inusemth = InUseMth, @inusebatchid = InUseBatchId
    from bAPPH
    where APCo = @apco and CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and
   	 CMRefSeq = @cmrefseq and PayMethod = 'C'
    if @@rowcount = 0
        begin
        select @msg = 'This check and sequence number does not exist in AP Payment History.', @rcode = 1
        goto bspexit
        end
    if @voidyn = 'Y'
        begin
        select @msg = 'This check has been voided.', @rcode = 1
        goto bspexit
        end
    if @inusemth = @batchmth and @inusebatchid = @batchid
        begin
        select @msg = 'You have already added this check to your current batch.', @rcode = 1
        goto bspexit
        end
    if @inusemth is not null
        begin
        select @msg = 'This check is currently in use by another batch - Mth: ' +  --#23061
            isnull(convert(varchar(2),datepart(month, @inusemth)), '') + '/' +
     		      isnull(substring(convert(varchar(4),datepart(year, @inusemth)),3,4), '') +
     			' Batch # ' + isnull(convert(varchar(6),@inusebatchid), ''), @rcode = 1
        goto bspexit
        end
    
    -- make sure check has not been cleared in CM Detail
    select @stmtdate = StmtDate
    from bCMDT
    where CMCo = @cmco and Mth = @paidmth and CMAcct = @cmacct and CMTransType = 1
        and CMRef = @cmref and CMRefSeq = @cmrefseq
    if @@rowcount = 1 and @stmtdate is not null
        begin
        select @msg = 'This check has already been cleared in CM.', @rcode = 1
        goto bspexit
        end
    
    -- make sure paid month is closed	- #16368 allow check rev in prior open month
    /*select @lastmthsubclsd = LastMthSubClsd
    from bGLCO g
    join bAPCO a on g.GLCo = a.GLCo
    where a.APCo = @apco
    if @@rowcount = 0
        begin
        select @msg = 'Missing AP and/or GL Company!', @rcode = 1
        goto bspexit
        end
    if @paidmth > @lastmthsubclsd
        begin
        select @msg = 'The check was paid in a month that is still open. ' +
            'Use the AP Payment Processing progam to void.', @rcode = 1
        goto bspexit
        end*/
    
    /*Issue 16368 - allow check rev in prior open month. Batch month must be
    	later than paidmth for the reversing entry.*/
    if @paidmth >= @batchmth
        begin
        select @msg = 'Paid Month: ' + isnull(convert(varchar(8),@paidmth,1), '') + ' must be prior to Batch Month: ' +
    		isnull(convert(varchar(8),@batchmth,1), ''), @rcode = 1  --#23061
        goto bspexit
        end
    
    -- make sure this check hasn't already been reversed
    if exists(select * from bAPPH where APCo = @apco and CMCo = @cmco and CMAcct = @cmacct
        and PayMethod = 'C' and CMRef = @cmref and CMRefSeq > @cmrefseq)
        begin
        select @msg = 'AP Payment History indicates that this check has already been reversed.', @rcode = 1
        goto bspexit
        end
    if exists(select * from bCMDT where CMCo = @cmco and CMAcct = @cmacct
        and CMTransType = 1 and CMRef = @cmref and CMRefSeq > @cmrefseq)
        begin
        select @msg = 'CM Detail indicates that this check has already been reversed.', @rcode = 1
        goto bspexit
        end
    
    -- make sure no entries exist for this check # in an Expense Batch
    select @inusemth = Mth, @inusebatchid = BatchId
    from bAPHB
    where Co = @apco and CMCo = @cmco and CMAcct = @cmacct and PrePaidYN = 'Y' and PrePaidChk = @cmref
    if @@rowcount <> 0
        begin
        select @msg = 'This check # is used as a Prepaid in batch - Mth: ' +
         isnull(convert(varchar(2),datepart(month, @inusemth)), '') + '/' +	--#23061
     		      isnull(substring(convert(varchar(4),datepart(year, @inusemth)),3,4), '') +
     			' Batch # ' + isnull(convert(varchar(6),@inusebatchid), ''), @rcode = 1
        goto bspexit
        end
   
   /* #23254 - validate CMRef isn't in an unprocessed prepaid in bAPTH */
   	select @apthco=APCo,@apthmth=Mth, @aptrans=APTrans
   		from bAPTH where PayMethod='C' and CMCo=@cmco and CMAcct=@cmacct and PrePaidChk=@cmref
   			and PrePaidSeq = (@cmrefseq + 1) and PrePaidYN='Y' and PrePaidProcYN='N'
   	if @@rowcount <> 0 
   		begin
   		select @msg='This check # is in an unprocessed prepaid transaction for Co: ' + isnull(convert(varchar(3),@apco), '')
    		+ ' Month: ' + isnull(convert(varchar(8),@apthmth,1), '')	--#23061
    		+ ' Trans#: ' + isnull(convert(varchar(10),@aptrans), ''),  @rcode=1
     		goto bspexit
     		end
    
    -- make sure no entries exist for this check # in a Payment Batch
    select @inusemth = Mth, @inusebatchid = BatchId
    from bAPPB
    where Co = @apco and CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'C' and CMRef = @cmref
    if @@rowcount <> 0
        begin
        select @msg = 'This check # exists in batch - Mth: ' +
         isnull(convert(varchar(2),datepart(month, @inusemth)), '') + '/' +	--#23061
     		      isnull(substring(convert(varchar(4),datepart(year, @inusemth)),3,4), '') +
     			' Batch # ' + isnull(convert(varchar(6),@inusebatchid), ''), @rcode = 1
        goto bspexit
        end
    
    -- make sure transactions still exist for this check
    select @detailamt = isnull(sum(Amount - DiscTaken),0)
    from bAPTD
    where APCo = @apco and CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'C'
        and CMRef = @cmref and CMRefSeq = @cmrefseq
    if @paidamt <> @detailamt
        begin
        select @msg = 'AP Payment History and Transaction Detail do not match.  Paid transactions ' +
            'may have been purged.', @rcode = 1
        goto bspexit
        end
    
    -- make sure PO or SL header is not locked 	-#19851
    select @po=PO, @sl=SL from APTL l join APTH h on l.APCo=h.APCo and l.Mth=h.Mth and l.APTrans=h.APTrans 
    		join APPD d on h.APCo=d.APCo and h.Mth=d.Mth and h.APTrans=d.APTrans and h.APRef=d.APRef
    		where d.APCo=@apco and d.CMCo=@cmco and d.CMRef=@cmref
    if @po is not null
    begin
    select @inusemth=InUseMth, @inusebatchid=InUseBatchId from POHD where POCo=@apco and PO=@po
    if @batchmth <> isnull(@inusemth,@batchmth) or @batchid <> isnull(@inusebatchid,@batchid)
      begin
    	select @source = Source from bHQBC where Co=@apco and Mth=@inusemth and BatchId=@inusebatchid
    	select @msg = ' PO: ' + isnull(@po, '') + ' is already in use by Batch: '
    			+ isnull(convert(varchar(6),@inusebatchid), '') + ' in month '  --#23061
    			+ isnull(convert(varchar(8),@inusemth,1), '')	
    		+ ' Source: ' + isnull(@source,''), @rcode = 1
         goto bspexit	
      end
    end
    
    if @sl is not null
    begin
    select @inusemth=InUseMth, @inusebatchid=InUseBatchId from SLHD where SLCo=@apco and SL=@sl
    if @batchmth <> isnull(@inusemth,@batchmth) or @batchid <> isnull(@inusebatchid,@batchid)
      begin	
    	select @source = Source from bHQBC where Co=@apco and Mth=@inusemth and BatchId=@inusebatchid 	 			
    	select @msg = ' Subcontract: ' + isnull(@sl,'') + ' is already in use by Batch: '	--#23061
    			+ isnull(convert(varchar(6),isnull(@inusebatchid,'')), '') + ' in Month: '
    		+ isnull(convert(varchar(8),isnull(@inusemth,''),1), '')	
    		+ ' Source: ' + isnull(@source,''), @rcode = 1
        goto bspexit	
     end
    end
    
    
    bspexit:
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPCheckReversalVal] TO [public]
GO
