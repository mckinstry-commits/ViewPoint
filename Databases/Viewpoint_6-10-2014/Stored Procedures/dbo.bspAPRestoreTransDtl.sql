SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPRestoreTransDtl    Script Date: 8/28/99 9:34:04 AM ******/
   CREATE         procedure [dbo].[bspAPRestoreTransDtl]
   
   
   /***********************************************************
    * CREATED BY: EN 11/04/97
    * MODIFIED By : EN 3/31/99
    *               EN 5/9/00 - fixed to do better job of finding hold codes to which to apply re-constituted details
    *				MV 3/19/02 - 14160 restore bAPWD workfile detail
    *				kb 10/29/2 - issue #18878 - fix double quotes
	*				MV 02/28/07 - #28267 @apline = null
	*				MV 09/10/08 - #128288 - restore tax amounts
	*				MV 01/28/10 - #136500 - changed APTD TaxAmount to GSTtaxAmt
	*				MV 03/02/10 - #136500 - restore old GST tax amt.
	*				MV 05/26/10 - #136500 - restore updated tax on splits when orig not updated
    * USAGE:
    * Consolidates unpaid and uncleared sequences in APTD for an
    * entire transaction or for a specified line.  This removes
    * any unwanted splits created by partial payments.
    *
    *  INPUT PARAMETERS
    *   @apco	AP company number
    *   @mth	expense month of trans
    *   @aptrans	transaction to restrict by
    *   @apline	line to restrict by (null for all)
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
   *********************************
   **********************************/
   (@apco bCompany = 0, @mth bMonth, @aptrans bTrans, @apline smallint = null, @msg varchar(90) output)
   
   as
   set nocount on
   
   declare @rcode tinyint, @APTDopened tinyint, @numberofseqs int, @dtlline smallint,
   	@dtlseq tinyint, @dtlpaytype tinyint, @ttlamount bDollar, @ttldiscoffer bDollar,
   	@ttldisctaken bDollar, @ttltottaxamount bDollar, @ttltaxamount bDollar, @ttloldtaxamount bDollar,
	@dtltottaxamt bDollar, @dtlgsttaxamt bDollar, @dtloldgsttaxamt bDollar, @dtlexpenseGST bYN
   
   select @rcode=0
   
   /* validate line */
   if @apline is not null
   	begin
   	 if not exists (select * from APTD where APCo=@apco and Mth=@mth and APTrans=@aptrans
   			and APLine=@apline)
   		begin
   		 select @msg = 'Invalid Line!' , @rcode=1
   		 goto bspexit
   		end
   	end
   
   /* set open cursor flags to false */
   select @APTDopened = 0

   /* spin through transaction details */
   declare bcAPTD cursor
   	for select APLine, min(APSeq), PayType
   		from bAPTD
   		where APCo=@apco and Mth=@mth and APTrans=@aptrans
   		and APLine=isnull(@apline,APLine) and Status<>3 and Status<>4
   		group by APTrans, APLine, PayType
   		for read only
   
   /* open cursor */
   open bcAPTD
   
   /* set open cursor flag to true */
   
   select @APTDopened = 1
   
   /* loop through all rows in this batch */
   detail_loop:
   	fetch next from bcAPTD into @dtlline, @dtlseq, @dtlpaytype
  
   	if @@fetch_status <> 0 goto bspexit

   	select @numberofseqs=count(APSeq), @ttlamount=sum(Amount), @ttldiscoffer=sum(DiscOffer),@ttldisctaken=sum(DiscTaken),
		@ttltottaxamount=sum(isnull(TotTaxAmount,0)), @ttltaxamount=sum(isnull(GSTtaxAmt,0)), @ttloldtaxamount = sum(isnull(OldGSTtaxAmt,0))
   		from bAPTD
   		where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@dtlline
   		and PayType=@dtlpaytype and Status<>3 and Status<>4
   
   	if @numberofseqs>1
   		begin
   		begin transaction
		/* handle reversing updated GST tax on split holdback transactions - #136500 */
		-- Get additional values from min(APSeq) - should be the 'Original' before splitting
		select @dtlgsttaxamt=GSTtaxAmt, @dtltottaxamt=TotTaxAmount,@dtloldgsttaxamt=OldGSTtaxAmt,@dtlexpenseGST=ExpenseGST
		from bAPTD where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@dtlline and APSeq=@dtlseq
   		and PayType=@dtlpaytype
		if @dtlexpenseGST = 'Y' -- this APSeq is CA holdback with GST expensed when released and paid
			begin
			if @dtloldgsttaxamt = 0 -- APSeq is all of the above plus there could be split sequences that had the tax updated.
			-- Split sequences with updated tax have to be restored to the old tax amount.
				begin
				update APTD set Amount =  ((Amount - GSTtaxAmt) + OldGSTtaxAmt), GSTtaxAmt = OldGSTtaxAmt,TotTaxAmount = OldGSTtaxAmt,OldGSTtaxAmt=0
				where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@dtlline and PayType=@dtlpaytype and Status<>3 and Status<>4
					and OldGSTtaxAmt <> 0
				-- Get updated total amounts 
				select @ttlamount=sum(Amount), @ttldiscoffer=sum(DiscOffer),@ttldisctaken=sum(DiscTaken),
				@ttltottaxamount=sum(isnull(TotTaxAmount,0)), @ttltaxamount=sum(isnull(GSTtaxAmt,0)), @ttloldtaxamount = sum(isnull(OldGSTtaxAmt,0))
   				from bAPTD
   				where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@dtlline
   				and PayType=@dtlpaytype and Status<>3 and Status<>4                                                                     
				end
			end -- END handle reversing updated GST tax on split holdback transactions - #136500  

   		/* update detail amounts into consolidated sequence */
   		update bAPTD
   			set Amount=@ttlamount,TotTaxAmount=@ttltottaxamount,GSTtaxAmt=@ttltaxamount, OldGSTtaxAmt=@ttloldtaxamount
   			where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@dtlline
   			and APSeq=@dtlseq
   		if @@rowcount = 0 goto detail_loop
   		else
   		/* update discoffer and disctaken in bAPWD which updates bAPTD*/
   		update bAPWD
   			set Amount=@ttlamount, DiscOffered=@ttldiscoffer, DiscTaken=@ttldisctaken
   			where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@dtlline
   			and APSeq=@dtlseq
   		/* to sequence just updated, add any hold codes from sequence(s) about to be deleted */
   		insert bAPHD
   			select @apco, @mth, @aptrans, @dtlline, @dtlseq, HoldCode from bAPHD
   			where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@dtlline
               		and APSeq in (select APSeq from bAPTD where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@dtlline
                   	and PayType=@dtlpaytype and Status<>3 and Status<>4)
   			and HoldCode not in (select HoldCode from bAPHD where APCo=@apco and Mth=@mth and APTrans=@aptrans
   			and APLine=@dtlline and APSeq=@dtlseq)
   			and HoldCode not in (select RetHoldCode from bAPCO where APCo=@apco)
   		if @@rowcount <> 0
   			select @msg = 'Warning - During restore, Hold Codes were transferred into merged detail.' , @rcode=5
   
   		/* remove any hold codes from sequence(s) about to be deleted */
   		delete bAPHD
   			where APCo=@apco and Mth=@mth and APTrans=@aptrans
   
   			and APLine=@dtlline and APSeq in (select APSeq from bAPTD
   				where APCo=@apco and Mth=@mth and APTrans=@aptrans
   				and APLine=@dtlline and APSeq<>@dtlseq and PayType=@dtlpaytype
   				and Status<>3 and Status<>4)
   		/* delete bAPWD */
   		delete bAPWD
   			where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@dtlline
   			and APSeq in (select APSeq from bAPTD where APCo=@apco and Mth=@mth
   			and APTrans=@aptrans and APLine=@dtlline and APSeq<>@dtlseq
   			and PayType=@dtlpaytype)
   		/* delete sequence(s) */
   		delete bAPTD
   			where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@dtlline
   			and APSeq<>@dtlseq and PayType=@dtlpaytype and Status<>3 and Status<>4
   		if @@rowcount = 0
   			begin
   			rollback transaction
   			goto detail_loop
   			end
   		commit transaction
   		end
   
   
   	goto detail_loop
   
   
   bspexit:
   	if @APTDopened = 1
   		begin
   		close bcAPTD
   		deallocate bcAPTD
   		end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPRestoreTransDtl] TO [public]
GO
