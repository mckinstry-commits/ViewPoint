SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  procedure [dbo].[vspSLUpdateAPUnapp]
/******************************************************
* CREATED BY:	MH 1/16/2008 
* MODIFIED By:	MV 2/12/08 - check for Reviewer on each line
*               MV 06/23/08 - #128715 - threshold reviewers
*				DC 07/23/08 - #128435 - SL Taxes added to SL Update to AP Unapp
*				DC 09/10/08 - #129737 - Can't insert null into phase error when validating AP batch.
*				DC 10/20/08 - #130511 - SL WORKSHEET ATTACHMENT WHEN UPDATING TO AP INTERFERES W/JOB SEC
*				DC 11/20/08 - #129253 - Sequence # exists in AP Unapproved Invoice Review History
*				TJL 02/23/09 - #129889 - SL Claims and Certifications.  Update SL Worksheet History
*				DC  07/07/09 - #133846 - Use tax included in AP invoice total
*				DC 01/20/10  - #136187 - Separate payment flag and 1099 info not updating from SL worksheet to AP
*				MV 02/04/10 - #136500 - bspHQTaxRateGetAll added NULL output param.
*				MV 02/11/10 - #136500 - calculate taxbasis based on APCO TaxbasisNetRetg flag
*				GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
*				MV 10/25/11 - TK-09143 - bspHQTaxRateGetAll added NULL output param.
*				GF 02/29/2012 TK-12905 #140843 need to write out originator to APUL
*				MV 03/01/2012 TK-12855 - Calculate bAPUI Invoice Total per country specific requirements
*				CHS	04/19/2012 - TK-14207 - added Pay Method for Credit Services
*				GF 10/02/2012 TK-18300 input parameters added for vendor sort name range
*				GF 11/13/2012 TK-19330 SL Claim Cleanup Changed how ud columns are updated
*
*
* Usage:	Called from SLUpdateAPUnapp 
*	
*
* Input params:
*	    @co			SL/AP Co#
*   	@mth		Batch Month
*   	@batchid	Batch Id#
*   	@begjcco	Beginning JC Co#
*	    @endjcco	Ending JC Co#
*   	@begjob		Beginning Job
*	    @endjob		Ending Job to select a range to subcontracts from the worksheet
*		@paycategory pay category
*		@slpaytype	 payment type
*		@username	 user name
*		@beginvendorsortname	begin vendor sort name or null
*		@endvendorsortname		end vendor sort name or NULL
*	
*	
*
* Output params:
*	@msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/
(@co bCompany, @uimth bMonth, @begjcco bCompany = null, @endjcco bCompany = null, @begjob bJob = null,
@endjob bJob = null, @paycategory int = null, @slpaytype tinyint = null, @username bVPUserName = null,
----TK-18300
@BeginVendorName bSortName = NULL, @EndVendorName bSortName = NULL,
@numrows int output, @msg varchar(200) output)

as 
set nocount on

declare @sl VARCHAR(30), @rcode int, @uiseq int, @slwhopencursor tinyint, @paytype tinyint, @uniqueattchid uniqueidentifier,
@payterms bPayTerms, @eft char(1), @paymethod char(1), @invdate bDate, @v1099yn bYN, @v1099type varchar(10), @v1099box tinyint, 
@discdate bDate, @calcduedate bDate, @discrate bRate, @slwiopencursor tinyint, @slitem int, @apline int, @phasegroup bGroup,
@phase bPhase, @um bUM, @jcco bCompany, @purchased bDollar, @glcostoveride bYN, @wcunits bUnits, @sm bDollar, @curunitcost bUnitCost,
@installed bDollar, @prevwcunits bUnits, @prevwccost bDollar, @wccost bDollar, @wcretamt bDollar, @prevsm bDollar,
@smretamt bDollar, @linedesc bItemDesc, -- bDesc, DC #135813
@job bJob, @suppliervendgroup bGroup, @supplier bVendor, @jcctype bJCCType, @glco bCompany,
@slglacct bGLAcct, @jcglacct bGLAcct, @invtotal bDollar, @SLWHjobco int, @SLWHjob bJob, @reviewergroup varchar(10),
@taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @taxrate bRate,  -- DC #128435
@totaltax bDollar,@taxamt bDollar,  --DC #128435
@slusername bVPUserName,		--#129889
@SeparatePayInvYN bYN, --DC #136187
@APCOTaxbasisNetRetgYN bYN, @taxbasis bDollar, --MV 136500
@HQCoDefaultCountry char(3), @TotalRetgAmt bDollar, -- MV TK-12855
@VendorPaymethod char(1), @ApcoCsCmAcct bCMAcct -- CHS TK-14207 
----TK-19330
,@APUI_UDFlag CHAR(1), @APUL_UDFlag CHAR(1), @ErrMsg VARCHAR(255)
,@SLWH_APUI_Update VARCHAR(4000), @SLWI_APUL_Update VARCHAR(4000)
,@SLWH_KeyId BIGINT, @SLWI_KeyId BIGINT, @APUI_KeyId BIGINT, @APUL_KeyId BIGINT
,@SLWI_Notes VARCHAR(MAX), @SL_AP_SQL VARCHAR(4000)

select @rcode = 0, @uiseq = 0, @numrows = 0

if @endjcco is null select @endjcco=255
if @begjcco is null select @begjcco = 0

/* set open cursor flag to false */
select @slwhopencursor = 0, @rcode = 0

