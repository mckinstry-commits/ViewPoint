SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspIMProcessReleaseRetgAP   Script Date:  ******/
CREATE procedure [dbo].[vspIMProcessReleaseRetgAP]    
/********************************************************************
* CREATED BY: TJL 09/01/09 - Issue #135341, Import AP Entry transactions from Textura
* MODIFIED BY:   DC 6/29/10 - #135813 - expand subcontract number
*				ECV 05/25/11 - TK-05443 - Add SMPayType parameter to bspAPPayTypeGet
*
* USE:
*	This procedure is called from the import upload routine "bspIMUploadHeaderDetail" when import records
*	have been flagged as "Release Retainage" records.  The imported Release Retainage amount will get
*	distributed to AP Invoices (Retainage APTD records will get taken of 'Hold' status), starting with 
*	the earliest invoice and working forward until the Release amount has been fully distributed.
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0   success
*   1   fail
*******************************************************************/
(@apco bCompany, @linetype tinyint, @sl VARCHAR(30) = NULL, --bSL = null, DC #135813
	@slitem bItem = null, @jcco bCompany = null, @job bJob = null,
	@phasegroup bGroup = null, @phase bPhase = null, @totalreleaseamt bDollar = 0, @distributetax bYN = 'N', 
	@vendorgroup bGroup = null, @vendor bVendor = null, @errorid tinyint output, @errmsg varchar(255) output)

as
set nocount on
    
declare @rcode tinyint, @openAPTDcursor tinyint, @relamtleft bDollar, @totalretgamt bDollar, @invretgamt bDollar

/* Variables relative to procedure "bspAPPayTypeGet" for returning PayType. */
declare @retpaytype int, @paycategory int
  
/* Variables relative to procedure "bspAPProcessPartialPayments" for Releasing Retainage. */
declare  @mth bMonth, @aptrans bTrans, @apline smallint, @apseq tinyint, @releaseamt bDollar

select @rcode=0, @openAPTDcursor = 0, @relamtleft = @totalreleaseamt, @releaseamt = 0, @invretgamt = 0, @totalretgamt = 0

/* Input Validation*/
if @apco is null or @apco = 0		--@apco = 0 required: When value removed from Work Edit, tinyint empty string is replaced with 0.	
	begin
	select @errmsg = 'Missing AP Company.', @errorid = 0, @rcode = 1
	goto vspexit
	end
if @linetype is null 	
	begin
	select @errmsg = 'Missing AP Line Type.', @errorid = 2, @rcode = 1
	goto vspexit
	end
if @linetype = 7
	begin 
	if @sl is null
		begin
		select @errmsg = 'SubContract is missing.', @errorid = 3, @rcode = 1
		goto vspexit
		end
	else
		begin
		if not exists(select 1 from bSLHD with (nolock) where SLCo = @apco and SL = @sl)
			begin
			select @errmsg = 'Not a valid SubContract.', @errorid = 3, @rcode = 1
			goto vspexit
			end
		else
			begin
			if @slitem is null
				begin
				select @errmsg = 'SubContract Item is missing.', @errorid = 4, @rcode = 1
				goto vspexit
				end
			else
				begin
				if not exists(select 1 from bSLIT with (nolock) where SLCo = @apco and SL = @sl
					and SLItem = @slitem)
					begin
					select @errmsg = 'Not a valid SubContract Item.', @errorid = 4, @rcode = 1
					goto vspexit
					end
				end
			end
		end
	end
if @linetype = 1 
	begin
	if @jcco is null	
		begin
		select @errmsg = 'Job Cost Company is missing.', @errorid = 5, @rcode = 1
		goto vspexit
		end
	else
		begin
		if not exists(select top 1 1 from bJCCO with (nolock) where JCCo = @jcco)
			begin
			select @errmsg = 'Not a valid JC Company.', @errorid = 5, @rcode = 1
			goto vspexit
			end	
		else
			begin
			if @job is null
				begin
				select @errmsg = 'Job is missing.', @errorid = 6, @rcode = 1
				goto vspexit
				end
			else
				begin
				if not exists(select top 1 1 from bJCJM with (nolock) where JCCo = @jcco and Job = @job)
					begin
					select @errmsg = 'Not a valid Job.', @errorid = 6, @rcode = 1
					goto vspexit
					end	
				else
					begin
					if @phasegroup is null
						begin
						select @errmsg = 'Job Phase Group is missing.', @errorid = 7, @rcode = 1
						goto vspexit
						end
					else
						begin
						if not exists(select top 1 1 from bHQCO with (nolock) where HQCo = @jcco and PhaseGroup = @phasegroup)
							begin
							select @errmsg = 'Not a valid PhaseGroup for this Job Cost Company.', @errorid = 7, @rcode = 1
							goto vspexit
							end	
						else
							begin
							if @phase is null
								begin
								select @errmsg = 'Job Phase is missing.', @errorid = 8, @rcode = 1
								goto vspexit
								end	
							else
								begin
								if not exists(select top 1 1 from bJCPM with (nolock) where PhaseGroup = @phasegroup and Phase = @phase)
									begin
									select @errmsg = 'Not a valid Job Phase.', @errorid = 8, @rcode = 1
									goto vspexit
									end									
								end					
							end						
						end				
					end				
				end
			end	
		end
	end	

if @totalreleaseamt = 0
	begin
	goto vspexit
	end

/* Get Pay Type from AP Company setup.  (We will ignore User PayType configuration.) */
exec @rcode = dbo.bspAPPayTypeGet @apco, null, null, null, null, null, @retpaytype output, null,	--SLPayType and JCPayType not needed here.
	null, @paycategory output, @errmsg output

