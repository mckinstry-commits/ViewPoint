SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLUpdateAP    Script Date: 8/28/99 9:36:37 AM ******/
CREATE proc [dbo].[bspSLUpdateAP]
/***********************************************************
* CREATED BY: kf 9/1/97
* MODIFIED By : kb 02/4/99
*               GG 05/15/00 - removed updates to bSLIT, will be done when AP batch is posted in bspAPHBPost
*               GG 07/18/00 - fixed invoice total updated to bAPTH, removed PrevSM
*               GR 10/26/00 - added code to insert attachments in APEntry batch issue #11133
*               GG 11/27/00 - changed datatype from bAPRef to bAPReference
*               kb 2/8/2 - issue #14779
*				  RM 02/22/02 - Updated for changed in attachments.
*                kb 5/14/2 - issue #14779
*                kb 5/22/2 - issue #17311
*                kb 8/5/2 - issue #18174
*				mv 04/17/03 - #20991 - insert SL or JC GLAcct based on GLCostOverride
*				RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
*				MV 03/03/04 - #18769 - Pay Category
*				ES 03/16/04 = #23821 Added Notes
*				MV 03/30/04 - #18769 - post demo pay category changes
*				MV 08/05/04 - #25317 - insert pay category value into stored material AP lines.
*				MV 09/22/04 - #25406 - update notes to both WC and SM lines
*				MV 09/23/04 - #25470 - fix code that updates UniqueAttachID to bAPHB
*				MV 10/13/04 - #25606 - Stored Materials description in bAPLB
*				MV 12/14/04 - #26364 - add SLCo to where clause in SLWH cursor select
*				MV 04/28/05 - #28574 - don't restrict notes update by username
*			DC  08/01/07 - #123030 - Creating header only transactions for wrong company
*			DC  01/30/08 - #30175 - Allow UD fields in SLWH to update AP
*			DC  07/16/08 - #128435 - Add Taxes to SL 
*			DC  09/10/08 - #129737 - Can't insert null into phase error when validating AP batch.
*			TJL 02/23/09 - #129889 - SL Claims and Certifications.  Update SL Worksheet History
*			DC 07/07/09 - #133846 - Use tax included in AP invoice total
*			DC 01/20/10 - #136187 - Separate payment flag and 1099 info not updating from SL worksheet to AP
*			MV 02/04/10 - #136500 - bspHQTaxRateGetAll added NULL output param
*			TJL 02/08/10 - #137101 - MARS SQL error due to improper rollback on error, SLItem cursor not reset
*			MV 02/11/10 - #136500 - calculate taxbasis based on APCO TaxbasisNetRetg flag
*			DC 06/25/10 - #135813 - expand subcontract number 
*			MV 10/25/2011 - TK-09243 - bspHQTaxRateGetAll added NULL output param
*			MV 02/27/2012 - TK-12854 - Calculate bAPHB Invoice Total per country specific requirements
*			CHS	04/19/2012 - TK-14206 - added Pay Method for Credit Services
*			GF 10/02/2012 TK-18283 input parameters added for vendor sort name range
*			GF 11/13/2012 TK-19330 SL Claim Cleanup Changed how ud columns are updated
*
*
* USAGE:
* 	Called by the SL Worksheet posting program to create an AP batch
*	of subcontract transactions.  One line is added for Work Complete,
*	and another is added for Stored Materials.
*	Updates Work Completed and Stored Materials back to SL Items.
*
*  INPUT PARAMETERS
*	    @co		SL/AP Co#
*   	@mth		Batch Month
*   	@batchid	Batch Id#
*   	@begjcco	Beginning JC Co#
*	    @endjcco	Ending JC Co#
*   	@begjob		Beginning Job
*	    @endjob		Ending Job to select a range to subcontracts from the worksheet
*		@paycategory pay category
*		@slpaytype	 payment type
*		@username	 user name
*		@BeginVendorName	begin vendor sort name or null
*		@EndVendorName		end vendor sort name or NULL
*
* OUTPUT PARAMETERS
*	    @numrows	# of transactions added to the AP batch
*   	@msg      	error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
***********************************************************/
(@co bCompany,@mth bMonth,@batchid bBatchID,@begjcco bCompany = null,
@endjcco bCompany = null, @begjob bJob = null, @endjob bJob = null,
@paycategory int = null,@slpaytype tinyint = null, @username bVPUserName = null,
----TK-18283
@BeginVendorName bSortName = NULL, @EndVendorName bSortName = NULL,
@numrows int output, @unapprows int output, @msg varchar(256) output)