----TK-19330
---- call dbo.vspSLWorksheetUDUpdateBuild to create update statement
---- pass in source and destination. Remember to use views only.
---- SLWH - APUI ud columns
SET @APUI_UDFlag = 'N'
exec @rcode = dbo.vspSLWorksheetUDUpdateBuild 'SLWH', 'APUI',
				@APUI_UDFlag OUTPUT, @SLWH_APUI_Update OUTPUT, @ErrMsg OUTPUT
if @rcode <> 0 SET @APUI_UDFlag = 'N'

---- SLWI - APUL ud columns
SET @APUL_UDFlag = 'N'
exec @rcode = dbo.vspSLWorksheetUDUpdateBuild 'SLWI', 'APUL',
				@APUL_UDFlag OUTPUT, @SLWI_APUL_Update OUTPUT, @ErrMsg OUTPUT
if @rcode <> 0 SET @APUL_UDFlag = 'N'



if @slpaytype is null
	begin
	select @paytype = SubPayType from dbo.APCO (nolock) where APCo = @co
	end
else
	begin
	select @paytype = @slpaytype
	end

-- get APCO TaxBasisNetRetgYN flag
select @APCOTaxbasisNetRetgYN = TaxBasisNetRetgYN, @ApcoCsCmAcct = CSCMAcct from APCO with (nolock) where APCo = @co
-- Get HQCO default country
SELECT @HQCoDefaultCountry = DefaultCountry
FROM dbo.HQCO
WHERE HQCo=@co

declare vcSLWH cursor local fast_forward for
select h.SL, h.UniqueAttchID, h.JCCo, h.Job, 
		h.InvDate, h.UserName
		----TK-19330
		,h.KeyID
from dbo.SLWH h (nolock)
join dbo.SLHD d (nolock) on d.SLCo=h.SLCo and d.SL=h.SL
----TK-18300
JOIN APVM ON APVM.VendorGroup=h.VendorGroup AND APVM.Vendor=h.Vendor
where h.JCCo>=@begjcco and h.JCCo<=@endjcco and 
	h.Job>=isnull(@begjob,h.Job) and h.Job<=isnull(@endjob,h.Job)
	and h.ReadyYN='Y' and d.InUseMth is null and (@username is null or (h.UserName = @username))
	and h.SLCo=@co  
	----TK-18300
	AND APVM.SortName >= ISNULL(@BeginVendorName, APVM.SortName)
	AND APVM.SortName <= ISNULL(@EndVendorName, APVM.SortName)
	
open vcSLWH
select @slwhopencursor = 1

Next_SLWH:
fetch next from vcSLWH into @sl, @uniqueattchid, @SLWHjobco, @SLWHjob, 
		@invdate, @slusername
		----TK-19330
		,@SLWH_KeyId

