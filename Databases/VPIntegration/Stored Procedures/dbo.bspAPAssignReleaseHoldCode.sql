SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspAPAssignReleaseHoldCode]
/***********************************************************
* CREATED: EN 08/14/97
* MODIFIED: EN 1/21/99
*			kb 2/17/99 - problem at Leopardo, trying to release a hold code on a trans with no retainage
*			EN 2/18/99
*			EN 3/9/99
*			GH 8/9/99 - time out issue when assigning hold codes by job
*			EN 9/8/99 - neg rtng and matching pos rtng not released properly when release 100%
*			EN 9/9/99 - rtng sometimes not released properly when release amt and there is neg rtng
*           EN 4/26/00 - if hold code is the one set up for retainage in bAPCO, only apply to lines with retainage pay type
*           EN 5/9/00 - return error message if try to apply retainage hold code to a specified non-retainage line/sequence,
*                          and set up warning for not assigning retainage hold code to non-retainage portions
*           SR 09/27/01 - Issue 14734 added check for trans in bcAPDetail to only grab trans of status 1 or 2
*			GG 02/21/02 - Removed unecessary cursor to retrieve Trans total amount
*		    MV 08/15/02 - #17817 added select by a range of phases
*		    MV 10/18/02 - 18878 quoted identifier cleanup
*           bc 02/03/03 - issue #20277
*			MV 08/01/03 - #21834 - return count of transactions released or put on hold
*			MV 09/12/03 - #22453 removed order by clause, redid joins, added performance enhancement to cursor
*			MV 10/20/03 - #21834 fix count of transactions for amount released.
*			MV 02/12/04 - #18769 - Pay Category 
*			ES 03/12/04 - #23061 isnull wrapping
*			MV 04/28/04 - #18769 - Holdcode warning msg/Total Ret to release by PayType
*			MV 01/17/05 = #26759 - add order by mth to select statement
*			MV 02/21/05 - #27216 - fix transaction count, isnull wrap @jcco 
*           MV 07/03/08 - #128288 - insert bAPTD - value 0 for TaxAmount
*			MV 08/15/08 - #129332 - trim Phase for phase list compare
*			MV 07/14/09 - #134776 - corrected bAPTD insert statement
*			MV 01/28/10 - #136500 - changed bAPTD TaxAmount to GSTtaxAmt
*			MV 02/22/10 - #136500 - THIS STORED PROC IS NO LONGER USED FOR HOLD AND RELEASE.
*									SEE vspAPAssignReleaseHoldCode or vspAPHoldRelAPHR
* USAGE:
* This procedure is called from AP Hold and Release and AP Pay Control Functions
* and will assign or release hold codes to open AP transactions.
* An error is returned if anything goes wrong.
*
*  INPUT PARAMETERS
*   @aropt	'A' if assigning hold codes or 'R' if releasing them
*   @holdcode	hold code to assign or release
*   @jcco	company of job to restrict by (null for all)
*   @job	job to restrict by (null for all)
*   @apco	AP company number
*   @vendgrp	vendor group
*   @vendor	vendor to restrict by (null for all)
*   @retopt	'A' if releasing amt, 'P' if releasing percent, null if neither
*   @retamount	amount of retainage to release
*   @retpercent	percent of retainage to release
*   @ptlist	list of pay types to restrict on
*   @fmth	expense month of trans (null for all)
*   @ftrans	transaction to restrict by (null for all)
*   @fline	line to restrict by (null for all)
*   @fseq	sequence to restrict by (null for all)
*   @phslist   phase list - a range of phases if selecting by Job and phase
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************/
	(@aropt varchar(1) = null, @holdcode bHoldCode = null, @jcco bCompany = null,
     @job bJob = null, @apco bCompany = 0, @vendgrp bGroup = null,
     @vendor bVendor = null, @retopt varchar(1) = null, @retamount bDollar = 0,
     @retpercent bPct = 0, @ptlist varchar(200)=null, @fmth bMonth = null, @ftrans bTrans = null,
     @fline smallint = null, @fseq tinyint = null, @phslist varchar (200)= null,	@msg varchar(200) output)
          