/* Check that there is enough retainage on hold left to release. */
select @totalretgamt = isnull(sum(d.Amount),0)
from bAPTL l with (nolock)
join bAPTH h with (nolock) on h.APCo = l.APCo and h.Mth = l.Mth and h.APTrans = l.APTrans
join bAPTD d with (nolock) on d.APCo = l.APCo and d.Mth = l.Mth and d.APTrans = l.APTrans and d.APLine = l.APLine
where l.APCo = @apco and l.LineType = @linetype and d.PayType = @retpaytype and d.Status = 2
	and h.VendorGroup = @vendorgroup and h.Vendor = @vendor
	and isnull(l.SL, '') = isnull(@sl, isnull(l.SL, '')) and isnull(l.SLItem, -1) = isnull(@slitem, isnull(l.SLItem, -1))
	and isnull(l.JCCo, 0) = isnull(@jcco, isnull(l.JCCo, 0)) and isnull(l.Job, '') = isnull(@job, isnull(l.Job, '')) 
		and isnull(l.PhaseGroup, 0) = isnull(@phasegroup, isnull(l.PhaseGroup, 0)) and isnull(l.Phase, '') = isnull(@phase, isnull(l.Phase, ''))
if @totalretgamt < @totalreleaseamt
	begin
	select @errmsg = 'Amount being released exceeds the amount of retainage withheld on this item.', @errorid = 1, @rcode = 1
	goto vspexit
	end
				
/* Get AP Invoices containing this Line (SLItem or JobPhase/Contract Item) with Retainage still "On Hold" (Not yet released).
   Get Line Retainage Sequence value. */
declare bcAPTD cursor local fast_forward for
select l.Mth, l.APTrans, l.APLine, d.APSeq, d.Amount
from bAPTL l with (nolock)
join bAPTH h with (nolock) on h.APCo = l.APCo and h.Mth = l.Mth and h.APTrans = l.APTrans
join bAPTD d with (nolock) on d.APCo = l.APCo and d.Mth = l.Mth and d.APTrans = l.APTrans and d.APLine = l.APLine
where l.APCo = @apco and l.LineType = @linetype and d.PayType = @retpaytype and d.Status = 2
	and h.VendorGroup = @vendorgroup and h.Vendor = @vendor
	and isnull(l.SL, '') = isnull(@sl, isnull(l.SL, '')) and isnull(l.SLItem, -1) = isnull(@slitem, isnull(l.SLItem, -1))
	and isnull(l.JCCo, 0) = isnull(@jcco, isnull(l.JCCo, 0)) and isnull(l.Job, '') = isnull(@job, isnull(l.Job, '')) 
		and isnull(l.PhaseGroup, 0) = isnull(@phasegroup, isnull(l.PhaseGroup, 0)) and isnull(l.Phase, '') = isnull(@phase, isnull(l.Phase, ''))
group by l.Mth, l.APTrans, l.APLine, d.APSeq, d.Amount
order by l.Mth, l.APTrans, l.APLine, d.APSeq

/* open cursor */
open bcAPTD
select @openAPTDcursor = 1

fetch next from bcAPTD into @mth, @aptrans, @apline, @apseq, @invretgamt
/* Begin cycling through the invoice lines, releasing retainage (removing from Hold status), starting with the earliest invoice
   and working to later invoices until the full release amount has been dispensed. */
while @@fetch_status = 0 
   	begin	/* Begin Invoice Process loop */
  	select @releaseamt = 0 
  	if (@totalreleaseamt > 0 and @invretgamt < 0) or (@totalreleaseamt < 0 and @invretgamt > 0)		--Neg invoice handling
  		begin
  		/* Negative Invoice has been encountered. */
  		select @releaseamt = @invretgamt
		update bAPTD
		set Status = 1
		where APCo = @apco and Mth = @mth and APTrans = @aptrans and APLine = @apline and APSeq = @apseq
		if @@rowcount <> 1
			begin
			select @errmsg = 'Unspecified table Update error.  Releasing of Retainage has failed.', @errorid = 0, @rcode = 1
			goto vspexit
			end
  		end
  	else
  		begin
  		/* Normal Positive Invoices. */
   		if abs(@invretgamt) <= abs(@relamtleft)
   			begin
   			/* Release the entire Retainage amount.  (Set Status = 1 on original retg Line/Seq) */
   			select @releaseamt = @invretgamt
   			update bAPTD
   			set Status = 1
   			where APCo = @apco and Mth = @mth and APTrans = @aptrans and APLine = @apline and APSeq = @apseq
   			if @@rowcount <> 1
   				begin
   				select @errmsg = 'Unspecified table Update error.  Releasing of Retainage has failed.', @errorid = 0, @rcode = 1
   				goto vspexit
   				end
   			end
		else
			begin
			/* Split Line/Seq. Release retainage on a portion. */
			select @releaseamt = @relamtleft
			exec @rcode = dbo.bspAPProcessPartialPayments @apco, @mth, @aptrans, @apline, @apseq, @releaseamt, null, 'N', null,
				'N', null, @distributetax, 'N', @errmsg output
			if @rcode <> 0 
				begin
				select @errorid = 0
				goto vspexit
				end
			end
		end
		
	select @relamtleft = @relamtleft - @releaseamt
	if @relamtleft = 0 goto vspexit
	
	fetch next from bcAPTD into @mth, @aptrans, @apline, @apseq, @invretgamt
	end		/* End Invoice Process loop */

vspexit:

if @openAPTDcursor = 1
	begin
	close bcAPTD
	deallocate bcAPTD
	select @openAPTDcursor = 0
	end
	
return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspIMProcessReleaseRetgAP] TO [public]
GO
