SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspAPAssignReleaseHoldCode]
/***********************************************************
* CREATED:  MV 02/22/10 #136500 - modified old stored proc 'bspAssignReleaseHoldCode' to assign for both APHoldRel and APPayCntrlDet
*								  but release only for APPayCntrlDet.  Release for APHoldRel is now done in 'vspAPHoldRelAPHR'								  
* MODIFIED:	MV 05/24/10 #136500 - do not calculate OldGSTtaxAmt if it is not 0 (has already been calculated and updated)
*			MV 11/1/11 - TK09243 - multilevel taxcodes net of retention - recalc tax amount for GST/PST
*			MV 11/15/11 - TK09243 - corrected update to bAPTD on released retainage.
*
* USAGE:
* This procedure is called from AP Hold and Release and AP Pay Control Functions
* to assign hold codes to open AP transactions.  Releases holdcodes for APPayCntrlDet
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
*   @PayTypeList	list of pay types to restrict on
*   @fmth	expense month of trans 
*   @ftrans	transaction to restrict by 
*   @fline	line to restrict by (null for all)
*   @fseq	sequence to restrict by (null for all)
*   @PhaseList   phase list - a range of phases if selecting by Job and phase
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
     @vendor bVendor = null, @PayTypeList varchar(200)=null, @fmth bMonth = null, @ftrans bTrans = null,
     @fline smallint = null, @fseq tinyint = null, @PhaseList varchar (200)= null,@ApplyNewTaxRate bYN, 
	 @msg varchar(200) output)
          
as
set nocount on

declare @rcode tinyint, @aprettype tinyint, @mth bMonth, @aptrans bTrans, @apline smallint,
	@apseq tinyint, @seq tinyint, @paytype tinyint, @amount bDollar, @discoffer bDollar,
	@disctaken bDollar, @duedate bDate, @status tinyint, @paidmth bMonth, @paiddate bDate,
	@cmco bCompany, @cmacct bCMAcct, @paymethod varchar(1), @cmref bCMRef, @cmrefseq tinyint,
	@eftseq smallint, @vendgroup bGroup, @supplier bVendor,  @amtreleased bDollar, @part bDollar,
	@APVMopened tinyint, @APDetailopened tinyint, @rc tinyint, @vendkey bVendor,@count int,@foundamt bDollar,
	@retholdcode bHoldCode, @retonlytype tinyint, @phasegroup bGroup, @paycategory int, @appcrettype tinyint,
	@lastmth bMonth, @lasttrans bTrans, @NewGSTtaxAmt bDollar

select @rcode=0, @count=0
      
-- select retainage pay type and hold code from bAPCO
select @aprettype = RetPayType, @retholdcode = RetHoldCode
from dbo.bAPCO (nolock) where APCo=@apco

-- set value of pay type to check for if putting only retainage on hold; else null
select @retonlytype = null
if @holdcode = @retholdcode select @retonlytype = @aprettype
if @PayTypeList = '' select @PayTypeList = null
if @PhaseList = '' select @PhaseList = null
if @ApplyNewTaxRate = '' or @ApplyNewTaxRate = Null select @ApplyNewTaxRate = 'N'

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
 
/*ASSIGN HOLD CODES */     
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
           begin
           select @msg = 'Cannot assign retainage hold code to non-retainage paytype lines.', @rcode = 1
           goto bspexit
           end
		end

		  -- if retainage hold code selected, warn if there are non retainage lines
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
  			   and ((charindex(',' + isnull(convert(varchar(10),d.PayType), '') + ',', @PayTypeList) > 0) or @PayTypeList is null))  -- #23061
		   select @msg = 'Hold Code is for retainage only and cannot be applied to any non-retainage paytype lines.', @rcode = 5
     end


	  /* SPIN THROUGH VENDORS TO ASSIGN OR RELEASE FOR VENDORS BY JOB, VENDOR SELECTED OR ALL VENDORS */
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
  		fetch next from bcAPVM into @vendkey
  		if @@fetch_status <> 0 goto bspexit

  		declare bcAPDetail cursor LOCAL FAST_FORWARD	
			for select d.Mth, d.APTrans, d.APLine, d.APSeq, d.PayType,
   			d.Amount, d.DiscOffer, d.DiscTaken, d.DueDate, d.Status, d.PaidMth,
   			d.PaidDate, d.CMCo, d.CMAcct, d.PayMethod, d.CMRef, d.CMRefSeq,
   			d.EFTSeq, d.VendorGroup, d.Supplier,d.PayCategory
			from bAPTH h WITH (NOLOCK)
			JOIN bAPTL l WITH (NOLOCK) on h.APCo=l.APCo and h.Mth=l.Mth and h.APTrans=l.APTrans 
			JOIN bAPTD d WITH (NOLOCK) on l.APCo=d.APCo and l.Mth=d.Mth and l.APTrans=d.APTrans 
				and l.APLine=d.APLine
   			where h.APCo=@apco and h.VendorGroup=@vendgrp and h.Vendor=@vendkey 

   			and h.InUseBatchId is null and isnull(l.JCCo,0)=isnull(isnull(@jcco,l.JCCo),0)
   			and isnull(l.Job,'')=isnull(isnull(@job,l.Job),'')
			and isnull(l.PhaseGroup,0)=isnull(isnull(@phasegroup,l.PhaseGroup),0)
			and ((charindex(',' + rtrim(l.Phase) + ',', isnull(@PhaseList, '')) > 0) or @PhaseList is null)   --#23061
			and d.CMRef is null
   			and ((charindex(',' + isnull(convert(varchar(10),d.PayType), '') + ',', isnull(@PayTypeList, '')) > 0) or @PayTypeList is null)
    			and d.Mth=isnull(@fmth,d.Mth) and d.APTrans=isnull(@ftrans,d.APTrans)
   			and d.APLine=isnull(@fline,d.APLine) and d.APSeq=isnull(@fseq,d.APSeq)
				and ((d.PayCategory is null and d.PayType=isnull(@retonlytype,d.PayType))
					or (d.PayCategory is not null and @retonlytype is not null and 
				 		d.PayType=(select RetPayType from bAPPC with (nolock)
				 		where APCo=@apco and PayCategory=d.PayCategory))
					or (d.PayCategory is not null and @retonlytype is null))
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
							begin
							select @count = @count + 1
							end
 					end
  				END
 
	/* RELEASE HOLD CODES */
	IF @aropt='R'  
	BEGIN
	--BEGIN TRANSACTION
		-- Update transaction detail GST tax amounts if Apply New Tax Rates flag is checked.
		IF @ApplyNewTaxRate='Y'
		BEGIN
			--update GST, PST and Total tax in APTD
			UPDATE dbo.bAPTD SET OldGSTtaxAmt=d.GSTtaxAmt, OldPSTtaxAmt=d.PSTtaxAmt,
				 GSTtaxAmt = ((d.Amount - d.TotTaxAmount) * t.TaxRate),
				 PSTtaxAmt = ((d.Amount - d.TotTaxAmount) * t.PSTRate),
				 TotTaxAmount = ((d.Amount - d.TotTaxAmount) * t.TaxRate) + ((d.Amount - d.TotTaxAmount) * t.PSTRate)
			from dbo.bAPTD d
			JOIN dbo.bAPTL l on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine 
			CROSS APPLY (SELECT TaxRate,PSTRate FROM dbo.vfHQTaxRatesForPSTGST(l.TaxGroup, l.TaxCode)) t 
			WHERE d.APCo=@apco and d.Mth=@fmth and d.APTrans=@ftrans and d.APLine=ISNULL(@fline,d.APLine) and d.APSeq= ISNULL(@fseq,d.APSeq)
				--AND	(d.GSTtaxAmt <> 0 and d.OldGSTtaxAmt = 0) OR (d.PSTtaxAmt <> 0 and d.OldPSTtaxAmt = 0)
				AND ((d.PayCategory is null and d.PayType=@aprettype) 
					OR (d.PayCategory is not null and d.PayType = (select RetPayType from bAPPC with (nolock) 
						WHERE APCo=@apco and PayCategory=d.PayCategory))) 
						
		
			-- now update Amount in APTD
			UPDATE dbo.bAPTD SET Amount = ((d.Amount - (d.OldGSTtaxAmt + d.OldPSTtaxAmt)) + (d.GSTtaxAmt + d.PSTtaxAmt))
			FROM dbo.bAPTD d
			WHERE d.APCo=@apco and d.Mth=@fmth and d.APTrans=@ftrans and d.APLine=ISNULL(@fline,d.APLine) and d.APSeq=ISNULL(@fseq,d.APSeq)
				--AND	(d.GSTtaxAmt <> 0 and d.OldGSTtaxAmt <> 0) OR (d.PSTtaxAmt <> 0 and d.OldPSTtaxAmt <> 0)
				AND ((d.PayCategory is null and d.PayType=@aprettype) 
					OR (d.PayCategory is not null and d.PayType = (select RetPayType from bAPPC with (nolock) 
						WHERE APCo=@apco and PayCategory=d.PayCategory))) 
						
			-- btAPTDu update trigger updates bAPWD Amount.
			
		END
		-- release only for APAddtlPayControlDet form. 
		IF EXISTS(
					SELECT * 
					FROM dbo.bAPHD 
					WHERE APCo=@apco and Mth=@fmth and APTrans=@ftrans
						AND APLine=ISNULL(@fline,APLine) and APSeq=ISNULL(@fseq,APSeq)
						AND HoldCode=@holdcode
				)
		BEGIN
			DELETE dbo.bAPHD
			WHERE APCo=@apco and Mth=@fmth and APTrans=@ftrans
				AND APLine=ISNULL(@fline,APLine) and APSeq=ISNULL(@fseq,APSeq)
				AND HoldCode=@holdcode
			 IF @@ROWCOUNT = 0
			 BEGIN
				SELECT @msg = 'Could not delete hold detail.',
				@rcode = 1
				--ROLLBACK TRANSACTION
			END
			ELSE
			BEGIN
				SELECT @count = @count + 1
			END
		END	
	--COMMIT TRANSACTION
	END -- end release

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
GRANT EXECUTE ON  [dbo].[vspAPAssignReleaseHoldCode] TO [public]
GO
