SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPEFTProcess    Script Date: 8/28/99 9:33:58 AM ******/
      CREATE         proc [dbo].[bspAPEFTProcess]
      /***********************************************************
       * CREATED BY	: SE 10/22/97
       * MODIFIED BY	: kb 1/7/99
       *                kb 12/12/00 - issue #10940
       *                kb 1/22/2 -issue #15845
       *                kb 3/17/2 -issue #16663
       *				   EN 3/20/02 - issue 12974 Added check for null CMRef to cursor bcAPPB and fixed to not check for CMRef on reload.
     								Also changed cursor to read VendorGroup and Vendor rather than reading them in a separate select stmt.
       *                 kb 4/11/2
       *                 kb 4/29/2 - issue #15845
       *                 kb 5/15/2 - issue #15845
       *                 kb 6/4/2 - issue #17566
   	*              	  kb 10/28/2 - issue #18878 - fix double quotes
       *				  mv 04/03/03 - #20537 - return the err msg to user when something goes wrong.
       *				  MV 02/19/04 - #18769 - pay category / #23061 isnull wrap
       *				  DANF 03/15/05 - #27294 - Remove scrollable cursor.
		*					MV 09/04/08	- #127166 - Country based vendor EFT info validation
	   *					MV 03/02/09 - #127222 - validate EFT info for CA
       * USED IN
       *   APEFT
       * USAGE:
       * used to validate CMRef for Eft's and assign EFTSeq numbers to payments in APPB
       * This will return STDBTK_SUCCES if OK, otherwise STDBTK_ERROR
       * INPUT PARAMETERS
       *   APCo     APCompan of batch
       *   Month    Batch Month
       *   BatchId  BatchId of APPB checks you want to assign check numbers to
       *   Reload   Weather or not we are reloading.
       *   CMCo     CM Company
       *   CMAcct   CMAcct to process
       *   CMREF    Reference for EFT
       *   PaidDate PaidDate to be plugged into APPB
       *
       * OUTPUT PARAMETERS 
       *   @msg     If error occurs, Error message goes here
       *
       * RETURN VALUE
       *   0         success
       *   1         Failure  '
       *****************************************************/
   
          (@apco bCompany, @month bMonth, @batchid bBatchID, @reload bYN, @cmco bCompany,
           @cmacct bCMAcct, @cmref bCMRef, @paiddate bDate,@msg varchar(100) output )
      as
   
      set nocount on
   
      declare @rcode int
      declare @opencursorAPPB tinyint, @eftseq int, @batchseq int, @vendorgroup bGroup,
        @routingid varchar(10), @vendor bVendor, @bankacct varchar(20), @expmth bMonth,
        @aptrans bTrans, @apline int, @retainage bDollar, @retpaytype tinyint,
        @prevpaid bDollar, @batchprevpaid bDollar, @prevdisc bDollar,
        @batchprevdisc bDollar, @balance bDollar, @batchbalance bDollar,
        @disctaken bDollar, @otherbalance bDollar, @supplier bVendor,
		@hqcodefaultcountry varchar(2)
   
      select @retpaytype = RetPayType from bAPCO where @apco = APCo
   
      select @eftseq=0
      /* if we are reprinting EFTs  then remove all RefSeqs for the EFT we are processing*/
      if @reload='Y'
          update bAPPB set CMRef=null, EFTSeq=null, PaidDate=null where Co=@apco and Mth=@month and BatchId=@batchid and
          		CMCo=@cmco and CMAcct=@cmacct and PayMethod='E'
   
      /*
       * now validate to make sure that the EFT we are using for a CMREF is unique
       */
   
      if exists(select * from bAPPB where PayMethod='E' and CMCo=@cmco and CMAcct=@cmacct
                and CMRef=@cmref)
         begin
           select @msg='Entries in the payment detail batch already exist for this EFT Reference!', @rcode=1
           goto bspexit
         end
   
      if exists(select * from bAPPD where PayMethod='E' and CMCo=@cmco and CMAcct=@cmacct
                and CMRef=@cmref)
         begin
           select @msg='Entries in payment detail already exist for this EFT Reference!', @rcode=1
           goto bspexit
         end
      if exists(select * from bCMDT where CMTransType=4 and CMCo=@cmco and CMAcct=@cmacct
                and CMRef=@cmref)
         begin
           select @msg='Entries in CM payment detail already exist for this EFT Reference!', @rcode=1
           goto bspexit
         end
   
		-- get HQCO DefaultCountry for Country based validation of vendor EFT info.
		select @hqcodefaultcountry= DefaultCountry from bHQCO where HQCo=@apco
   
         declare bcAPPB cursor local fast_forward for select BatchSeq, VendorGroup, Vendor,Supplier
          from bAPPB where Co = @apco and Mth = @month and BatchId = @batchid
          	and CMCo=@cmco and CMAcct=@cmacct and PayMethod='E' and CMRef is null --issue 12974 only look for entries with null CMRef
          	order by Vendor, BatchSeq
   
   
      /* open cursor */
      open bcAPPB
   
   /* set open cursor flag to true */
      select @opencursorAPPB = 1, @rcode=0, @eftseq=0
   
      /* get first row */
      fetch next from bcAPPB into @batchseq, @vendorgroup, @vendor, @supplier
      /* loop through all rows */
      while (@@fetch_status = 0)
       begin
        /*do not assign the CMRef if there are no transactions to be paid on this seq - kb 1/7/99*/
        if not exists(select * from APTB where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq= @batchseq)
        	goto GetNext
        /* assign same CMREF and Next EftSeq to line*/

		-- validate vendor EFT based on country
		if isnull(@hqcodefaultcountry,'US') in ('US', 'CA')
		begin
		select @routingid = RoutingId, @bankacct = BankAcct from bAPVM where VendorGroup = @vendorgroup
          and Vendor = @vendor
        if @routingid is null or @bankacct is null
          begin
           select @msg='Vendor Routing Id or Bank Acct infomation is missing. Cannot proceed with the download', @rcode=1
           goto bspexit
          end
		end

		if @hqcodefaultcountry = 'AU' -- Australia
		begin
		select @routingid = AUVendorBSB, @bankacct = AUVendorAccountNumber from bAPVM where VendorGroup = @vendorgroup
          and Vendor = @vendor
        if @routingid is null or @bankacct is null 
          begin
           select @msg='Vendor BSB Number or Account Number is missing. Cannot proceed with the download', @rcode=1
           goto bspexit
          end
		end
        
   
      --update APTB fields Retainage,PrevPaid,PrevDisc,Balance,DiscTaken
      select @expmth = min(ExpMth) from bAPTB where Co = @apco and Mth = @month
        and BatchId = @batchid and BatchSeq = @batchseq
      while @expmth is not null
          begin
          select @aptrans = min(APTrans) from bAPTB where Co = @apco and Mth = @month
            and BatchId = @batchid and BatchSeq = @batchseq and ExpMth = @expmth
          while @aptrans is not null
              begin
           select @balance = isnull((select sum(Amount) from bAPTD where APCo = @apco
           and Mth = @expmth and APTrans = @aptrans and Status <3) ,0)
   
           select @batchbalance = isnull((select sum(Amount) from bAPDB where Co = @apco
            and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq
            and ExpMth = @expmth and APTrans = @aptrans),0)
   
           select @balance = @balance - @batchbalance
   
           select @retainage = sum(d.Amount) from bAPTD d with (nolock) where d.APCo = @apco
             	and d.Mth = @expmth and d.APTrans = @aptrans and d.Status = 2
   			and ((d.PayCategory is null and d.PayType = @retpaytype)
   				 or (d.PayCategory is not null and d.PayType = (select c.RetPayType 
   						from bAPPC c with (nolock) where c.APCo=@apco and c.PayCategory=d.PayCategory)))
             /*and PayType = @retpaytype and Status = 2*/
           select @prevpaid = sum(Amount) - sum(DiscTaken),
             @prevdisc = sum(DiscTaken)
             from bAPTD where APCo = @apco and Mth = @expmth
             and APTrans = @aptrans and Status > 2
   /*              select @balance = sum(Amount) from bAPTD where APCo = @apco
                   and Mth = @expmth and APTrans = @aptrans and Status = 2
                   and PayType <> @retpaytype*/
           select @batchprevdisc = sum(DiscTaken),
             @batchprevpaid = sum(Amount) - sum(DiscTaken)
             from bAPDB where Co = @apco and ExpMth = @expmth and APTrans = @aptrans
             and BatchId = @batchid and Mth = @month and BatchSeq < @batchseq
   /*              select @batchbalance = sum(Amount) from bAPDB where Co = @apco
                   and ExpMth = @expmth and APTrans = @aptrans and BatchId = @batchid*/
   --                and Mth = @month and BatchSeq > @batchseq
    			/*this will get the balance not counting this transaction*/
   /*  			select @otherbalance = sum(Amount)-isnull(@batchbalance,0)
                   from bAPTD  d
   			   join bAPTL l on l.APCo = d.APCo and l.Mth = d.Mth
   				and l.APTrans = d.APTrans
   				and l.APLine = d.APLine where d.APCo = @apco
       		   and d.Mth = @expmth and d.APTrans = @aptrans and Status =1
                  and not exists(select * from APDB b where b.Co = d.APCo
                  and b.ExpMth = d.Mth and d.APTrans = b.APTrans and
                  d.APLine = b.APLine and d.APSeq = b.APSeq and
                  b.Co = @apco and b.Mth = @month and b.BatchId = @batchid
                  and b.ExpMth = @expmth and b.APTrans = @aptrans)*/
                  /*and ((isnull(d.Supplier,0) <> isnull(@supplier,0))
   			   or (isnull(JCCo,0) <> isnull(@jcco,0))
   			   or (isnull(Job,0) <> isnull(@job,0)))*/
   
                /*select @otherbalance = sum(t.Amount)-isnull(@batchbalance,0)
                  from bAPTD t join bAPDB d on
                  d.Co = t.APCo and t.Mth = d.ExpMth and d.APTrans = t.APTrans
                  and d.APLine = t.APLine and d.APSeq = t.APSeq
                  where APCo = @apco and t.Mth = @expmth and t.APTrans = @aptrans
                  and Status =1 and d.Mth = @month and BatchId = @batchid
                  and BatchSeq <> @batchseq*/
             select @disctaken = sum(DiscTaken) from bAPDB where Co = @apco
                   and ExpMth = @expmth and APTrans = @aptrans and Mth = @month
                   and BatchId = @batchid and BatchSeq = @batchseq
                 select @disctaken = isnull(@disctaken,0), @retainage = isnull(@retainage,0),
                   @prevpaid = isnull(@prevpaid,0) + isnull(@batchprevpaid,0),
                   @prevdisc = isnull(@prevdisc,0) + isnull(@batchprevdisc,0)/*,
                   @balance = isnull(@balance,0) + isnull(@batchbalance,0)*/
                 select @balance = @balance - isnull(@batchprevpaid,0) - isnull(@batchprevdisc,0)
   
                 update bAPTB set Retainage = @retainage, PrevPaid = @prevpaid,
                   PrevDisc = @prevdisc,
    			   Balance = @balance - @retainage, --/*+isnull(@otherbalance,0)*/-/*4/29/2*/
                  --isnull(@batchprevpaid,0) - isnull(@batchprevdisc,0),
     			  DiscTaken = @disctaken
                   from bAPTB
     where Co = @apco and Mth = @month and BatchId = @batchid and
                   BatchSeq = @batchseq and ExpMth = @expmth and APTrans = @aptrans
              select @aptrans = min(APTrans) from bAPTB where Co = @apco and Mth = @month
                and BatchId = @batchid and BatchSeq = @batchseq and ExpMth = @expmth
                and APTrans > @aptrans
              end
          select @expmth = min(ExpMth) from bAPTB where Co = @apco and Mth = @month
            and BatchId = @batchid and BatchSeq = @batchseq and ExpMth > @expmth
          end
   
        update bAPPB set CMRef=@cmref, CMRefSeq=0, EFTSeq=@eftseq, PaidDate=@paiddate
               where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq
   
        select @eftseq=@eftseq+1
        GetNext:
        fetch next from bcAPPB into @batchseq, @vendorgroup, @vendor, @supplier
   
       end
   
       if @eftseq=0
           select @msg = 'No EFT''s were processed.', @rcode=1
       else
          begin
           select @msg = isnull(convert(varchar(15),@eftseq),'') + ' EFT(s) processed.', @rcode=0
          end
   
   
      bspexit:
        /* reset the ending check to what we ended up using*/
        if @opencursorAPPB=1
           begin
             close bcAPPB
             deallocate bcAPPB
             select @opencursorAPPB=0
           end
   
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPEFTProcess] TO [public]
GO
