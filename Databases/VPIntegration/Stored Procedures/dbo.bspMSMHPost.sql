SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************/
CREATE      procedure [dbo].[bspMSMHPost]
/***********************************************************
* Created By:	GF 02/28/2005
* Modified By: GG 08/05/05 - #29507 update missing info to bAPTL (material, u/m, tax type) 
*				GF 09/19/2005 - issue #29856 update MSTD.MatlCost from MSMA
*				GF 10/03/2005 - issue #29941 update APTH.InvAmt with @taxamt also, was only doing @totalcost
*				GG 10/14/05 - #29856 - correct MSTD.MatlCost update
*				GF 07/17/2008 - issue #128458 international tax GST/PST
*				MV 08/20/08 - #127994 - update bAPVM with LastInvDate, '01/01/1999' 4 digit year
*				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*				DAN SO 02/05/09 - Issue #129210 - Reduce Matl Cost by Discount Amt (APCO.NetAmtOpt)
*				MV 01/29/10 - #136500 - renamed bAPTD.TaxAmount "GSTtaxAmt"
*				LG 05/04/11 - Issue 141281 - Added [bspBatchUserMemoUpdate] for performance.  5/10 - reversed out change.  further research needed. MarkH
*				CHS	04/19/2012 - TK-14209 - added Pay Method for Credit Services
*
* Called from MS Batch Processing to post a validated
* batch of Material Vendor Payments.
*
* Posts material vendor invoices to AP - inserts expense transactions
* Updates bMSTD - sets MatlAPCo, MatlAPMth, MatlAPRef
*
* Calls bspMSMHPostGL to update account distributions to GL.
*
* INPUT PARAMETERS:
*   @co             MS Co#
*   @mth            Batch Month
*   @batchid        Batch Id
*   @dateposted     Posting date
*
* OUTPUT PARAMETERS
*   @errmsg         error message if something went wrong
*
* RETURN
*  0 = success, 1 = error
*
*****************************************************/
(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
 @dateposted bDate = null, @errmsg varchar(255) = null output)
as
set nocount on

declare @rcode int, @status tinyint, @seq int, @openMSMH_cursor tinyint, @openMSMH_trans tinyint,
		@openMSMA_cursor tinyint, @msmh_count bTrans, @msmh_trans bTrans, @apco bCompany, @exppaytype tinyint, 
		@apcmco bCompany, @vendorgroup bGroup, @vendor bVendor, @apref bAPReference, @invdate bDate,
		@description bDesc, @duedate bDate, @holdcode bHoldCode, @paycontrol varchar(10), @cmco bCompany,
		@cmacct bCMAcct, @errorstart varchar(12), @v1099yn bYN, @v1099type varchar(10), @v1099box tinyint,
		@paymethod char(1), @aptdstatus tinyint, @aptrans bTrans, @glco bCompany, @glacct bGLAcct,
		@apline smallint, @numrows int, @Notes varchar(400), @guid uniqueidentifier, @apthud_flag bYN,
		@join varchar(2000), @where varchar(2000), @update varchar(2000), @sql varchar(8000),
		@paycategory int, @paytype tinyint, @discoff bDollar, @discdate bDate, @linedesc bDesc,
		@matlgroup bGroup, @material bMatl, @um bUM, @unitcost bUnitCost, @ecm bECM, @units bUnits,
		@totalcost bDollar, @taxgroup bGroup, @taxcode bTaxCode, @taxbasis bDollar, @taxamt bDollar,
		@taxtype tinyint, @gsttaxamt bDollar, @UseDiscOption char(1), @DiscOptAmt bDollar, @NetAmtOpt char(1),
		@Eft char(1), @SeparatePayInvYN bYN, @VendorPaymethod char(1), @ApcoCsCmAcct bCMAcct -- CHS TK-14209 		


select @rcode = 0, @openMSMH_cursor = 0, @openMSMH_trans = 0, @apthud_flag = 'N', @msmh_count = 0, @msmh_trans = 0,
		@UseDiscOption = 'Y', @DiscOptAmt = 0