while (@@fetch_status = 0)
	begin
		select @totaltax = 0  --DC #128435
		SELECT @TotalRetgAmt = 0 --TK-12855

		if @payterms is not null
			begin
			exec @rcode = bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @calcduedate output,
			@discrate output, @msg output

			select @msg = isnull(@msg,'') + ' - SL:' + @sl

			if @rcode=1 goto vspexit
			end


		select @eft = m.EFT, @v1099yn = m.V1099YN, @v1099type = m.V1099Type, @v1099box = m.V1099Box,
     			@SeparatePayInvYN = SeparatePayInvYN,  --DC #136187
     			@VendorPaymethod = PayMethod	-- CHS TK-14207
		from dbo.APVM m(nolock) 
		join SLWH h (nolock) on m.VendorGroup = h.VendorGroup and m.Vendor = h.Vendor
		where h.SLCo = @co and h.SL = @sl

			-- CHS TK-14207
			IF @VendorPaymethod = 'S'
				BEGIN
				SELECT @paymethod='S', @SeparatePayInvYN = 'N'
				END

     		ELSE IF @eft='A'
				BEGIN
				SELECT @paymethod='E'
				END
				
			ELSE
				BEGIN
				SELECT @paymethod='C'
				END

		--make sure Job has at least one reviewer on it.  If not, skip this Job, return rcode 7 
		if not exists (select * from vHQRD d join bJCJM j on d.ReviewerGroup=j.RevGrpInv where j.JCCo=@SLWHjobco and j.Job=@SLWHjob )
			begin
			if not exists(select * from bJCJR with (nolock) where JCCo=@SLWHjobco and Job=@SLWHjob and ReviewerType in (1,3))
				begin
				select @rcode=7 --return successconditional for reviewer message.
				goto Next_SLWH
				end
			end
		else
			begin
			select @reviewergroup = RevGrpInv from bJCJM with (nolock) where JCCo=@SLWHjobco and Job=@SLWHjob
			end

		--Create Header

		-- Invoice Total is the sum of Work Completed plus Stored Materials
		select @invtotal=isnull(sum(WCCost),0) + isnull(sum(Purchased),0) - isnull(sum(Installed),0)
		from SLWI where SLCo = @co and SL = @sl

		--DC #129253
		--Get next UISeq
		exec @rcode = vspAPUIGetNextSeq @co, @uimth, @uiseq output, @msg output								
		--select @uiseq = (select isnull(max(UISeq),0) from dbo.APUI (nolock) where APCo = @co and UIMth = @uimth) + 1  --DC #129253

		--Check if header already exists.
		if not exists(select 1 from dbo.APUI (nolock) where APCo = @co and UIMth = @uimth and UISeq = @uiseq)
			begin
			insert dbo.APUI(APCo, UIMth, UISeq, VendorGroup, Vendor, InvTotal, CMCo, 
				V1099YN, SeparatePayYN, V1099Type, V1099Box, --DC #136187
				PayOverrideYN, PayControl, PayMethod, APRef, [Description], InvDate, DueDate,
				CMAcct, HoldCode, UniqueAttchID, Notes)
			select @co, @uimth, @uiseq, h.VendorGroup, h.Vendor, @invtotal, h.CMCo, 
				@v1099yn, @SeparatePayInvYN, @v1099type, @v1099box, --DC #136187
				'N', h.PayControl, @paymethod, h.APRef, h.InvDescription, h.InvDate, h.DueDate, 
				(CASE WHEN @paymethod = 'S' THEN @ApcoCsCmAcct ELSE h.CMAcct END),
				h.HoldCode, h.UniqueAttchID, convert(varchar(2000), h.Notes)
			from dbo.SLWH h (nolock)
			where h.SLCo = @co and h.SL = @sl	

			---- get APUI key id
			SET @APUI_KeyId = SCOPE_IDENTITY()

			select @numrows = @numrows + 1

			---- TK-19330 update UD fields
			IF @APUI_UDFlag = 'Y'
				BEGIN
				SELECT @SL_AP_SQL = @SLWH_APUI_Update
									+ ' WHERE SLWH.KeyID = ' + dbo.vfToString(@SLWH_KeyId)
									+ ' AND APUI.KeyID = ' + dbo.vfToString(@APUI_KeyId) 
				EXEC (@SL_AP_SQL)
				END
            	
			END

		if @uniqueattchid is not null
			begin
			update bHQAT	-- update Attachments  DC #130511
			set TableName = 'APUI', FormName = 'APUnappInv'
			where UniqueAttchID = @uniqueattchid

			exec dbo.bspHQRefreshIndexes null, null, @uniqueattchid, null   
			end

		--Create Detail
		declare vcSLWI cursor local fast_forward for
		select w.SLItem, w.PhaseGroup, w.Phase, w.UM, w.CurUnitCost,
			w.PrevWCUnits, w.PrevWCCost, w.WCUnits, w.WCCost, w.WCRetAmt, w.PrevSM,
			w.Purchased, w.Installed, w.SMRetAmt, w.LineDesc, w.VendorGroup, w.Supplier,
			i.JCCo, i.Job, i.JCCType, i.GLCo, i.GLAcct,
			i.TaxGroup, i.TaxType, i.TaxCode
			----TK-19330
			,w.KeyID
		from SLWI w join SLIT i on i.SLCo=w.SLCo and i.SL=w.SL and i.SLItem=w.SLItem
		where w.SLCo = @co and w.SL = @sl

		open vcSLWI
		select @slwiopencursor = 1

		fetch next from vcSLWI into @slitem, @phasegroup, @phase, @um, @curunitcost,
			@prevwcunits, @prevwccost, @wcunits, @wccost, @wcretamt, @prevsm,
			@purchased, @installed, @smretamt, @linedesc, @suppliervendgroup, @supplier,
			@jcco, @job, @jcctype, @glco, @slglacct,
			@taxgroup, @taxtype, @taxcode
			----TK-19330
			,@SLWI_KeyId

		select @apline = 0

		while @@fetch_status = 0
		begin

			select @taxamt = 0
			select @sm = @purchased - @installed	--  Stored Materials This Invoice


			-- DC  #128435
			-- need to calculate orig tax for existing item when tax code was null now not null
			if isnull(@taxcode,'') <> ''			
				begin
				exec @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, @invdate, null, @taxrate output, null, null, 
					null, null, null, null, null, 
					null, NULL, NULL, @msg output
				end /* tax code validation*/

			/*20991 - insert SL or JC GLAcct based on GLCostOverride */
			-- get jcglacct
			exec @rcode = bspJCCAGlacctDflt @jcco, @job, @phasegroup, @phase, @jcctype, 'N',
				@jcglacct output, @msg output

			if @rcode = 1
				begin
				select @msg = isnull(@msg,'') + ' - SL:' + @sl + ' Item: ' + convert(varchar(4),@slitem)
				goto vspexit
				end				

			-- get cost override flag
			select @glcostoveride=GLCostOveride from JCCO where JCCo= @jcco 

			---- TK-19330 get slwi notes
			SELECT @SLWI_Notes = Notes
			from dbo.SLWI
			WHERE KeyID = @SLWI_KeyId


			if @wcunits<>0 or @wccost<>0 or @wcretamt<>0
			begin
				--DC #128435
				IF ISNULL(@taxcode,'') <> ''
				BEGIN
					IF @HQCoDefaultCountry <> 'US' -- TK-12855
					BEGIN
						-- caclulate taxbasis for international
						IF ISNULL(@APCOTaxbasisNetRetgYN,'N') = 'N'
						BEGIN
							SELECT @taxbasis = @wccost
						END
						ELSE
						BEGIN
							SELECT @taxbasis = @wccost - @wcretamt
						END
					END
					ELSE
					BEGIN -- calculate taxbasis for US
						SELECT @taxbasis = @wccost 
					END
					
					SELECT @taxamt = @taxbasis*@taxrate	--@wccost*@taxrate
					--DC #133846
					IF @taxtype <> 2 
					BEGIN
						SELECT @totaltax = @totaltax + @taxamt
					END	
				END					
								
				-- Accumulate Retg Amt -- TK-12855
				SELECT @TotalRetgAmt = @TotalRetgAmt + ISNULL(@wcretamt,0)			

				--Need to get line 
				select @apline = isnull(max(Line),0) + 1 from APUL where APCo = @co and UIMth = @uimth and
				UISeq = @uiseq

				begin transaction

				insert APUL(APCo, Line, UIMth, UISeq, LineType, SL, SLItem, JCCo, Job,PhaseGroup, Phase, JCCType,
					GLCo, GLAcct, [Description], UM, Units, UnitCost, ECM, VendorGroup, Supplier, PayCategory,PayType, GrossAmt, 
					MiscAmt, MiscYN,TaxBasis, 
					TaxAmt, Retainage, Discount, ReviewerGroup,
					----TK-12905
					InvOriginator, TaxGroup, TaxType, TaxCode
					----TK-19330
					,Notes)
				values(@co, @apline, @uimth, @uiseq, 7, @sl, @slitem, @jcco, @job, @phasegroup, @phase, @jcctype,
					@glco, case @glcostoveride when 'Y' then @slglacct else case when @jcglacct is null then 
					@slglacct else @jcglacct end end,convert(varchar(30),@linedesc), @um, @wcunits, @curunitcost, 
					case @um when 'LS' then null else 'E' end, @suppliervendgroup, @supplier,@paycategory,@paytype, @wccost, 
					0, 'Y', case isnull(@taxcode,'') when '' then 0 else @taxbasis /*@wccost*/ end,  --DC #129737, 
					@taxamt, @wcretamt, 0, @reviewergroup,
					----TK-12905
					@slusername, @taxgroup, @taxtype, @taxcode
					----TK-19330
					,@SLWI_Notes)
                    
                ---- TK-19330 get APUL key id
				SET @APUL_KeyId = SCOPE_IDENTITY()

				---- TK-19330 update UD fields
				IF @APUL_UDFlag = 'Y'
					BEGIN
					SELECT @SL_AP_SQL = @SLWI_APUL_Update
										+ ' WHERE SLWI.KeyID = ' + dbo.vfToString(@SLWI_KeyId)
										+ ' AND APUL.KeyID = ' + dbo.vfToString(@APUL_KeyId) 
					EXEC (@SL_AP_SQL)
					END

				commit transaction

			END		

			if @sm <> 0 or @smretamt <> 0
				begin
				--DC #128435
				if isnull(@taxcode,'')<> ''
					BEGIN
					IF @HQCoDefaultCountry <> 'US' -- TK-12855
					BEGIN
						-- caclulate taxbasis for international
						IF ISNULL(@APCOTaxbasisNetRetgYN,'N') = 'N'
						BEGIN
							SELECT @taxbasis = @sm
						END
						ELSE
						BEGIN
							SELECT @taxbasis = @sm - @smretamt
						END
					END
					ELSE
					BEGIN -- calculate taxbasis for US
						SELECT @taxbasis = @sm 
					END
					
					SELECT @taxamt = @taxbasis*@taxrate	--@wccost*@taxrate
					--DC #133846
					IF @taxtype <> 2 
					BEGIN
						SELECT @totaltax = @totaltax + @taxamt
					END						
					END	
										
				-- Accumulate Retg Amt -- TK-12855
				SELECT @TotalRetgAmt = @TotalRetgAmt + ISNULL(@smretamt,0)			

				--Need to get line 
				select @apline = isnull(max(Line),0) + 1 from APUL where APCo = @co and UIMth = @uimth and
				UISeq = @uiseq

				--How do I know this line has already been sent?
				begin TRANSACTION
                
				insert APUL(APCo, Line, UIMth, UISeq, LineType, 
					SL, SLItem, JCCo, Job, PhaseGroup, 
					Phase, JCCType, GLCo, GLAcct, [Description], 
					UM, Units, UnitCost, VendorGroup, Supplier, 
					PayCategory, PayType, GrossAmt, MiscYN, MiscAmt, 
					Retainage, Discount, TaxAmt, TaxBasis, 
					ReviewerGroup, 
					----TK-12905
					InvOriginator, TaxGroup, TaxType, TaxCode
					,Notes)
				values(@co, @apline, @uimth, @uiseq, 7, 
					@sl, @slitem, @jcco, @job, @phasegroup, 
					@phase, @jcctype, @glco, case @glcostoveride when 'Y' then @slglacct else case when @jcglacct is null then @slglacct else @jcglacct end end, 'Stored Materials for Item ' + convert(varchar (4),@slitem), 
					'LS', 0, 0, @suppliervendgroup, @supplier, 
					@paycategory, @paytype, @sm, 'Y', 0, 
					@smretamt, 0, @taxamt, case isnull(@taxcode,'') when '' then 0 else @taxbasis /*@sm*/ end,  --DC #129737, 
					@reviewergroup, 
					----TK-12905
					@slusername, @taxgroup, @taxtype, @taxcode
					----TK-19330
					,@SLWI_Notes)


                    ---- TK-19330 get APUL key id
					SET @APUL_KeyId = SCOPE_IDENTITY()

					---- TK-19330 update UD fields
					IF @APUL_UDFlag = 'Y'
						BEGIN
						SELECT @SL_AP_SQL = @SLWI_APUL_Update
											+ ' WHERE SLWI.KeyID = ' + dbo.vfToString(@SLWI_KeyId)
											+ ' AND APUL.KeyID = ' + dbo.vfToString(@APUL_KeyId) 
						EXEC (@SL_AP_SQL)
						END

					COMMIT transaction
				END


			/* Write SL Worksheet item to history table prior to deleting from worksheet. */
			exec @rcode = vspSLUpdateSLWIHist @co, @slusername, @sl, @slitem, @msg output
			if @rcode = 1
				begin
				select @msg = 'VPUserName: ' + @slusername + ', SubContract: ' + @sl + ', SLItem: ' + convert(varchar, @slitem) +' - ' + isnull(@msg, '')
				goto vspexit 
				end

			/* History has been recorded, delete worksheet item. */
			delete from SLWI where SLCo = @co and UserName = @slusername and SL = @sl and SLItem = @slitem

			fetch next from vcSLWI into @slitem, @phasegroup, @phase, @um, @curunitcost,
				@prevwcunits, @prevwccost, @wcunits, @wccost, @wcretamt, @prevsm,
				@purchased, @installed, @smretamt, @linedesc, @suppliervendgroup, @supplier,
				@jcco, @job, @jcctype, @glco, @slglacct,
				@taxgroup, @taxtype, @taxcode
				----TK-19330
				,@SLWI_KeyId

		end

		if @slwiopencursor = 1
			begin
			close vcSLWI
			deallocate vcSLWI
			end

        -- add threshold reviewers for this UISeq
        exec vspAPUnappThresholdReviewers @co, @uimth, @uiseq

		/* Write SL Worksheet header to history table prior to deleting from worksheet. */
		exec @rcode = vspSLUpdateSLWHHist @co, @slusername, @sl, @msg output
		if @rcode = 1
			begin
			select @msg = 'VPUserName: ' + @slusername + ', SubContract: ' + @sl + ' - ' + isnull(@msg, '')
			goto vspexit 
			end

		delete SLWH where SLCo = @co and UserName = @slusername and SL = @sl

		-- Update Invoice Total in APUI header for US and International -- TK-12855
		IF @HQCoDefaultCountry <> 'US'
		BEGIN --Update Invoice total in APHB for international
			IF ISNULL(@APCOTaxbasisNetRetgYN,'N') = 'Y'
			BEGIN
				UPDATE dbo.bAPUI
				SET InvTotal = InvTotal - ISNULL(@TotalRetgAmt,0) + ISNULL(@totaltax,0)
				WHERE APCo = @co and UIMth = @uimth and UISeq = @uiseq
			END
			ELSE
			BEGIN
				UPDATE dbo.bAPUI
				SET InvTotal = InvTotal + ISNULL(@totaltax,0) - ISNULL(@TotalRetgAmt,0) 
				WHERE APCo = @co and UIMth = @uimth and UISeq = @uiseq
			END
		END
		ELSE
		BEGIN -- Update Invoice total in APHB for US
			--DC #128435
			UPDATE dbo.bAPUI
			SET InvTotal = InvTotal + isnull(@totaltax,0)
			WHERE APCo = @co and UIMth = @uimth and UISeq = @uiseq
		END

		goto Next_SLWH

	end

	if @slwhopencursor = 1
		begin
		close vcSLWH
		DEALLOCATE vcSLWH	
		end
			
	vspexit:

	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspSLUpdateAPUnapp] TO [public]
GO
