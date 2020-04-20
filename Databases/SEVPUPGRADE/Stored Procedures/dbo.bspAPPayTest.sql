SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPayTest    Script Date: 8/28/99 9:34:03 AM ******/
   CREATE  Procedure [dbo].[bspAPPayTest]
   /********************************************
    *  Created: GG 5/27/99
    *              kb 10/28/2 - issue #18878 - fix double quotes
    *		ES 03/12/04 - #23061 isnull wrapping
    *
    *  Used to test consistency of AP Payment History,
    *  AP Transaction Detail, and CM Transaction Detail
    *
    **********************************************/
   as
   
   declare @openAPPH tinyint, @apco bCompany, @cmco bCompany, @cmacct bCMAcct, @paymethod char(1), @cmref bCMRef,
   @cmrefseq tinyint, @eftseq smallint, @paidmth bMonth, @paiddate bDate, @netamt bDollar, @voidyn bYN,
   @cmtrans bTrans, @cmamt bDollar, @cmvoid bYN, @numrows int, @detailamt bDollar,
   @openAPPD tinyint, @expmth bMonth, @aptrans bTrans, @openAPTD tinyint, @amt bDollar, @disc bDollar,
   @status tinyint, @tdpaidmth bMonth, @tdpaiddate bDate, @tdcmco bCompany, @tdcmacct bCMAcct,
   @tdpaymethod char(1), @tdcmref bCMRef, @tdcmrefseq tinyint, @tdamt bDollar, @pdamt bDollar, @cnt int,
   @cmco1 bCompany, @cmacct1 bCMAcct, @cmref1 bCMRef, @cmrefseq1 tinyint
   
   set nocount on
   
   select @cnt = 0     -- # of inconsistent payments found
   
   select 'Searching for missing AP Payment Headers...(bAPPD entries exist w/o bAPPH)'
   
   select distinct d.APCo, d.CMCo, d.CMAcct, d.PayMethod, d.CMRef, d.CMRefSeq
   from bAPPD d
   left join bAPPH h on d.APCo = h.APCo and d.CMCo = h.CMCo and d.CMAcct = h.CMAcct
   and d.PayMethod = h.PayMethod and d.CMRef = h.CMRef and d.CMRefSeq = h.CMRefSeq and d.EFTSeq = h.EFTSeq
   where h.VoidYN is null
   if @@rowcount = 0 select 'None found.'
   
   -- create a cursor to check each Payment in AP Payment History
   declare bcAPPH cursor for
   select APCo, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, PaidMth, PaidDate, Amount, VoidYN
   from bAPPH
   
   open bcAPPH
   select @openAPPH = 1
   
   APPH_loop:      -- loop through each Payment Header
       fetch next from bcAPPH into @apco, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, @eftseq,
           @paidmth, @paiddate, @netamt, @voidyn
   
       if @@fetch_status <> 0 goto APPH_end
   
       -- check CM Transactions
       select @cmtrans = CMTrans, @cmamt = Amount, @cmvoid = Void
       from bCMDT
       where CMCo = @cmco and Mth = @paidmth and CMAcct = @cmacct
           and CMTransType = case @paymethod when 'C' then 1 else 4 end
           and CMRef = @cmref and CMRefSeq = @cmrefseq
       select @numrows = @@rowcount
       if @numrows = 0
           begin
           select @cnt = @cnt + 1
           select isnull(convert(varchar(6),@cnt), '') + '. Payment (APCo:' 
   		+ isnull(convert(varchar(3),@apco), '') + ' CMCo:' + convert(varchar(3),@cmco)
               	+ ' CMAcct:' + isnull(convert(varchar(6),@cmacct), '') + ' CMRef:' + isnull(@cmref, '')
   		+ ' CMRefSeq:' + isnull(convert(varchar(3),@cmrefseq), '') + ') does not exist in bCMDT.'  --#23061
           goto APPH_loop
           end
       if @numrows > 1
           begin
           select @cnt = @cnt + 1
           select isnull(convert(varchar(6),@cnt), '') + '. Payment (APCo:' 
   		+ isnull(convert(varchar(3),@apco), '') + ' CMCo:' + isnull(convert(varchar(3),@cmco), '')
               	+ ' CMAcct:' + isnull(convert(varchar(6),@cmacct), '') + ' CMRef:' + isnull(@cmref, '') 
   		+ ' CMRefSeq:' + isnull(convert(varchar(3),@cmrefseq), '') + ') has more than one entry in bCMDT.'
           goto APPH_loop
           end
       if @netamt <> -(@cmamt)
           begin
           select @cnt = @cnt + 1
           select isnull(convert(varchar(6),@cnt), '') + '. Amount of Payment (APCo:' 
   		+ isnull(convert(varchar(3),@apco), '') + ' CMCo:' + isnull(convert(varchar(3),@cmco), '')
               	+ ' CMAcct:' + isnull(convert(varchar(6),@cmacct), '') + ' CMRef:' + isnull(@cmref, '')
   		+ ' CMRefSeq:' + isnull(convert(varchar(3),@cmrefseq), '') + ') does not match the amount in bCMDT.'  --#23061
               select '===> bAPPH:' + isnull(convert(varchar(12),@netamt), '') + ' bCMDT:' + isnull(convert(varchar(12),-(@cmamt)), '')
           goto APPH_loop
           end
       if @voidyn <> @cmvoid
           begin
           select @cnt = @cnt + 1
           select isnull(convert(varchar(6),@cnt), '') + '. Void flag on Payment (APCo:' 
   		+ isnull(convert(varchar(3),@apco), '') + ' CMCo:' + isnull(convert(varchar(3),@cmco), '')
               	+ ' CMAcct:' + isnull(convert(varchar(6),@cmacct), '') + ' CMRef:' + isnull(@cmref, '') 
   		+ ' CMRefSeq:' + isnull(convert(varchar(3),@cmrefseq), '') + ') does not match bCMDT. (bAPPH Void: ' 
   		+ isnull(@voidyn, '') + ' bCMDT Void: ' + isnull(@cmvoid, '') + ')'  --#23061
           goto APPH_loop
           end
   
   
       if @voidyn = 'Y'
           begin
           -- Payment Detail should not exist for voided payments
           if exists(select * from bAPPD where APCo = @apco and CMCo = @cmco and CMAcct = @cmacct
                       and PayMethod = @paymethod and CMRef = @cmref and CMRefSeq = @cmrefseq and EFTSeq = @eftseq)
               begin
               select @cnt = @cnt + 1
               select isnull(convert(varchar(6),@cnt), '') + '. Voided payment (APCo:' 
   		+ isnull(convert(varchar(3),@apco), '') + ' CMCo:' + isnull(convert(varchar(3),@cmco), '')
                   + ' CMAcct:' + isnull(convert(varchar(6),@cmacct), '') + ' CMRef:' + isnull(@cmref, '') 
   		+ ' CMRefSeq:' + isnull(convert(varchar(3),@cmrefseq), '')
   		+ ') has entries in bAPPD.  They should be removed.'  --#23061
               end
           goto APPH_loop  -- finished with voided payment
           end
   
       -- sum of Payment Detail should match Header amount
       select @detailamt = sum(Gross - Retainage - PrevPaid - PrevDiscTaken - Balance - DiscTaken)
       from bAPPD
       where APCo = @apco and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @paymethod
           and CMRef = @cmref and CMRefSeq = @cmrefseq and EFTSeq = @eftseq
       if @@rowcount = 0
           begin
           select @cnt = @cnt + 1
           select isnull(convert(varchar(6),@cnt), '') + '. Payment (APCo:' + isnull(convert(varchar(3),@apco), '')
   	 	+ ' CMCo:' + isnull(convert(varchar(3),@cmco), '') + ' CMAcct:'  
   		+ isnull(convert(varchar(6),@cmacct), '') + ' CMRef:' + isnull(@cmref, '') 
   		+ ' CMRefSeq:' + isnull(convert(varchar(3),@cmrefseq), '') + ') has no entries in bAPPD.' --#23061
           goto APPH_loop
           end
       if @detailamt <> @netamt
           begin
           select @cnt = @cnt + 1
           select isnull(convert(varchar(6),@cnt), '') + '. Amount of Payment (APCo:' + isnull(convert(varchar(3),@apco), '') 
   		+ ' CMCo:' + isnull(convert(varchar(3),@cmco), '') + ' CMAcct:' + isnull(convert(varchar(6),@cmacct), '')
   		+ ' CMRef:' + isnull(@cmref, '') + ' CMRefSeq:' + isnull(convert(varchar(3),@cmrefseq), '')
   		+ ') does not equal the sum of its entries in bAPPD.'		--#23061
               select '===> bAPPH Amt:' + isnull(convert(varchar(12),@netamt), '') 
   			+ ' bAPPD Total:' + isnull(convert(varchar(12),@detailamt), '')  --#23061
           goto APPH_loop
           end
   
       -- create a cursor to process all paid transactions for the Payment Header
       declare bcAPPD cursor for
       select Mth, APTrans,
           'PaidAmt' = convert(numeric(12,2),(Gross - Retainage - PrevPaid - PrevDiscTaken - Balance - DiscTaken))
       from bAPPD
       where APCo = @apco and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @paymethod
           and CMRef = @cmref and CMRefSeq = @cmrefseq and EFTSeq = @eftseq
   
       open bcAPPD
       select @openAPPD = 1
   
       APPD_loop:      -- loop through each Payment Detail
           fetch next from bcAPPD into @expmth, @aptrans, @pdamt
   
           if @@fetch_status <> 0 goto APPD_end
   
           -- create a cursor to process all AP Transaction Detail entries
           declare bcAPTD cursor for
           select Amount, DiscTaken, Status, PaidMth, PaidDate, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq
           from bAPTD
           where APCo = @apco and Mth = @expmth and APTrans = @aptrans
   
           open bcAPTD
           select @openAPTD = 1
   
           select @tdamt = 0
   
           APTD_loop:      -- loop through all AP Transaction Detail
               fetch next from bcAPTD into @amt, @disc, @status, @tdpaidmth, @tdpaiddate, @tdcmco,
                   @tdcmacct, @tdpaymethod, @tdcmref, @tdcmrefseq
   
               if @@fetch_status <> 0 goto APTD_end
   
               -- amount paid on this payment
               if @status = 3 and @tdcmco = @cmco and @tdcmacct = @cmacct and @tdpaymethod = @paymethod
                   and @tdcmref = @cmref and @tdcmrefseq = @cmrefseq select @tdamt = @tdamt + @amt - @disc
   
               goto APTD_loop  -- next transaction detail
   
           APTD_end:
               close bcAPTD
               deallocate bcAPTD
               select @openAPTD = 0
   
               if @pdamt <> @tdamt
                   begin
                   select @cnt = @cnt + 1
                   select isnull(convert(varchar(6),@cnt), '') + '. Transaction detail amounts on Payment (APCo:' 
   		+ isnull(convert(varchar(3),@apco), '') + ' CMCo:' + isnull(convert(varchar(3),@cmco), '') 
   		+ ' CMAcct:' + isnull(convert(varchar(6),@cmacct), '') + ' CMRef:' + isnull(@cmref, '') +
                   ' CMRefSeq:' + isnull(convert(varchar(3),@cmrefseq), '') + ') are not equal.'
                   select '===> Exp Mth: ' + isnull(convert(varchar(12),@expmth,101), '') 
   		+ ' Trans#:' + isnull(convert(varchar(8),@aptrans), '') +  ' bAPTD Net:' 
   		+ isnull(convert(varchar(12),@tdamt), '') + ' bAPPD Net:' + isnull(convert(varchar(12),@pdamt), '')
                   goto APPD_loop
                   end
   
               -- check for transactions paid more than once
               select @cmco1 = CMCo, @cmacct1 = CMAcct, @cmref1 = CMRef, @cmrefseq1 = @cmrefseq
               from bAPPD
               where APCo = @apco and Mth = @expmth and APTrans = @aptrans
                   and not(CMCo = @cmco and CMAcct = @cmacct and PayMethod = @paymethod and CMRef = @cmref and CMRefSeq = @cmrefseq)
                   and (Gross - Retainage - PrevPaid - PrevDiscTaken - Balance - DiscTaken) = @pdamt
               if @@rowcount > 0
                   begin
                   select @cnt = @cnt + 1
                   select isnull(convert(varchar(6),@cnt), '') + '. Transaction may have been paid more than once (APCo:'
                   + isnull(convert(varchar(3),@apco), '') + ' CMCo:' + isnull(convert(varchar(3),@cmco), '') + ' CMAcct:'
                   + isnull(convert(varchar(6),@cmacct), '') + ' CMRef:' + isnull(@cmref, '') + ' CMRefSeq:' 
   		+ isnull(convert(varchar(3),@cmrefseq), '') + ')'   --#23061
                   select '===> Exp Mth: ' + isnull(convert(varchar(12),@expmth,101), '') + ' Trans#:' 
   		+ isnull(convert(varchar(8),@aptrans), '') +  ' CMCo#' + isnull(convert(varchar(3),@cmco1), '') 
   		+ ' CMAcct:' + isnull(convert(varchar(6),@cmacct1), '') + ' CMRef:' + isnull(@cmref1, '') 
   		+ ' CMRefSeq:' + isnull(convert(varchar(2),@cmrefseq1), '')
                   end
   
               goto APPD_loop
   
       APPD_end:   -- finished with transactions on this payment
           close bcAPPD
           deallocate bcAPPD
           select @openAPPD = 0
   
           goto APPH_loop
   
   APPH_end:   -- finished with Payment Headers
       close bcAPPH
       deallocate bcAPPH
       select @openAPPH = 0

GO
GRANT EXECUTE ON  [dbo].[bspAPPayTest] TO [public]
GO