-- check for Posting Date
if @dateposted is null
	begin
	select @errmsg = 'Missing posting date!', @rcode = 1
	goto bspexit
	end
   
  -- call bspUserMemoQueryBuild to create update, join, and where clause
  -- pass in source and destination. Remember to use views only unless working
  -- with a Viewpoint (bidtek) connection.
  exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'MSMH', 'APTH', @apthud_flag output,
   			@update output, @join output, @where output, @errmsg output
  if @rcode <> 0 goto bspexit
  
  -- validate HQ Batch
  exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'MS MatlPay', 'MSMH', @errmsg output, @status output
  if @rcode <> 0 goto bspexit
  if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress
       begin
       select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
       goto bspexit
       end
  -- set HQ Batch status to 4 (posting in progress)
  update bHQBC
  set Status = 4, DatePosted = @dateposted
  where Co = @co and Mth = @mth and BatchId = @batchid
  if @@rowcount = 0
       begin
       select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
       goto bspexit
       end
  
  -- get MS Company info
  select @apco = APCo from bMSCO with (Nolock) where MSCo = @co
  if @@rowcount = 0
       begin
       select @errmsg = 'Invalid MS Co#!', @rcode = 1
       goto bspexit
       end
  
  
  -- need cursor on bMSMH for each distinct APCo
  declare bcMSMHTrans cursor LOCAL FAST_FORWARD for select distinct(APCo)
  from bMSMH where Co = @co and Mth = @mth and BatchId = @batchid
  group by APCo
  
  --open cursor
  open bcMSMHTrans
  select @openMSMH_trans = 1
  
  MSMHTrans_loop:
  fetch next from bcMSMHTrans into @apco
  
  if @@fetch_status = -1 goto MSMHTrans_end
  if @@fetch_status <> 0 goto MSMHTrans_loop
  
  -- get count of bMSMH rows that need a APTrans
  select @msmh_count = count(*) from bMSMH
  where Co=@co and Mth=@mth and BatchId=@batchid and APTrans is null and APCo=@apco
  -- only update HQTC and MSMH if there are MSMH rows that need updating
  if isnull(@msmh_count,0) <> 0
  	begin
  	-- get next available Transaction # for APTH
  	exec @aptrans = dbo.bspHQTCNextTransWithCount 'bAPTH', @apco, @mth, @msmh_count, @errmsg output
  	if @aptrans = 0
  		begin
  		select @errmsg = 'Unable to get AP transaction from HQTC!', @rcode = 1
  		goto bspexit
  		end
    
  	-- set @msmh_trans to last transaction from bHQTC as starting point for update
  	set @msmh_trans = @aptrans - @msmh_count
    	
  	-- update bMSMH and set APTrans
  	update bMSMH set @msmh_trans = @msmh_trans + 1, APTrans = @msmh_trans
  	where Co=@co and Mth=@mth and BatchId=@batchid and APTrans is null and APCo=@apco
  	-- compare count from update with MSMH rows that need to be updated
  	if @@rowcount <> @msmh_count
  		begin
  		select @errmsg = 'Error has occurred updating APTrans in MSMH batch!', @rcode = 1
  		goto bspexit
  		end
  
     	-- have now successfully updated APTrans to MSMH, now update distribution tables
     	-- update bMSMG
     	update bMSMG set APTrans = b.APTrans
     	from bMSMG a join bMSMH b on b.Co=a.MSCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
     	where a.MSCo=@co and a.Mth=@mth and a.BatchId=@batchid and b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.APCo=@apco
  	end
  
  
  goto MSMHTrans_loop
  
  
  MSMHTrans_end:
  	if @openMSMH_trans = 1
  		begin
  		close bcMSMHTrans
  		deallocate bcMSMHTrans
  		set @openMSMH_trans = 0
  		end
  
  
  -- -- -- declare cursor on MS Material Vendor Worksheet Batch
  declare bcMSMH cursor LOCAL FAST_FORWARD
  for select BatchSeq, VendorGroup, MatlVendor, APRef, InvDate, InvDescription, DueDate,
       	HoldCode, PayControl, CMCo, CMAcct, APTrans, UniqueAttchID, APCo, PayCategory, 
  		PayType, DiscDate
  from bMSMH
  where Co = @co and Mth = @mth and BatchId = @batchid
   
  -- open cursor
  open bcMSMH
  set @openMSMH_cursor = 1
   
  -- process through all entries in batch
  MSMH_loop:
  fetch next from bcMSMH into @seq, @vendorgroup, @vendor, @apref, @invdate, @description, @duedate,
           @holdcode, @paycontrol, @cmco, @cmacct, @aptrans, @guid, @apco, @paycategory, @paytype, @discdate
   
  if @@fetch_status = -1 goto MSMH_end
  if @@fetch_status <> 0 goto MSMH_loop
   
  select @errorstart = 'Seq# ' + convert(varchar(6),@seq)
  
  -- ************* --
  -- ISSUE #129210 --
  -- ************* --
  -- -- -- get AP Company info
  select @exppaytype = ExpPayType, @apcmco = CMCo, @NetAmtOpt = NetAmtOpt, @ApcoCsCmAcct = CSCMAcct	-- CHS TK-14209
  from bAPCO with (Nolock) where APCo = @apco
  if @@rowcount = 0
  	begin
  	select @errmsg = @errorstart + ' - Invalid AP Co#!', @rcode = 1
  	goto bspexit
  	end
  
  -- -- -- if MSMH.PayType is not null use instead of APCo.ExpPayType
  if @paytype is not null set @exppaytype = @paytype
  
  
  -- -- -- get Vendor info
  select @v1099yn = V1099YN, @v1099type = V1099Type, @v1099box = V1099Box, @Eft = EFT, @VendorPaymethod = PayMethod	-- CHS TK-14209
              --@paymethod = case EFT when 'A' then 'E' else 'C' end  -- default is check unless active EFT
  from bAPVM with (Nolock) 
  where VendorGroup = @vendorgroup and Vendor = @vendor
  if @@rowcount = 0
  	begin
  	select @errmsg = @errorstart + ' - Invalid Vendor!', @rcode = 1
  	goto bspexit
  	end
  
	-- CHS TK-14206
	SELECT @SeparatePayInvYN = 'N'

	IF @VendorPaymethod = 'S'
		BEGIN
		SELECT @paymethod='S', @cmacct = @ApcoCsCmAcct
		END

	ELSE IF @Eft='A'
		BEGIN
		SELECT @paymethod='E'
		END
		
	ELSE
		BEGIN
		SELECT @paymethod='C'
		END  
  
  
  -- -- -- determine detail status - 1 = open, 2 = hold
  select @aptdstatus = 1
  if @holdcode is not null select @aptdstatus = 2   -- transaction is on hold
  -- -- -- check for Vendor Hold codes
  if exists(select 1 from bAPVH with (Nolock) where APCo = @apco and VendorGroup = @vendorgroup and Vendor = @vendor)
  	select @aptdstatus = 2
  
  begin transaction   -- start a transaction, commit when all updates for this invoice are complete (except GL dist)
  
  
  -- -- -- add AP Transaction Header
  insert bAPTH(APCo, Mth, APTrans, VendorGroup, Vendor, APRef, Description,
  	InvDate, DiscDate, DueDate, InvTotal, HoldCode, PayControl, PayMethod, CMCo, CMAcct,
  	PrePaidYN, PrePaidProcYN, V1099YN, V1099Type, V1099Box, PayOverrideYN, OpenYN, BatchId,
  	Purge, InPayControl, UniqueAttchID, SeparatePayYN)
  values(@apco, @mth, @aptrans, @vendorgroup, @vendor, @apref, @description,
  	@invdate, @discdate, @duedate, 0, @holdcode, @paycontrol, @paymethod, isnull(@cmco,@apcmco), @cmacct,
  	'N', 'N', @v1099yn, @v1099type, @v1099box, 'N', 'Y', @batchid, 'N', 'N', @guid, @SeparatePayInvYN)
  if @@rowcount <> 1
  	begin
  	select @errmsg = @errorstart + ' - unable to insert AP transaction header!'
  	goto MSMH_error
  	end
  
  -- -- -- update Last Invoice Date in Vendor Master
  update bAPVM set LastInvDate = @invdate
  where VendorGroup = @vendorgroup and Vendor = @vendor and isnull(LastInvDate,'01/01/1999') < @invdate
   
  -- -- -- update User Memos
  if @apthud_flag = 'Y'
  	begin
   	---- build joins and where clause
   	  select @join = @join + ' and APTH.APCo = ' + convert(varchar(3),@apco)
   				+ ' and APTH.APTrans = ' + convert(varchar(10),@aptrans)
   	  select @where = @where + ' and b.BatchSeq = ' + convert(varchar(10), @seq)
   				+ ' and APTH.APCo = ' + convert(varchar(3),@apco)
   				+ ' and APTH.APTrans = ' + convert(varchar(10), @aptrans)
   	-- create user memo update statement
   	select @sql = @update + @join + @where
   	exec (@sql)
   	
   	-- ISSUE: #141281
	--EXECUTE bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'MS MatlPay', @errmsg
   	
  	end