as

set nocount on

declare @rcode int, @opencursor tinyint, @vendorgroup bGroup, @payterms bPayTerms, @eft char(1),
@paycontrol varchar(10), @vendor bVendor, @sl VARCHAR(30), --bSL, DC #135813
@invdate bDate, @v1099yn bYN, @seq int,
@slwiopencursor tinyint, @phasegroup bGroup, @line smallint, @apref bAPReference, @discdate bDate,
@v1099type varchar(10), @v1099box tinyint,@invdescription bDesc, @phase bPhase, @duedate bDate,
@calcduedate bDate, @um bUM, @cmco bCompany, @curunitcost bUnitCost, @cmacct bCMAcct,
@discrate bRate, @supplier bVendor,@holdcode bHoldCode, @wcunits bUnits, @wccost bDollar,
@wcretamt bDollar, @linedesc bItemDesc, --bDesc, DC #135813
@suppliervendgroup bGroup, @paymethod char(1),
@jcctype bJCCType, @glco bCompany, @slglacct bGLAcct, @slitem bItem, @jcco bCompany, @job bJob,
@paytype tinyint, @invtotal bDollar, @prevsm bDollar, @purchased bDollar, @installed bDollar,
@smretamt bDollar, @sm bDollar, @prevwcunits bUnits, @prevwccost bDollar,@keyfield varchar(255),
@insertkeyfield varchar(255), @slwhjcco bCompany, @slwhjob bJob,@guid uniqueidentifier,@jcglacct bGLAcct,
@glcostoveride bYN, @jobstatus int, @slusername bVPUserName,
@taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @taxrate bRate,  -- DC #128435
@totaltax bDollar,@taxamt bDollar,  --DC #128435
@SeparatePayInvYN bYN,  --DC #136187
@slitemusername bVPUserName,		--TJL 137101
@APCOTaxbasisNetRetgYN bYN, @taxbasis bDollar, --MV 136500
@HQCoDefaultCountry char(3), @TotalRetgAmt bDollar, -- MV TK-12854
@VendorPaymethod char(1), @ApcoCsCmAcct bCMAcct -- CHS TK-14206
----TK-19330
,@APHB_UDFlag CHAR(1), @APLB_UDFlag CHAR(1), @ErrMsg VARCHAR(255)
,@SLWH_APHB_Update VARCHAR(4000), @SLWI_APLB_Update VARCHAR(4000)
,@SLWH_KeyId BIGINT, @SLWI_KeyId BIGINT, @APHB_KeyId BIGINT, @APLB_KeyId BIGINT
,@SLWH_Notes VARCHAR(MAX), @SLWI_Notes VARCHAR(MAX), @SL_AP_SQL VARCHAR(4000)


select @numrows=0, @unapprows= 0 /*Keeps track of how many rows were affected */
if @endjcco is null select @endjcco=255
if @begjcco is null select @begjcco=0

/* set open cursor flag to false */
select @opencursor = 0,@rcode = 0, @TotalRetgAmt = 0

----TK-19330
---- call dbo.vspSLWorksheetUDUpdateBuild to create update statement
---- pass in source and destination. Remember to use views only.
---- SLWH - APHB ud columns
SET @APHB_UDFlag = 'N'
exec @rcode = dbo.vspSLWorksheetUDUpdateBuild 'SLWH', 'APHB',
				@APHB_UDFlag OUTPUT, @SLWH_APHB_Update OUTPUT, @ErrMsg OUTPUT
if @rcode <> 0 SET @APHB_UDFlag = 'N'

---- SLWI - APLB ud columns
SET @APLB_UDFlag = 'N'
exec @rcode = dbo.vspSLWorksheetUDUpdateBuild 'SLWI', 'APLB',
				@APLB_UDFlag OUTPUT, @SLWI_APLB_Update OUTPUT, @ErrMsg OUTPUT
if @rcode <> 0 SET @APLB_UDFlag = 'N'


