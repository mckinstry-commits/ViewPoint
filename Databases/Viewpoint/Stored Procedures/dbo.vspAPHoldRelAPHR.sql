SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspAPHoldRelAPHR]
/***********************************************************
* CREATED: MV 02/16/10
* MODIFIED: MV 05/17/10 - split tax amounts out on split transactions
*
* USAGE:
* This procedure is called from AP Hold and Release 
* and updates bAPHR with open transactions to be released
* based on selection criteria passed.
*
*  INPUT PARAMETERS
*   @jcco	company of job to restrict by (null for all)
*   @job	job to restrict by (null for all)
*   @apco	AP company number
*   @vendgrp	vendor group
*   @vendor	vendor to restrict by (null for all)
*   @retopt	'A' if releasing amt, 'P' if releasing percent, null if neither
*   @retamount	amount of retainage to release
*   @retpercent	percent of retainage to release
*   @PayTypeList	list of pay types to restrict on
*   @PhaseList   phase list - a range of phases if selecting by Job and phase
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************/
	(@apco bCompany = 0,@holdcode bHoldCode = null,@vendgrp bGroup = null,@vendor bVendor = null,
	 @jcco bCompany = null,@job bJob = null,@PhaseList varchar (200)= null,@PayTypeList varchar(200)=null,
	 @retopt varchar(1) = null,@retamount bDollar = 0,@retpercent bPct = 0, @ApplyNewTaxRateYN bYN, 
	 @userid bVPUserName, @msg varchar(200) output)
          
as
set nocount on

declare @rcode tinyint, @aprettype tinyint, @mth bMonth, @aptrans bTrans, @apline smallint,
	@apseq tinyint, @seq tinyint, @paytype tinyint, @amount bDollar, @discoffer bDollar,
	@disctaken bDollar, @duedate bDate, @status tinyint, @paidmth bMonth, @paiddate bDate,
	@cmco bCompany, @cmacct bCMAcct, @paymethod varchar(1), @cmref bCMRef, @cmrefseq tinyint,
	@eftseq smallint, @vendgroup bGroup, @supplier bVendor,  @amtreleased bDollar, @part bDollar,
	@APVMopened tinyint, @APDetailopened tinyint, @rc tinyint, @vendkey bVendor,@count int,@foundamt bDollar,
	@retholdcode bHoldCode, @RetOnlyPayType tinyint, @phasegroup bGroup, @paycategory int, @appcrettype tinyint,
	@lastmth bMonth, @lasttrans bTrans, @APTDTotTax bDollar, @APTDGSTTax bDollar, @totaltax bDollar, @gsttax bDollar,
	@splittottax bDollar, @splitgsttax bDollar,@expenseGSTyn bYN

select @rcode=0, @count=0
      
-- select retainage pay type and hold code from bAPCO
select @aprettype = RetPayType, @retholdcode = RetHoldCode
from dbo.bAPCO (nolock) where APCo=@apco

-- set value of pay type to check for if putting only retainage on hold; else null
select @RetOnlyPayType = null
if @holdcode = @retholdcode select @RetOnlyPayType = @aprettype
if @PayTypeList = '' select @PayTypeList = null
if @PhaseList = '' select @PhaseList = null
if @holdcode = '' select @holdcode = null
if @retopt = '' select @retopt = null

--get phasegroup if phslist is not null
if @PhaseList is not null
	begin
	select @phasegroup=PhaseGroup
	from dbo.bHQCO (nolock) where HQCo=@jcco
	end
	
/* set open cursor flags to false */
select @APVMopened = 0, @APDetailopened = 0