-- -- -- declare cursor on MS Material Vendor Worksheet AP Lines - #128458
declare bcMSMA cursor LOCAL FAST_FORWARD
for select MatlGroup, Material, UM, UnitCost, ECM, GLCo, GLAcct, TaxGroup, TaxCode,
	convert(numeric(12,3),sum(Units)), convert(numeric(12,2),sum(TotalCost)), 
	convert(numeric(12,2),sum(DiscOff)), convert(numeric(12,2),sum(TaxBasis)),
	convert(numeric(12,2),sum(TaxAmt)), TaxType, convert(numeric(12,2),sum(GSTTaxAmt))
from dbo.bMSMA
where MSCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
-- -- -- create a separate line per material, um, unit cost, GLCo, GLAcct, Tax Code #128458
group by MatlGroup, Material, UM, UnitCost, ECM, GLCo, GLAcct, TaxGroup, TaxCode, TaxType

-- -- -- open MS Worksheet AP Line cursor
open bcMSMA
select @openMSMA_cursor = 1

-- -- -- process each Line on the Invoice
MSMA_loop:
fetch next from bcMSMA into @matlgroup, @material, @um, @unitcost, @ecm, @glco, @glacct,
			@taxgroup, @taxcode, @units, @totalcost, @discoff, @taxbasis, @taxamt, @taxtype, @gsttaxamt