-- get Subcontract Pay Type
/* #18769 - set paytype */
if @slpaytype is null
	begin
		select @paytype=SubPayType from APCO where APCo=@co
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
   
 -- use a cursor to process Subcontracts in the Worksheet - they must be Ready and not currently in a batch

declare bcSLWH cursor local fast_forward for 
select SLWH.VendorGroup, SLWH.Vendor, SLWH.PayControl, SLWH.APRef,
	SLWH.InvDescription,SLWH.InvDate,SLWH.PayTerms, SLWH.DueDate, SLWH.CMCo, SLWH.CMAcct, SLWH.HoldCode,
	SLWH.SL, SLWH.JCCo, SLWH.Job,SLWH.UniqueAttchID, SLWH.UserName
	----TK-19330
	,SLWH.KeyID
from SLWH 
join SLHD on SLHD.SLCo=SLWH.SLCo and SLHD.SL=SLWH.SL
----TK-18283
JOIN APVM ON APVM.VendorGroup=SLWH.VendorGroup AND APVM.Vendor=SLWH.Vendor
where SLWH.JCCo>=@begjcco and SLWH.JCCo<=@endjcco and 
	SLWH.Job>=isnull(@begjob,SLWH.Job) and 	SLWH.Job<=isnull(@endjob,SLWH.Job)
	and SLWH.ReadyYN='Y' and SLHD.InUseMth is null and (@username is null or (SLWH.UserName = @username))
	and SLWH.SLCo=@co
	----TK-18283
	AND APVM.SortName >= ISNULL(@BeginVendorName, APVM.SortName)
	AND APVM.SortName <= ISNULL(@EndVendorName, APVM.SortName)
   
/* open cursor */
open bcSLWH

/* set open cursor flag to true */
select @opencursor = 1
--select @totaltax = 0  DC #133846
  