/* validate Hold Code */
if not exists (select 1 from dbo.bHQHC (NOLOCK) where HoldCode=@holdcode)
	begin
	select @msg = 'Invalid Hold Code!', @rcode = 1
	goto bspexit
	end
      
      /* spin through vendor(s) */
     if @job is not null /* speed up retrieval when assigning hold codes by job */
         begin
         declare bcAPVM cursor LOCAL FAST_FORWARD
         for select distinct Vendor
         from bAPTH WITH (NOLOCK)
         where VendorGroup=@vendgrp and Vendor=isnull(@vendor,Vendor)and
  		 	exists (select 1 from bAPTL WITH (NOLOCK)
  				where bAPTH.APCo=bAPTL.APCo and bAPTH.Mth=bAPTL.Mth and
         			bAPTH.APTrans=bAPTL.APTrans and bAPTL.Job=@job and
  				isnull(PhaseGroup,0)=isnull(isnull(@phasegroup,PhaseGroup),0)and
  				((charindex(',' + rtrim(Phase) + ',', isnull(@PhaseList, '')) > 0) or @PhaseList is null))	--#23061
         end
     else
        begin
        declare bcAPVM cursor LOCAL FAST_FORWARD
      	for select Vendor
      	from bAPVM WITH (NOLOCK)
      	where VendorGroup=@vendgrp and Vendor=isnull(@vendor,Vendor)
        end
  
      /* open cursor */
      open bcAPVM
      /* set open cursor flag to true */
      select @APVMopened = 1
      /* loop through all vendors */
      vendor_search_loop:
      	select @amtreleased = 0
      	fetch next from bcAPVM into @vendkey
      	if @@fetch_status <> 0 goto bspexit
  
          /* get total retainage amount for vendor */
  		 select @foundamt = 0
 			select @foundamt = sum(d.Amount)
 	    	from APTD d WITH (NOLOCK)
 	    	join APTL l WITH (NOLOCK) on l.APCo=d.APCo and l.Mth=d.Mth and l.APTrans=d.APTrans 
 				and l.APLine = d.APLine
 	    	join APTH h WITH (NOLOCK) on h.APCo=d.APCo and h.Mth=d.Mth and h.APTrans=d.APTrans
 	    	where d.APCo=@apco and d.Status=2
 			and ((d.PayCategory is null and d.PayType=@aprettype)
 			 	or (d.PayCategory is not null and d.PayType=(select RetPayType from bAPPC with (nolock)
 			 		where APCo=@apco and PayCategory=d.PayCategory)))
 	    	and isnull(l.JCCo,0)=isnull(isnull(@jcco,l.JCCo),0)
 	    	and isnull(l.Job,'')=isnull(isnull(@job,l.Job),'')
 			and isnull(l.PhaseGroup,0)=isnull(isnull(@phasegroup,l.PhaseGroup),0)
 			and ((charindex(',' + rtrim(l.Phase) + ',', isnull(@PhaseList, '')) > 0) or @PhaseList is null)   
			and ((charindex(',' + isnull(convert(varchar(10),d.PayType), '') + ',', isnull(@PayTypeList, '')) > 0) or @PayTypeList is null)
 	    	and h.VendorGroup=@vendgrp and h.Vendor=@vendkey
 
          /* calculate retainage based on percentage */
      	if @retopt = 'P' select @retamount = isnull(@foundamt,0) * @retpercent
                   
		/* Get transaction detail to work with */
      	declare bcAPDetail cursor LOCAL FAST_FORWARD	
  			for select d.Mth, d.APTrans, d.APLine, d.APSeq, d.PayType,
       		d.Amount, d.DiscOffer, d.DiscTaken, d.DueDate, d.Status, d.PaidMth,
       		d.PaidDate, d.CMCo, d.CMAcct, d.PayMethod, d.CMRef, d.CMRefSeq,
       		d.EFTSeq, d.VendorGroup, d.Supplier,d.PayCategory,d.TotTaxAmount,d.GSTtaxAmt,d.ExpenseGST
  			from bAPTH h WITH (NOLOCK)
  			JOIN bAPTL l WITH (NOLOCK) on h.APCo=l.APCo and h.Mth=l.Mth and h.APTrans=l.APTrans 
  			JOIN bAPTD d WITH (NOLOCK) on l.APCo=d.APCo and l.Mth=d.Mth and l.APTrans=d.APTrans 
  				and l.APLine=d.APLine
       		where h.APCo=@apco and h.VendorGroup=@vendgrp and h.Vendor=@vendkey 
       		and h.InUseBatchId is null and h.InPayControl = 'N'
			and isnull(l.JCCo,0)=isnull(isnull(@jcco,l.JCCo),0)
       		and isnull(l.Job,'')=isnull(isnull(@job,l.Job),'')
   		    and isnull(l.PhaseGroup,0)=isnull(isnull(@phasegroup,l.PhaseGroup),0)
   			and ((charindex(',' + rtrim(l.Phase) + ',', isnull(@PhaseList, '')) > 0) or @PhaseList is null)  
   		    and d.CMRef is null
       		and ((charindex(',' + isnull(convert(varchar(10),d.PayType), '') + ',', isnull(@PayTypeList, '')) > 0) or @PayTypeList is null)
        	and ((d.PayCategory is null and d.PayType=isnull(@RetOnlyPayType,d.PayType))
 					or (d.PayCategory is not null and @RetOnlyPayType is not null and 
 					 	d.PayType=(select RetPayType from bAPPC with (nolock)
 					 	where APCo=@apco and PayCategory=d.PayCategory))
 					or (d.PayCategory is not null and @RetOnlyPayType is null))
			and exists (select * from APHD hd where hd.APCo=d.APCo and hd.Mth=d.Mth and hd.APTrans=d.APTrans 
  				and hd.APLine=d.APLine and hd.APSeq=d.APSeq and hd.HoldCode= isnull(@holdcode, hd.HoldCode))
 			and d.Status in (1,2)
			order by d.Mth  

     	/* open cursor */
      	open bcAPDetail
      	/* set open cursor flag to true */
      	select @APDetailopened = 1
      	/* loop through all rows */
      	detail_loop:
      		fetch next from bcAPDetail into @mth, @aptrans, @apline, @apseq, @paytype,
      			@amount, @discoffer, @disctaken, @duedate, @status, @paidmth,
      			@paiddate, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, @eftseq,
      			@vendgroup, @supplier, @paycategory,@APTDTotTax,@APTDGSTTax,@expenseGSTyn 
      		if @@fetch_status <> 0 goto detail_loop_end
 
 			/* ADD TRANS DETAIL TO APHR */
      			BEGIN
      			/* Split transaction - Insert APHR with partial retainage amount to be released 
				   and update APTD with remaining retainage amount */
      			begin transaction
      			if exists (select 1 from APHD WITH (NOLOCK)
      					where APCo=@apco and Mth=@mth and APTrans=@aptrans
      					and APLine=@apline and APSeq=@apseq
      					and HoldCode=@holdcode)
      				BEGIN
      				 if not (@retopt='P' and @retpercent=1)
                                  and not (@retopt='A' and @retamount>=@foundamt)
                                  and @retopt is not null
     							 and ((@paycategory is null and @paytype = @aprettype)
     								 or (@paycategory is not null and @paytype=(select RetPayType from bAPPC with (nolock)
     					 				where APCo=@apco and PayCategory=@paycategory)))
                                  and @retamount < @amount + @amtreleased
      					BEGIN
      					 /* update APTD with retainage amt to be left on hold */
						 --calculate tax amounts to be split out
						select @splittottax = @APTDTotTax * ((@retamount - @amtreleased)/@amount)
						select @splitgsttax = @APTDGSTTax * ((@retamount - @amtreleased)/@amount)
						select @totaltax = @APTDTotTax - @splittottax
						select @gsttax = @APTDGSTTax - @splitgsttax
      					 update bAPTD
      					 set Amount = @amount - (@retamount - @amtreleased), TotTaxAmount = @totaltax, GSTtaxAmt=@gsttax
      					 where APCo=@apco and Mth=@mth and APTrans=@aptrans
      						and APLine=@apline and APSeq=@apseq
      					 if @@rowcount = 0
      						begin
      						 select @msg = 'Could not change transaction detail amount.  Update cancelled!', @rcode = 1
      						 rollback transaction
      						 goto bspexit
 							 end
      					 /* add APTD entry for amt to be released */
      					 /* find next sequence number */
      					 select @seq = max(APSeq)+1 from APTD WITH (NOLOCK)
      						where APCo=@apco
      						and Mth=@mth
      						and APTrans=@aptrans
      						and APLine=@apline
      					 if @@rowcount = 0
      						begin
      						 select @msg = 'Could not determine new sequence number.  Update cancelled!',
   						   @rcode = 1
      						 rollback transaction
      						 goto bspexit
      						end

      					 /* add APTD entry - this is the split, the portion of trans detail to be released */
      					 insert bAPTD (APCo,Mth,APTrans,APLine,APSeq,PayType,Amount,DiscOffer,DiscTaken,DueDate,Status,PaidMth,
							PaidDate,CMCo,CMAcct,PayMethod,CMRef,CMRefSeq,EFTSeq,VendorGroup,Supplier,PayCategory,GSTtaxAmt,
							TotTaxAmount,ExpenseGST)
      					 values (@apco, @mth, @aptrans, @apline,
      						@seq, @paytype, @retamount - @amtreleased,
      						@discoffer, @disctaken, @duedate, 1,
      						@paidmth, @paiddate, @cmco, @cmacct,
      						@paymethod, @cmref, @cmrefseq, @eftseq,
      						@vendgroup, @supplier, @paycategory,@splitgsttax,
							@splittottax,@expenseGSTyn)
      					 if @@rowcount = 0
      						begin
      						 select @msg = 'Could not add transaction detail.  Update cancelled!',
   							@rcode = 1
      						 rollback transaction
      						 goto bspexit
      						end
      					 /* apply any hold codes assigned to original line */
      					 insert bAPHD
      					 select APCo, Mth, APTrans, APLine, @seq, HoldCode
      					 from bAPHD
      					 where APCo = @apco and Mth = @mth and APTrans = @aptrans
      					 	and APLine = @apline and APSeq = @apseq


						/*Insert transaction detail to be released into bAPHR */
						 if not exists( select * from APHR where APCo=@apco and Mth=@mth and APTrans=@aptrans and
							APLine=@apline and APSeq=@seq and PayType=@paytype)
							begin
							 insert bAPHR (APCo,UserId,Mth,APTrans,APLine,APSeq,PayType,Amount,HoldCode,ApplyNewTaxRateYN)
      						 values (@apco, @userid, @mth, @aptrans, @apline,@seq, @paytype, @retamount - @amtreleased,@holdcode,@ApplyNewTaxRateYN)
							  if @@rowcount = 0
      							begin
      							select @msg = 'Could not add transaction detail to bAPHR.  Grid Fill cancelled!',
   								@rcode = 1
      							 rollback transaction
      							 goto bspexit
      							end
							 /*update amount released */
       						 select @amtreleased = @retamount
							 select @count = @count + 1
							end
      					END
 
				/* Transaction Detail to be released is non retainage or retainage that doesn't need to be split */
  				 if @retopt is null or (@retopt='P' and @retpercent=1)
                              or (@retopt='A' and @retamount>=@foundamt)
                              or (@retopt is not null
 								and ((@paycategory is null and @paytype = @aprettype)
 									or (@paycategory is not null and @paytype=(select RetPayType from bAPPC with (nolock)
 					 				where APCo=@apco and PayCategory=@paycategory)))
 								and @retamount >= @amount + @amtreleased)
                              or (@retopt='P' 
 								and ((@paycategory is null and @paytype <> @aprettype)
 									or (@paycategory is not null and @paytype<>(select RetPayType from bAPPC with (nolock)
 					 				where APCo=@apco and PayCategory=@paycategory)))
 								and @retamount = 0) 
  				 	BEGIN
  					 /* Insert bAPHR with transaction detail to be released  */
					  if not exists( select * from APHR where APCo=@apco and Mth=@mth and APTrans=@aptrans and
						APLine=@apline and APSeq=@apseq and PayType=@paytype)
						begin
						insert bAPHR (APCo,UserId,Mth,APTrans,APLine,APSeq,PayType,Amount,HoldCode,ApplyNewTaxRateYN)
  						 values (@apco,@userid, @mth, @aptrans, @apline,@apseq, @paytype,@amount,@holdcode,@ApplyNewTaxRateYN)
						  if @@rowcount = 0
  								begin
  								 select @msg = 'Could not add transaction detail to bAPHR.  Grid Fill cancelled!',
								@rcode = 1
  								 rollback transaction
  								 goto bspexit
  								end
						  else
							select @count = @count + 1
							if @retopt is not null
				 			select @amtreleased = @amtreleased + @amount
						end
  					END
  				END
     			commit transaction
								
 	     			if @retopt is not null and @amtreleased=@retamount
 	                         and not (@retopt='P' and @retpercent=1)
 	                         and not (@retopt='A' and @retamount>=@foundamt)
 	                goto detail_loop_end
      			END
      		goto detail_loop
  
      		detail_loop_end:
      			close bcAPDetail
      			deallocate bcAPDetail
      			select @APDetailopened = 0
      			goto vendor_search_loop

      bspexit:
      	if @APDetailopened = 1
      		begin
      		close bcAPDetail
      		deallocate bcAPDetail
      		end
  
      	if @APVMopened = 1
      		begin
      		close bcAPVM
      		deallocate bcAPVM
      		end
  
		if @rcode = 0
		begin
		if @count > 0
			begin
			select @msg = convert(varchar(10),@count) + ' transactions to release added to the Selection Display Grid.'
			end
		else
			begin
			select @msg = 'No transactions to release were added to the Selection Display Grid.'
			end
		end		
		

      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPHoldRelAPHR] TO [public]
GO