as
set nocount on

declare @rcode tinyint, @aprettype tinyint, @mth bMonth, @aptrans bTrans, @apline smallint,
	@apseq tinyint, @seq tinyint, @paytype tinyint, @amount bDollar, @discoffer bDollar,
	@disctaken bDollar, @duedate bDate, @status tinyint, @paidmth bMonth, @paiddate bDate,
	@cmco bCompany, @cmacct bCMAcct, @paymethod varchar(1), @cmref bCMRef, @cmrefseq tinyint,
	@eftseq smallint, @vendgroup bGroup, @supplier bVendor,  @amtreleased bDollar, @part bDollar,
	@APVMopened tinyint, @APDetailopened tinyint, @rc tinyint, @vendkey bVendor,@count int,@foundamt bDollar,
	@retholdcode bHoldCode, @retonlytype tinyint, @phasegroup bGroup, @paycategory int, @appcrettype tinyint,
	@lastmth bMonth, @lasttrans bTrans

select @rcode=0, @count=0
      
-- select retainage pay type and hold code from bAPCO
select @aprettype = RetPayType, @retholdcode = RetHoldCode
from dbo.bAPCO (nolock) where APCo=@apco

-- set value of pay type to check for if putting only retainage on hold; else null
select @retonlytype = null
if @holdcode = @retholdcode select @retonlytype = @aprettype
if @ptlist = '' select @ptlist = null
if @phslist = '' select @phslist = null

--get phasegroup if phslist is not null
if @phslist is not null
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
/* validate line */
if @fline is not null
	begin
	if not exists (select 1 from dbo.bAPTD (NOLOCK)
					where APCo=@apco and Mth=@fmth and APTrans=@ftrans and APLine=@fline)
		begin
		select @msg = 'Invalid Line!', @rcode=1
		goto bspexit
		end
	end