/* get first row */
fetch next from bcSLWH into @vendorgroup, @vendor, @paycontrol, @apref,
	@invdescription, @invdate, @payterms, @duedate, @cmco, @cmacct, @holdcode,
	@sl, @slwhjcco, @slwhjob,@guid, @slusername
	----TK-19330
	,@SLWH_KeyId
   
	/* loop through all rows */
	while (@@fetch_status = 0)
		begin

		--DC #133846
		select @totaltax = 0
		SELECT @TotalRetgAmt = 0

		---- TK-19330 get slwh notes
		SELECT @SLWH_Notes = SLWH.Notes
		from dbo.SLWH SLWH
		WHERE SLWH.KeyID = @SLWH_KeyId


		begin TRANSACTION
        
		--Begin Create AP Entry Header
		-- Invoice Total is the sum of Work Completed plus Stored Materials
		select @invtotal=isnull(sum(WCCost),0) + isnull(sum(Purchased),0) - isnull(sum(Installed),0)
		from SLWI 
		where SLCo = @co and SL = @sl
	   
		/*took out per issue #17311
		if @invtotal=0 goto SLWHGetNext		-- skip if 0 invoice amount*/

		if @payterms is not null
			begin
			exec @rcode = bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @calcduedate output,
			@discrate output, @msg output

			select @msg = isnull(@msg,'') + ' - SL:' + @sl

			if @rcode=1 goto bspexit
			end
	   


     	select @eft = EFT, @v1099yn = V1099YN, @v1099type = V1099Type, @v1099box = V1099Box,
     		@SeparatePayInvYN = SeparatePayInvYN,  --DC #136187
     		@VendorPaymethod = PayMethod	-- CHS TK-14206
     	from bAPVM 
		where VendorGroup = @vendorgroup and Vendor = @vendor

		-- CHS TK-14206
		IF @VendorPaymethod = 'S'
			BEGIN
			SELECT @paymethod='S', @SeparatePayInvYN = 'N', @cmacct = @ApcoCsCmAcct
			END

     	ELSE IF @eft='A'
			BEGIN
			SELECT @paymethod='E'
			END
				
		ELSE
			BEGIN
			SELECT @paymethod='C'
			END
	   
     	-- get next available sequence # for the batch
     	select @seq = isnull(max(BatchSeq),0)+1
     	from APHB
     	where Co = @co and Mth = @mth and BatchId = @batchid
	   
		insert bAPHB (Co,Mth,BatchId,BatchSeq,BatchTransType,VendorGroup,Vendor,APRef,Description,InvDate,DiscDate,
			DueDate,InvTotal,HoldCode,PayControl,PayMethod,CMCo,CMAcct,PrePaidYN,V1099YN,V1099Type,
			V1099Box, PayOverrideYN, UniqueAttchID, SeparatePayYN,
			----TK-19330
			Notes)
		values(@co,@mth,@batchid,@seq,'A',@vendorgroup,@vendor,@apref,@invdescription,@invdate,@discdate,
			@duedate,@invtotal,@holdcode,@paycontrol,@paymethod,@cmco,@cmacct,'N',@v1099yn,@v1099type,
			@v1099box, 'N', @guid, @SeparatePayInvYN
			----TK-19330
			,@SLWH_Notes)

		---- get APHB key id
		SET @APHB_KeyId = SCOPE_IDENTITY()

   		select @numrows=@numrows + 1 /*Keeps track of how many invoices were sent to AP Header Batch */
	             
		---- TK-19330 update UD fields
		IF @APHB_UDFlag = 'Y'
			BEGIN
			SELECT @SL_AP_SQL = @SLWH_APHB_Update
								+ ' WHERE SLWH.KeyID = ' + dbo.vfToString(@SLWH_KeyId)
								+ ' AND APHB.KeyID = ' + dbo.vfToString(@APHB_KeyId) 
			EXEC (@SL_AP_SQL)
			END
					         
  		--update attachments table to use APEntry instead of SLWH
		--update bHQAT Set FormName='APEntry' where UniqueAttchID=@guid          
		update bHQAT
			set TableName = 'APHB', FormName='APEntry'
		where UniqueAttchID = @guid

   		--Refresh indexes if attachments exist
		if @guid is not null 
			exec dbo.bspHQRefreshIndexes null, null ,@guid, null

		-- use a cursor to process the Items
		declare bcSLWI cursor for
		select w.SLItem, w.PhaseGroup, w.Phase, w.UM, w.CurUnitCost,
				w.PrevWCUnits, w.PrevWCCost, w.WCUnits, w.WCCost, w.WCRetAmt, w.PrevSM,
				w.Purchased, w.Installed, w.SMRetAmt, w.LineDesc, w.VendorGroup, w.Supplier,
				i.JCCo, i.Job, i.JCCType, i.GLCo, i.GLAcct,
				i.TaxGroup, i.TaxType, i.TaxCode, w.UserName
				----TK-19330
				,w.KeyID
		from SLWI w join SLIT i on i.SLCo=w.SLCo and i.SL=w.SL and i.SLItem=w.SLItem
		where w.SLCo = @co and w.SL = @sl
   
		/* open cursor */
		open bcSLWI
		select @slwiopencursor = 1
      
		/* get first row */
		fetch next from bcSLWI into @slitem, @phasegroup, @phase, @um, @curunitcost,
			@prevwcunits, @prevwccost, @wcunits, @wccost, @wcretamt, @prevsm,
			@purchased, @installed, @smretamt, @linedesc, @suppliervendgroup, @supplier,
			@jcco, @job, @jcctype, @glco, @slglacct,
			@taxgroup, @taxtype, @taxcode, @slitemusername
			----TK-19330
			,@SLWI_KeyId


		/* loop through all rows */
		while (@@fetch_status = 0)
			begin
			if @slusername <> @slitemusername
				begin
				select @msg = 'SL ' + convert(varchar(30), @sl) + ', '  --DC #135813
				select @msg = @msg + 'SL Item ' + convert(varchar, @slitem) + ' cannot be interfaced using a UserName ''' + @slitemusername
				select @msg = @msg + ''' different from the header UserName ''' + @slusername + '''', @rcode = 1
				goto bspexit
				end
				

			--Begin Create AP Entry Detail
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
				goto bspexit
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
				if isnull(@taxcode,'')<> ''
					BEGIN
					IF @HQCoDefaultCountry <> 'US' -- TK-12854
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
										
				-- Accumulate Retg Amt -- TK-12854
				SELECT @TotalRetgAmt = @TotalRetgAmt + ISNULL(@wcretamt,0)
						
				-- add a Line for Work Completed
				select @line = isnull(max(APLine),0)+1 from APLB where Co = @co and Mth = @mth and

				BatchId = @batchid and BatchSeq=@seq

				insert bAPLB (Co,Mth,BatchId,BatchSeq,APLine,BatchTransType,LineType,SL,SLItem,JCCo,Job,
					PhaseGroup,Phase,JCCType,GLCo,GLAcct,Description,UM,Units,UnitCost,ECM,VendorGroup,
					Supplier,PayCategory,PayType,GrossAmt,MiscYN, MiscAmt,Retainage,
					Discount,TaxAmt, TaxBasis, TaxGroup,TaxType,TaxCode
					----TK-19330
					,Notes)
				values(@co,@mth,@batchid,@seq,@line,'A',7,@sl,@slitem,@jcco,@job,@phasegroup,
					@phase,@jcctype,@glco, case @glcostoveride when 'Y' then @slglacct else
					case when @jcglacct is null then @slglacct else @jcglacct end end,
					convert(varchar(30),@linedesc),@um,@wcunits,@curunitcost, case @um when 'LS' then null else 'E' end,
					@suppliervendgroup,@supplier,@paycategory,@paytype,@wccost,'Y',0,@wcretamt,
					0,@taxamt, case isnull(@taxcode,'') when '' then 0 else @taxbasis end,  --DC #129737
					@taxgroup, @taxtype, @taxcode
					----TK-19330
					,@SLWI_Notes)

				---- get APLB key id
				SET @APLB_KeyId = SCOPE_IDENTITY()
	   			
				---- TK-19330 update UD fields
				IF @APLB_UDFlag = 'Y'
					BEGIN
					SELECT @SL_AP_SQL = @SLWI_APLB_Update
										+ ' WHERE SLWI.KeyID = ' + dbo.vfToString(@SLWI_KeyId)
										+ ' AND APLB.Co = ' + dbo.vfToString(@co) 
										+ ' AND APLB.Mth = ' + CHAR(39) + CONVERT(VARCHAR(100),@mth) + CHAR(39)
										+ ' AND APLB.BatchId = ' + dbo.vfToString(@batchid)
										+ ' AND APLB.BatchSeq = ' + dbo.vfToString(@seq)
					EXEC (@SL_AP_SQL)
					END

			END
	   
			if @sm <> 0 or @smretamt<>0
			begin

				--DC #128435
				if isnull(@taxcode,'')<> ''
					BEGIN
					IF @HQCoDefaultCountry <> 'US' -- TK-12854
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
										
				-- Accumulate Retg Amt -- TK-12854
				SELECT @TotalRetgAmt = @TotalRetgAmt + ISNULL(@smretamt,0)

				-- add Line for Stored Materials
				select @line = isnull(max(APLine),0)+1 from APLB where Co = @co and Mth = @mth and
				BatchId = @batchid and BatchSeq=@seq

				insert bAPLB (Co,Mth,BatchId,BatchSeq,APLine,BatchTransType,LineType,SL,SLItem,JCCo,Job,PhaseGroup,
					Phase,JCCType,GLCo,GLAcct,Description,UM,Units,UnitCost,VendorGroup,Supplier,PayCategory,
					PayType,GrossAmt,MiscYN, MiscAmt,Retainage,Discount,TaxAmt, 
					TaxBasis, 
					SMChange, TaxGroup, TaxType, TaxCode
					----TK-19330
					,Notes)
				values(@co,@mth,@batchid,@seq,@line,'A',7,@sl,@slitem,@jcco,@job,@phasegroup,
					@phase,@jcctype,@glco, case @glcostoveride when 'Y' then @slglacct else
					case when @jcglacct is null then @slglacct else @jcglacct end end,
					'Stored Materials for Item ' + convert(varchar (4),@slitem), /*@linedesc,*/
					'LS',0,0,@suppliervendgroup,@supplier,@paycategory,@paytype,@sm,'Y',0,@smretamt,0,@taxamt, 
					case isnull(@taxcode,'') when '' then 0 else @taxbasis /*@sm*/ end,  --DC #129737 , 
					@sm, @taxgroup,@taxtype,@taxcode
					----TK-19330
					,@SLWI_Notes)

				---- get APLB key id
				SET @APLB_KeyId = SCOPE_IDENTITY()

				---- TK-19330 update UD fields
				IF @APLB_UDFlag = 'Y'
					BEGIN
					SELECT @SL_AP_SQL = @SLWI_APLB_Update
										+ ' WHERE SLWI.KeyID = ' + dbo.vfToString(@SLWI_KeyId)
										+ ' AND APLB.Co = ' + dbo.vfToString(@co) 
										+ ' AND APLB.Mth = ' + CHAR(39) + CONVERT(VARCHAR(100),@mth) + CHAR(39)
										+ ' AND APLB.BatchId = ' + dbo.vfToString(@batchid)
										+ ' AND APLB.BatchSeq = ' + dbo.vfToString(@seq)
					EXEC (@SL_AP_SQL)
					END

			END


			/* Write SL Worksheet item to history table prior to deleting from worksheet. */
			exec @rcode = vspSLUpdateSLWIHist @co, @slusername, @sl, @slitem, @msg output
			if @rcode = 1
				begin
				select @msg = 'VPUserName: ' + @slusername + ', SubContract: ' + @sl + ', SLItem: ' + convert(varchar, @slitem) +' - ' + isnull(@msg, '')
				goto bspexit 
				end

			/* History has been recorded, delete worksheet item. */
			delete from SLWI where SLCo = @co and UserName = @slusername and SL = @sl and SLItem = @slitem

		SLWIGetNextLine:
		fetch next from bcSLWI into @slitem, @phasegroup, @phase, @um, @curunitcost,
				@prevwcunits, @prevwccost, @wcunits, @wccost, @wcretamt, @prevsm,
				@purchased, @installed, @smretamt, @linedesc, @suppliervendgroup, @supplier,
				@jcco, @job, @jcctype, @glco, @slglacct,
				@taxgroup, @taxtype, @taxcode,@slitemusername
				----TK-19330
				,@SLWI_KeyId

		end

		if @slwiopencursor = 1
		begin
			close bcSLWI
			deallocate bcSLWI
		end
   
		if not exists(select * from SLWI where SLCo=@co and SL=@sl)
		begin
			/* Potentially update Invoice Header information on "RecvClaims" from worksheet.
			   Do ONLY once!  Somehow know when NOT to update at all! */

			/* Write SL Worksheet header to history table prior to deleting from worksheet. */
			exec @rcode = vspSLUpdateSLWHHist @co, @slusername, @sl, @msg output
			if @rcode = 1
				begin
				select @msg = 'VPUserName: ' + @slusername + ', SubContract: ' + @sl + ' - ' + isnull(@msg, '')
				goto bspexit 
				end
			
			/* History has been recorded, delete worksheet header. */
			delete from SLWH where SLCo=@co and UserName = @slusername and SL=@sl
		end

		-- Update Invoice Total in APHB header for US and International -- TK-12854
		IF @HQCoDefaultCountry <> 'US'
		BEGIN --Update Invoice total in APHB for international
			IF ISNULL(@APCOTaxbasisNetRetgYN,'N') = 'Y'
			BEGIN
				UPDATE dbo.bAPHB
				SET InvTotal = InvTotal - ISNULL(@TotalRetgAmt,0) + ISNULL(@totaltax,0)
				WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @seq
			END
			ELSE
			BEGIN
				UPDATE dbo.bAPHB
				SET InvTotal = InvTotal + ISNULL(@totaltax,0) - ISNULL(@TotalRetgAmt,0) 
				WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @seq
			END
		END
		ELSE
		BEGIN -- Update Invoice total in APHB for US
			--DC #128435
			UPDATE dbo.bAPHB
			SET InvTotal = InvTotal + isnull(@totaltax,0)
			WHERE Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq	
		END
			
      
     	commit transaction

	SLWHGetNext:

	select @slwiopencursor=0
   
     fetch next from bcSLWH into @vendorgroup, @vendor, @paycontrol, @apref, @invdescription, @invdate,
       			@payterms, @duedate, @cmco, @cmacct, @holdcode, @sl, @slwhjcco, @slwhjob,@guid, @slusername
				----TK-19330
				,@SLWH_KeyId
	end

bspexit:

if @rcode = 1 rollback transaction

if @slwiopencursor = 1
	begin
		close bcSLWI
		deallocate bcSLWI
	end

if @opencursor = 1
	begin
		close bcSLWH
		deallocate bcSLWH
	end

return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspSLUpdateAP] TO [public]
GO