if @@fetch_status = -1 goto MSMA_end
if @@fetch_status <> 0 goto MSMA_loop

-- -- -- get Material description
select @linedesc = Description
from dbo.bHQMT with (Nolock) where MatlGroup = @matlgroup and Material = @material

-- -- -- get next available line on new trans
select @apline = isnull(max(APLine),0) + 1
from dbo.bAPTL with (Nolock) 
where APCo = @apco and Mth = @mth and APTrans = @aptrans

------ set Tax Type, null = none, 1 = sales
----set @taxtype = null
----if @taxcode is not null set @taxtype = 1

---- #128458 if tax type is null and tax code is not null set to 1 - Sales
if @taxtype is null and @taxcode is not null
	begin
	set @taxtype = 1
	end
  
-- -- -- add a new AP Line - expense type, no misc - #29507 add missing info to update
insert bAPTL (APCo, Mth, APTrans, APLine, LineType, MatlGroup, Material, GLCo, GLAcct,
	Description, UM, Units, UnitCost, ECM, PayType, GrossAmt, MiscAmt, MiscYN,
	TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt,
	Retainage, Discount, BurUnitCost, PayCategory)
values(@apco, @mth, @aptrans, @apline, 3, @matlgroup, @material, @glco, @glacct,
	@linedesc, @um, @units, @unitcost, @ecm, @exppaytype, @totalcost, 0, 'N',
	@taxgroup, @taxcode, @taxtype, @taxbasis, @taxamt,
	0, @discoff, 0, @paycategory)
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to insert AP line into APTL!'
	goto MSMH_error
	end


-- -- -- add AP Detail - Seq #1
insert bAPTD(APCo, Mth, APTrans, APLine, APSeq, PayType, Amount, DiscOffer, DiscTaken,
			DueDate, Status, PayCategory, GSTtaxAmt)
values(@apco, @mth, @aptrans, @apline, 1, @exppaytype, @totalcost + @taxamt, @discoff, @discoff,
			@duedate, @aptdstatus, @paycategory, isnull(@gsttaxamt,0))