/* validate seq */
if @fseq is not null
	begin
	if not exists (select 1 from dbo.bAPTD (NOLOCK)
					where APCo=@apco and Mth=@fmth and APTrans=@ftrans and APLine=@fline and APSeq=@fseq)
		begin
		select @msg = 'Invalid Sequence!', @rcode=1
		goto bspexit
		end
	end
      
          if @aropt = 'A'
              begin
              -- if line/seq was selected, check PayType against HoldCode
     			if @fline is not null and @fseq is not null
     			begin
     			-- get paytype and paycategory for line and seq
     			select @paytype = PayType,@paycategory = PayCategory from APTD WITH (NOLOCK)
       				where APCo=@apco and Mth=@fmth and APTrans=@ftrans and APLine=@fline and APSeq=@fseq
     			if @paycategory is not null
     				begin	-- get retainage paytype if using pay category
     				select @appcrettype = RetPayType from bAPPC with (nolock)
     					 where APCo=@apco and PayCategory=@paycategory
     				end
     			if @holdcode = (select RetHoldCode from APCO WITH (NOLOCK) where APCo=@apco)
     				and ((@paycategory is null and @aprettype <> @paytype)
     					or (@paycategory is not null and @appcrettype <> @paytype))
     --          if @fline is not null and @fseq is not null and
     --  			@holdcode = (select RetHoldCode from APCO WITH (NOLOCK) where APCo=@apco) and
     --  			@aprettype <>(select PayType from APTD WITH (NOLOCK)
     --  				where APCo=@apco and Mth=@fmth and APTrans=@ftrans and APLine=@fline and APSeq=@fseq)
                   begin
                   select @msg = 'Cannot assign retainage hold code to non-retainage paytype lines.', @rcode = 1
                   goto bspexit
                   end
      			end
     
              -- if retainage hold code selected, set warning
              if @fline is null and @fseq is null and
      			@holdcode = (select RetHoldCode from APCO WITH (NOLOCK) where APCo=@apco) and
      			exists (select 1 from bAPTH h WITH (NOLOCK)
      				join bAPTL l WITH (NOLOCK) on h.APCo=l.APCo and	h.Mth=l.Mth and h.APTrans=l.APTrans
                     	join bAPTD d WITH (NOLOCK) on h.APCo=d.APCo and h.Mth=d.Mth and h.APTrans=d.APTrans and l.APLine=d.APLine
                     where h.APCo=@apco and h.Mth=isnull(@fmth,h.Mth) and h.APTrans=isnull(@ftrans,h.APTrans)
                     and h.VendorGroup=@vendgrp and h.Vendor=isnull(@vendor,h.Vendor) and h.OpenYN='Y'
          	       and h.InUseBatchId is null and isnull(l.JCCo,0)=isnull(isnull(@jcco,l.JCCo),0)
          	       and isnull(l.Job,'')=isnull(isnull(@job,l.Job),'') and d.CMRef is null 
     			   and (d.PayCategory is null and d.PayType <> @aprettype)	
     			   or (d.PayCategory is not null and d.PayType <> (select RetPayType from bAPPC with (nolock) where APCo=@apco and PayCategory=d.PayCategory))
          	       and ((charindex(',' + isnull(convert(varchar(10),d.PayType), '') + ',', @ptlist) > 0) or @ptlist is null))  -- #23061
      	       select @msg = 'Hold Code is for retainage only and cannot be applied to any non-retainage paytype lines.', @rcode = 5
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
      				((charindex(',' + rtrim(Phase) + ',', isnull(@phslist, '')) > 0) or @phslist is null))	--#23061
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
     			--and d.PayType=@aprettype
     			and ((d.PayCategory is null and d.PayType=@aprettype)
     			 	or (d.PayCategory is not null and d.PayType=(select RetPayType from bAPPC with (nolock)
     			 		where APCo=@apco and PayCategory=d.PayCategory)))
     			--where d.APCo=@apco and d.PayType=@aprettype and d.Status=2
     	    	and isnull(l.JCCo,0)=isnull(isnull(@jcco,l.JCCo),0)
     	    	and isnull(l.Job,'')=isnull(isnull(@job,l.Job),'')
     			and isnull(l.PhaseGroup,0)=isnull(isnull(@phasegroup,l.PhaseGroup),0)
     			and ((charindex(',' + rtrim(l.Phase) + ',', isnull(@phslist, '')) > 0) or @phslist is null)   --#23061
   			and ((charindex(',' + isnull(convert(varchar(10),d.PayType), '') + ',', isnull(@ptlist, '')) > 0) or @ptlist is null)
     	    	and h.VendorGroup=@vendgrp and h.Vendor=@vendkey
     	    	--group by d.APCo, d.Mth, d.APTrans, d.APLine, d.APSeq, d.Amount
      		
     
              /* calculate retainage based on percentage */