-- -- -- add Hold Detail for posted Hold Code
if @holdcode is not null
	begin
	insert into bAPHD(APCo, Mth, APTrans, APLine, APSeq, HoldCode)
	values(@apco, @mth, @aptrans, @apline, 1, @holdcode)
	end
  
  	-- -- -- add Hold Detail for all Vendor Hold Codes
  	insert bAPHD(APCo, Mth, APTrans, APLine, APSeq, HoldCode)
  	select d.APCo, d.Mth, d.APTrans, d.APLine, d.APSeq, v.HoldCode
  	from bAPTD d with (nolock)
  	join bAPVH v with (Nolock) on d.APCo = v.APCo
  	where d.APCo = @apco and d.Mth = @mth and d.APTrans = @aptrans and d.APLine = @apline and d.APSeq = 1
  		and v.VendorGroup = @vendorgroup and v.Vendor = @vendor
  		and not exists(select top 1 1 from bAPHD d2 with (nolock) where d2.APCo = d.APCo and d2.Mth = d.Mth
  		and d2.APTrans = d.APTrans and d2.APLine = d.APLine and d2.APSeq = d.APSeq and d2.HoldCode = v.HoldCode)
  
  	-- -- -- update Invoice Total in Transaction Header
  	update bAPTH set InvTotal = InvTotal + @totalcost + @taxamt
  	where APCo = @apco and Mth = @mth and APTrans = @aptrans
  	if @@rowcount <> 1
  		begin
  		select @errmsg = 'Unable to update Invoice total in AP Transaction Header!'
  		goto MSMH_error
  		end
  
  	-- -- -- update Vendor Activity
  	update bAPVA set InvAmt = InvAmt + @totalcost + @taxamt, AuditYN = 'N'
  	where APCo = @apco and VendorGroup = @vendorgroup and Vendor = @vendor and Mth = @mth
  	if @@rowcount = 0
  		begin
  		insert into bAPVA(APCo, VendorGroup, Vendor, Mth, InvAmt, PaidAmt, DiscOff, DiscTaken, AuditYN)
  		values(@apco, @vendorgroup, @vendor, @mth, @totalcost, 0, @discoff, 0, 'N')
  		end
  	update bAPVA set AuditYN = 'Y'
  	where APCo = @apco and VendorGroup = @vendorgroup and Vendor = @vendor and Mth = @mth
 
	-- ************* --
	-- ISSUE #129210 --
	-- ************* --
 	-- -- -- #29856 update AP Info and Material Cost back to bMSTD
 	--update dbo.bMSTD set MatlAPCo = @apco, MatlAPMth = @mth, MatlAPRef = @apref, MatlCost = (a.TotalCost + a.TaxAmt - a.DiscOff) 																						  
 	update dbo.bMSTD set MatlAPCo = @apco, MatlAPMth = @mth, MatlAPRef = @apref, 
					     MatlCost = CASE @NetAmtOpt
										WHEN 'Y' THEN (a.TotalCost + a.TaxAmt - a.DiscOff) 
												 ELSE (a.TotalCost + a.TaxAmt) END
 	from dbo.bMSTD t
 	join dbo.bMSMA a on a.MSCo = t.MSCo and a.TransMth = t.Mth and a.MSTrans = t.MSTrans
 	where a.MSCo = @co and a.Mth = @mth and a.BatchId = @batchid and a.BatchSeq = @seq
 		and a.MatlGroup = @matlgroup and a.Material = @material and a.UM = @um and a.UnitCost = @unitcost
 		and a.ECM = @ecm and a.GLCo = @glco and a.GLAcct = @glacct and a.TaxGroup = @taxgroup
 		and isnull(a.TaxCode,'') = isnull(@taxcode,'')
 	select @numrows = @@rowcount
 
  	-- -- -- remove MSMA entries summarized into the AP Invoice Line 
  	delete dbo.bMSMA
  	where MSCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
  		and MatlGroup = @matlgroup and Material = @material and UM = @um and UnitCost = @unitcost
 		and ECM = @ecm and GLCo = @glco and GLAcct = @glacct and TaxGroup = @taxgroup
 		and isnull(TaxCode,'') = isnull(@taxcode,'')
 	if @numrows <> @@rowcount
  		begin
  		-- -- -- make sure number of AP Line Detail rows deleted matches number of Trans Detail updated
  		select @errmsg = 'Unable to update MS Transaction Detail with Material Vendor Payment information!'
  		goto MSMH_error
  		end
  
  	goto MSMA_loop -- next AP Invoice Line
  
  	MSMA_end:  -- finished with AP Invoice Lines
  		close bcMSMA
  		deallocate bcMSMA
  		select @openMSMA_cursor = 0
  
 	-- -- -- make sure all AP Line detail for the Sequence has been processed
 	if exists(select top 1 1 from dbo.bMSMA where MSCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq)
 		begin
 		select @errmsg = 'Not all AP Line detail was processed!'
 		goto MSMH_error
 		end
 
  	-- -- -- remove Worksheet Detail
  	delete bMSMT where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
  	
   	-- -- -- remove Material Vendor Worksheet Batch Header
  	delete bMSMH where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
  	if @@rowcount <> 1
  		begin
  		select @errmsg = 'Unable to delete Material Vendor Worksheet Header entry!'
  		goto MSMH_error
  		end
  
  commit transaction
  
  
  goto MSMH_loop  -- get next Material Vendor Worksheet Header entry
  
   
  MSMH_error:       -- error during Invoice processing
  	rollback transaction
  	select @rcode = 1
  	goto bspexit
  
  MSMH_end:   -- finished with Material Vendor Worksheet Headers
  	close bcMSMH
  	deallocate bcMSMH
  	select @openMSMH_cursor = 0
  
  
  
  -- -- -- General Ledger update
  exec @rcode = dbo.bspMSMHPostGL @co, @mth, @batchid, @dateposted, @errmsg output
  if @rcode <> 0 goto bspexit
  
  -- -- -- make sure all AP Invoice Line distributions have been processed
  if exists(select 1 from bMSMA with (Nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
  	begin
  	select @errmsg = 'Not all Invoice Line updates to AP were posted - unable to close the batch!', @rcode = 1
  	goto bspexit
  	end
  
  -- -- -- make sure all Material Vendor Worksheet Batch Detail has been processed
  if exists(select 1 from bMSMT with (Nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
  	begin
  	select @errmsg = 'Not all Material Vendor Worksheet detail updates were posted - unable to close the batch!', @rcode = 1
  	goto bspexit
  	end
  
  -- -- -- make sure all Worksheet Batch Headers have been processed
  if exists(select 1 from bMSMH with (Nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
  	begin
  
  	select @errmsg = 'Not all Material Vendor Worksheet headers were posted - unable to close the batch!', @rcode = 1
  	goto bspexit
  	end
  
  -- -- -- make sure all GL Distributions have been processed
  if exists(select 1 from bMSMG with (Nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
  	begin
  	select @errmsg = 'Not all updates to GL were posted - unable to close the batch!', @rcode = 1
  	goto bspexit
  	end
  
  -- -- -- set interface levels note string
  select @Notes=Notes from bHQBC with (Nolock) 
  where Co = @co and Mth = @mth and BatchId = @batchid
  if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
  select @Notes=@Notes +
           'AR Interface Level set at: ' + convert(char(1), a.ARInterfaceLvl) + char(13) + char(10) +
           'EM Interface Level set at: ' + convert(char(1), a.EMInterfaceLvl) + char(13) + char(10) +
           'GL Invoice Interface Level set at: ' + convert(char(1), a.GLInvLvl) + char(13) + char(10) +
           'GL Ticket Interface Level set at: ' + convert(char(1), a.GLTicLvl) + char(13) + char(10) +
           'IN Sales Interface Level set at: ' + convert(char(1), a.INInterfaceLvl) + char(13) + char(10) +
           'IN Production Interface Level set at: ' + convert(char(1), a.INProdInterfaceLvl) + char(13) + char(10) +
           'JC Interface Level set at: ' + convert(char(1), a.JCInterfaceLvl) + char(13) + char(10)
  from bMSCO a with (Nolock) where MSCo=@co
  
  -- -- -- delete HQ Close Control entries
  delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
  
  -- -- -- set HQ Batch status to 5 (posted)
  update bHQBC
  set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
  where Co = @co and Mth = @mth and BatchId = @batchid
  if @@rowcount = 0
  	begin
  	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
  	goto bspexit
  	end
  
  
  
  bspexit:
  	if @openMSMH_cursor = 1
  		begin
  		close bcMSMH
  		deallocate bcMSMH
  		end
  
      if @openMSMA_cursor = 1
  		begin
  		close bcMSMA
  		deallocate bcMSMA
  		end
   
       if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
       return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspMSMHPost] TO [public]
GO