--          	if @retopt = 'P' select @retamount = isnull(@foundamt,0) * @retpercent
      
          	declare bcAPDetail cursor LOCAL FAST_FORWARD	--#22453 
      			for select d.Mth, d.APTrans, d.APLine, d.APSeq, d.PayType,
           		d.Amount, d.DiscOffer, d.DiscTaken, d.DueDate, d.Status, d.PaidMth,
           		d.PaidDate, d.CMCo, d.CMAcct, d.PayMethod, d.CMRef, d.CMRefSeq,
           		d.EFTSeq, d.VendorGroup, d.Supplier,d.PayCategory
      			from bAPTH h WITH (NOLOCK)
      			JOIN bAPTL l WITH (NOLOCK) on h.APCo=l.APCo and h.Mth=l.Mth and h.APTrans=l.APTrans 
      			JOIN bAPTD d WITH (NOLOCK) on l.APCo=d.APCo and l.Mth=d.Mth and l.APTrans=d.APTrans 
      				and l.APLine=d.APLine
           		/*from bAPTH h, bAPTL l, bAPTD d*/
           		where h.APCo=@apco and h.VendorGroup=@vendgrp and h.Vendor=@vendkey 
     
           		and h.InUseBatchId is null and isnull(l.JCCo,0)=isnull(isnull(@jcco,l.JCCo),0)
           		and isnull(l.Job,'')=isnull(isnull(@job,l.Job),'')
       		    and isnull(l.PhaseGroup,0)=isnull(isnull(@phasegroup,l.PhaseGroup),0)
       			and ((charindex(',' + rtrim(l.Phase) + ',', isnull(@phslist, '')) > 0) or @phslist is null)   --#23061
       		    and d.CMRef is null
           		and ((charindex(',' + isnull(convert(varchar(10),d.PayType), '') + ',', isnull(@ptlist, '')) > 0) or @ptlist is null)
            		and d.Mth=isnull(@fmth,d.Mth) and d.APTrans=isnull(@ftrans,d.APTrans)
           		and d.APLine=isnull(@fline,d.APLine) and d.APSeq=isnull(@fseq,d.APSeq)
     				and ((d.PayCategory is null and d.PayType=isnull(@retonlytype,d.PayType))
     					or (d.PayCategory is not null and @retonlytype is not null and 
     					 	d.PayType=(select RetPayType from bAPPC with (nolock)
     					 	where APCo=@apco and PayCategory=d.PayCategory))
     					or (d.PayCategory is not null and @retonlytype is null))
           		--and d.PayType = isnull(@retonlytype,d.PayType)  
     				and d.Status in (1,2)
   				order by d.Mth --#26759 
      			/*Pay Category code above - if using Pay Category the paytype must = bAPPC.RetPayType ONLY
     				if the holdcode entered is a retainage hold code. If the holdcode is a retainage holdcode
     				then @retonlytype is not null.*/
      
          	/* open cursor */
          	open bcAPDetail
          	/* set open cursor flag to true */
          	select @APDetailopened = 1
          	/* loop through all rows in this batch */
          	detail_loop:
          		fetch next from bcAPDetail into @mth, @aptrans, @apline, @apseq, @paytype,
          			@amount, @discoffer, @disctaken, @duedate, @status, @paidmth,
          			@paiddate, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, @eftseq,
          			@vendgroup, @supplier, @paycategory
          		if @@fetch_status <> 0 goto detail_loop_end
   
   			/* ASSIGN HOLD CODES */
          		if @aropt='A' 
          			BEGIN
          			if not exists (select 1 from APHD WITH (NOLOCK)
          					where APCo=@apco and Mth=@mth and APTrans=@aptrans
          					and APLine=@apline and APSeq=@apseq
          					and HoldCode=@holdcode)
          				/* add entry to APHD for selected hold code */
          				begin
          				insert bAPHD values (@apco, @mth, @aptrans, @apline, @apseq, @holdcode)
          				if @@rowcount = 0
          					begin
          					select @msg = 'Could not add hold detail.  Update cancelled!'
          					goto bspexit
          					end
      					else
   						if (@lastmth is null and @lasttrans is null) or (@lastmth <> @mth or @lasttrans <> @aptrans) --#27216
   						begin
   						select @count = @count + 1
   						select @lastmth=@mth, @lasttrans=@aptrans
   						end
         				end
          			END
     
     			/* RELEASE HOLD CODES */
          		if @aropt='R'  
          			BEGIN
          			/* release from hold in APHD unless transaction is being split */
          			begin transaction
          			if exists (select 1 from APHD WITH (NOLOCK)
          					where APCo=@apco and Mth=@mth and APTrans=@aptrans
          					and APLine=@apline and APSeq=@apseq
          					and HoldCode=@holdcode)
          				BEGIN
          				 if not (@retopt='P' and @retpercent=1)
                                  and not (@retopt='A' and @retamount>=@foundamt)
                                  and @retopt is not null
     							 --and @paytype = @aprettype 
     							 and ((@paycategory is null and @paytype = @aprettype)
     								 or (@paycategory is not null and @paytype=(select RetPayType from bAPPC with (nolock)
     					 				where APCo=@apco and PayCategory=@paycategory)))
                                  and @retamount < @amount + @amtreleased
          					BEGIN
          					 /* release part of detail from hold */
          					 /* update amt to be left on hold */
          					 update bAPTD
          					 set Amount = @amount - (@retamount - @amtreleased)
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
          					 /* add APTD entry */
          					 insert bAPTD (APCo,Mth,APTrans,APLine,APSeq,PayType,Amount,DiscOffer,DiscTaken,DueDate,Status,PaidMth,
								PaidDate,CMCo,CMAcct,PayMethod,CMRef,CMRefSeq,EFTSeq,VendorGroup,Supplier,PayCategory,GSTtaxAmt,TotTaxAmount)
          					 values (@apco, @mth, @aptrans, @apline,
          						@seq, @paytype, @retamount - @amtreleased,
          						@discoffer, @disctaken, @duedate, 1,
          						@paidmth, @paiddate, @cmco, @cmacct,
          						@paymethod, @cmref, @cmrefseq, @eftseq,
          						@vendgroup, @supplier, @paycategory, 0,0 )
          					 if @@rowcount = 0
          						begin
          						 select @msg = 'Could not add transaction detail.  Update cancelled!',
       							@rcode = 1
          						 rollback transaction
          						 goto bspexit
          						end
          					 /* apply any hold codes assigned to original line other than the one being released */
          					 insert bAPHD
          					 select APCo, Mth, APTrans, APLine, @seq, HoldCode
          					 from bAPHD
          					 where APCo = @apco and Mth = @mth and APTrans = @aptrans
          					 	and APLine = @apline and APSeq = @apseq
       	   					    and HoldCode <> @holdcode
           					 select @amtreleased = @retamount
   						-- increment transaction counter 
     						if (@lastmth is null and @lasttrans is null) or (@lastmth <> @mth or @lasttrans <> @aptrans) --#27216
   							begin
   							select @count = @count + 1
   							select @lastmth=@mth, @lasttrans=@aptrans
   							end
          					END
     
          				 if @retopt is null or (@retopt='P' and @retpercent=1)
                                  or (@retopt='A' and @retamount>=@foundamt)
                                  or (@retopt is not null
     								/*and @paytype = @aprettype*/
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
          					 /* release entire detail from hold */
          					 delete bAPHD
          						where APCo=@apco and Mth=@mth and APTrans=@aptrans
          						and APLine=@apline and APSeq=@apseq
          						and HoldCode=@holdcode
          					 if @@rowcount = 0
          						begin
          						select @msg = 'Could not delete hold detail.  Update cancelled!',
       							@rcode = 1
          						rollback transaction
          						goto bspexit
          						end
   						 else
   							begin
   							-- increment transaction counter 
   		  					if (@lastmth is null and @lasttrans is null) or (@lastmth <> @mth or @lasttrans <> @aptrans) --#27216
   								begin
   								select @count = @count + 1
   								select @lastmth=@mth, @lasttrans=@aptrans
   								end
   							end
          					 if @retopt is not null
          					 	select @amtreleased = @amtreleased + @amount
          					END
      
          				END
     	     			commit transaction
     					-- increment transaction counter 
   -- 					select @count = @count + 1
   									
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
      
      		-- return count of transactions released or put on hold
      		if @rcode = 0
      			begin
      			select @msg = isnull(convert (varchar(10), @count),'') + case when @aropt='R' then ' transactions released.'
      				else ' transactions put on hold.' end
      			end
      		-- return warning msg and count
      			if @rcode = 5
      			begin
      			select @msg = @msg + isnull(convert (varchar(10), @count),'')
      			select @msg = @msg + case when @aropt='R' then ' transactions released.'
      				else ' transactions put on hold.' end
      			end
          	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPAssignReleaseHoldCode] TO [public]
GO
