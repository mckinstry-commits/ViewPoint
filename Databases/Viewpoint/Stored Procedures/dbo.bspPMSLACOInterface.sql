SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMSLACOInterface    Script Date: 8/28/99 9:36:47 AM ******/
CREATE  proc [dbo].[bspPMSLACOInterface]
/*************************************
 * Created By:   LM  04/30/1998
 * Modified By:  GF  05/12/2000 - Added another pseudo cursor level for item
 *               GG  05/16/2000 - Dropped PrevWC and WC columns from bSLIT - removed update
 *               GF  09/21/2000 - Update SLCB notes.
 *               GF  02/07/2001 - Changed to a cursor, no longer using a pseudo cursor.
 *               GF  02/23/2001 - changed insert into bPMBC for columns
 *               GF  03/01/2001 - change record type if regular item added from a change order
 *               GF  04/10/2001 - added check for existing SL in batch when adding items
 *               allenn 02/22/2002 - issue 14175. new phase override gl accounts from JC Department Master. 
 *               Danf 09/06/02 - 17738 Added Phase Group to bspJCADDCOSTTYPE
 *				GF  01/21/2003 - issue 20091 - getting glacct wrong changed to use bspJCCAGlacctDflt.
 *				GF 09/10/2003 - issue #22398 - added check for duplicate SL item with different
 *								 phase/costtype/um combination
 *				GF 10/10/2003 - issue #22707 - @slcbdesc was not being set, null going into SLCB
 *				GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
 *				GF 01/15/2003 - issue #20976 - added interface of pending change order to SL
 *				GF 03/09/2004 - issue #23938 - insert duplicate row problem with change orders.
 *				GF 04/30/2004 - #24486 - added SLItem is not null to cursor where clause
 *				GF 06/01/2004 - #24142 - update users memos when inserting SLHB batch row for SL.
 *				GF 07/21/2004 - #25100 - update SLIT user memos from PMSL
 *				GF 10/12/2004 - issue #25747 arithmatic overflow if more than 255 records for a change order
 *				GF 11/03/2004 - issue #24409 add input param for internal approval date used for SL change orders
 *				GF 05/31/2005 - issue #28797 expanded slcb description from 30 to 60 (bDesc to bItemDesc)
 *				GF 06/21/2005 - issue #29063 added validation for SLHB.PayTerms and SLHB.Holdcode
 *				GF 08/26/2005 - issue #29650 added case statement to SLIB update for SLItemType=4. Addon Pct problem.
 *				GF 09/27/2005 - ISSUE #29922 update SLHB.UniqueAttchID from SLHD when adding to SLHB batch.
 *				GF 12/22/2005 - issue #29868 allow early interface of subcontract change order original items (no SubCO)
 *				GF 09/19/2008 - issue #129811 subcontract tax
*				GF 01/25/2009 - issue #131992 insert AddedMth, AddedBatchID into SLIT
 *				DC 05/04/2009 - issue #130175 SLIT needs to match POIT - and tax needs to match when updated to JCCD
 *				GP 01/19/2010 - issue #137608 bcPMSL cursor select was not returning Tax related fields
 *				MV 02/04/10 - issue #136500 - bspHQTaxRateGetAll added NULL output param.
 *				DC 03/12/10 - issue #130175
 *				GF 03/20/2010 - issue #136053 AUS subcontractpre-bill
 *				GF 06/28/2010 - issue #135813 SL expanded to 30 characters
 *				GF 09/28/2010 - issue #141349 better error messages (with SL)
 *				JG 10/04/2010 - TFS# 491 - PM SL In/Exclusion Updates
 *				GF 10/07/2010 - issue #141562 SLHB batch sequence changed to integer.
 *				JG 10/06/2010 - TFS# 491 - Added the BatchTransType for SLInExclusions
 *				GF 10/12/2010 - issue #141264 check for vendor <> supplier
 *				GF 01/10/2011 - issue #142798 need to add max retainage columns to SLHB
 *				GF 02/21/2011 - TK-01723 SUBCO must be approved.
 *				MV 10/25/2011 - TK-09243 - bspHQTaxRateGetAll added NULL output param.
 *				GF 11/09/2012 TK-18033 SL Claim Enhancement. Changed to Use ApprovalRequired
 *
 *
 * USAGE:
 * used by PMInterface to interface a project or change order from PM to SL as specified
 *
 * Pass in :
 *	PMCo, Project, Mth, Approved Change Order, SL Batchid, Batch Status, errmsg
 *
 *
 * Returns
 *	SL Batchid, Batch Status, Error message and return code
 *
 *******************************************************/
(@pmco bCompany, @project bJob, @mth bMonth, @aco bACO, @glco bCompany, @pcotype bDocType, @pco bPCO,
 @internal_date bDate, @slbatchid int output, @slcbbatchid int output, @slstatus tinyint output, 
 @slcbstatus tinyint output, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @slhbseq int, @opencursor tinyint, @slco bCompany, @vendorgroup bGroup,
        @vendor bVendor, @actdate bDate, @holdcode bHoldCode, @payterms bPayTerms, @compgroup varchar(10),
        @um bUM, @phasegroup bGroup, @phase bPhase, @costtype bJCCType, @addon tinyint, @addonpct bPct,
        @pmslseq int, @units bUnits, @unitcost bUnitCost, @ecm bECM, @amount bDollar, @wcretpct bPct, 
        @smretpct bPct, @acoitemdesc bItemDesc, @glacct bGLAcct, @errtext varchar(255), @sl VARCHAR(30),
        @slitem bItem, @errorcount int, @status tinyint, @acoitem bACOItem, @itemtype tinyint,
        @slitemrowcount int,
        @contract bContract, @contractitem bContractItem, @department bDept, @slcbseq int, @approved bYN,
        @slchangeorder smallint, @supplier bVendor, @activeyn bYN, @slcbunitcost bUnitCost, @slcbcost bDollar,
        @slitemdesc bItemDesc, @slseq int, @slititem bItem, @slcbdesc bItemDesc, @pcotext varchar(100),
   		@approved_date bDate, @inusebatchid bBatchID, @source bSource, @inusemth bMonth,
   		@uniqueattchid uniqueidentifier, @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint,
		@taxphase bPhase, @taxct bJCCType, @taxjcum bUM, @taxrate bRate, @taxamount bDollar,
		@valueadd varchar(1), @gstrate bRate, @pstrate bRate, @HQTXdebtGLAcct bGLAcct,
		@gsttaxamt bDollar, @psttaxamt bDollar, --DC #130175
		----#141349
		@slitemerr VARCHAR(50)
		
select @rcode = 0, @errorcount = 0, @slbatchid = 0, @slcbbatchid = 0, @slitemrowcount = 0, @opencursor = 0

-- -- -- get SLCo for this PMCo
select @slco=APCo from bPMCO with (nolock) where PMCo=@pmco

-- -- -- set actual date
select @actdate= dbo.vfDateOnly()

-- -- -- declare cursor on PMSL subcontract detail using either ACO or PCO
if isnull(@pco,'') <> ''
	begin
	declare bcPMSL cursor LOCAL FAST_FORWARD
	for select Seq, SL, SLItem, VendorGroup, Vendor, SLItemType, SLAddon, isnull(SLAddonPct,0), PhaseGroup, 
		   Phase, CostType, SLItemDescription, UM, isnull(WCRetgPct,0), isnull(SMRetgPct,0), Supplier,
		   isnull(SubCO,0), PCOItem, isnull(Units,0), isnull(UnitCost,0), isnull(Amount,0),
		   TaxGroup, TaxType, TaxCode
	from bPMSL where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco 
	and SLCo=@slco and SL is not null and RecordType='C' and SendFlag='Y' /*and isnull(SubCO,0) > 0 -- -- -- issue #29868 */
	and InterfaceDate is null and SLItem is not null
	group by SL, SLItem, SLItemType, Seq, VendorGroup, Vendor, SLAddon, SLAddonPct, PhaseGroup,
	Phase, CostType, SLItemDescription, UM, WCRetgPct, SMRetgPct, Supplier, SubCO, PCOItem, Units,
	UnitCost, Amount, TaxGroup, TaxType, TaxCode
	end
else
	begin
	-- declare cursor on PMSL Subcontract Detail for interface to SLCB Change Order Batch
	declare bcPMSL cursor LOCAL FAST_FORWARD
	for select Seq, SL, SLItem, VendorGroup, Vendor, SLItemType, SLAddon, isnull(SLAddonPct,0), PhaseGroup,
			Phase, CostType, SLItemDescription, UM, isnull(WCRetgPct,0), isnull(SMRetgPct,0), Supplier,
			isnull(SubCO,0), ACOItem, isnull(Units,0), isnull(UnitCost,0), isnull(Amount,0),
			TaxGroup, TaxType, TaxCode
	from bPMSL where PMCo=@pmco and Project=@project and ACO=@aco and SLCo=@slco and SL is not null 
	and RecordType='C' and SendFlag='Y' and InterfaceDate is null and SLItem is not null
	group by SL, SLItem, SLItemType, Seq, VendorGroup, Vendor, SLAddon, SLAddonPct, PhaseGroup,
	Phase, CostType, SLItemDescription, UM, WCRetgPct, SMRetgPct, Supplier, SubCO, ACOItem, Units,
	UnitCost, Amount, TaxGroup, TaxType, TaxCode
	end
    
    -- open cursor
    open bcPMSL
    
    -- set open cursor flag to true
    select @opencursor = 1

    PMSL_loop:
    fetch next from bcPMSL into @pmslseq, @sl, @slitem, @vendorgroup, @vendor, @itemtype, @addon, @addonpct,
    		@phasegroup, @phase, @costtype, @slitemdesc, @um, @wcretpct, @smretpct, @supplier, @slchangeorder,
    		@acoitem, @units, @unitcost, @amount, @taxgroup, @taxtype, @taxcode

    if @@fetch_status <> 0 goto PMSL_end
    
    -- get needed SLHD information
    select @holdcode=HoldCode, @payterms=PayTerms, @compgroup=CompGroup, @approved=Approved, @status=Status,
    		@inusebatchid=InUseBatchId, @inusemth=InUseMth, @uniqueattchid=UniqueAttchID
    from bSLHD with (nolock) where SLCo=@slco and SL=@sl and VendorGroup=@vendorgroup and Vendor=@vendor
    
    if @status=3 and @approved in ('N',NULL) goto PMSL_loop
    
	---- issue #29868 - if interfacing a pco and @itemtype = 2 then @slchangeorder required (>0)
	if isnull(@pco,'') <> '' and @itemtype = 2 and isnull(@slchangeorder,0) = 0 goto PMSL_loop
	
	---- TK-01723
	IF ISNULL(@slchangeorder,0) > 0
		BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM dbo.PMSubcontractCO c WHERE c.SLCo=@slco AND c.SL=@sl
						AND c.SubCO=@slchangeorder AND c.ReadyForAcctg = 'N')
			BEGIN
			GOTO PMSL_loop
			END
		END

    If @slbatchid = 0
         begin
         exec @slbatchid = dbo.bspHQBCInsert @slco,@mth,'PM Intface','SLHB','N','N',null,null,@errmsg output
         if @slbatchid = 0
             begin
             select @errmsg = @errmsg + ' - Cannot create SL batch'
             goto bspexit
             end
         -- insert batchid into PMBC
         select @slseq=isnull(max(SLSeq),0)+1 from bPMBC with (nolock) 
         insert into bPMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
         select @pmco, @project, @mth, 'SLHB', @slbatchid, @slco, @slseq, null, null, null, null
         end
    
    if @slcbbatchid = 0
         begin
         exec @slcbbatchid = dbo.bspHQBCInsert @slco,@mth,'PM Intface','SLCB','N','N',null,null,@errmsg output
         if @slcbbatchid = 0
             begin
             select @errmsg = @errmsg + ' - Cannot create SLCB batch'
             goto bspexit
             end
         -- insert batchid into PMBC
         select @slseq=isnull(max(SLSeq),0)+1 from bPMBC with (nolock) 
         insert into bPMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
         select @pmco, @project, @mth, 'SLCB', @slcbbatchid, @slco, @slseq, null, null, null, null
         end
    
    -- Validate record prior to inserting into batch table
    if @inusebatchid is not null
    	begin
    	select @source=Source from HQBC with (nolock) 
    	where Co=@slco and BatchId=@inusebatchid and Mth=@inusemth
    	if @@rowcount <> 0
    		begin
    		select @errtext = 'SL: ' + isnull(@sl,'') + ' already in use by ' +
    			convert(varchar(2),DATEPART(month, @inusemth)) + '/' + substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) +
    			' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
			end
		else
			begin
			select @errtext='SL already in use by another batch!', @rcode=1
			end
      
    	exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
    	select @errorcount = @errorcount + 1
    	goto PMSL_loop
    	end
        
    -- -- -- get the PMOI.ApprovedDate for ACO Item
    set @approved_date = null
    if isnull(@aco,'') <> ''
    	begin
    	select @approved_date = ApprovedDate
    	from bPMOI where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
    	end
    
    -- -- -- if sending PCO sub CO's then use the @internal_date if not null else system date
    -- -- -- if sending ACO sub CO's then use the @approved_date if not null else system date
    if isnull(@pco,'') <> '' and isnull(@internal_date,'') <> '' set @actdate = @internal_date
    if isnull(@aco,'') <> '' and isnull(@approved_date,'') <> '' set @actdate = @approved_date

	----#141349
	select @slitemerr = ' SL: ' + isnull(@sl,'') + ' Item: ' + convert(varchar(6),isnull(@slitem,''))
    -- validate Phase
    exec @rcode = dbo.bspJCADDPHASE @pmco,@project,@phasegroup,@phase,'Y',null,@errmsg output
    if @rcode <> 0
		BEGIN
		----#141349
		select @errtext = @errmsg + @slitemerr
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
		end
    
	----#141264 the vendor cannot equal the supplier
	IF @supplier IS NOT NULL AND @supplier = @vendor
		BEGIN
        select @errtext = 'Supplier cannot be the same as the vendor.' + @slitemerr
        exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
        select @errorcount = @errorcount + 1
        goto PMSL_loop
		END
		
	-- validate Cost Type
	exec @rcode = dbo.bspJCADDCOSTTYPE @jcco=@pmco,@job=@project,@phasegroup=@phasegroup,@phase=@phase,@costtype=@costtype,@um=@um,@override= 'P',@msg=@errmsg output
	if @rcode<>0
		BEGIN
		----#141349
		select @errtext = @errmsg + @slitemerr
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
		end
    
	-- update active flag if needed
	select @activeyn=ActiveYN
	from bJCCH with (nolock) where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
	if @activeyn <> 'Y'
		begin
		update bJCCH set ActiveYN='Y'
		where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
		end
    
    -- get GLAcct
    select @contract=Contract, @contractitem=Item
    from bJCJP with (nolock) where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
    select @department=Department
    from bJCCI with (nolock) where JCCo=@pmco and Contract=@contract and Item=@contractitem
    select @glacct = null
    exec @rcode = dbo.bspJCCAGlacctDflt @pmco, @project, @phasegroup, @phase, @costtype, 'N', @glacct output, @errmsg output
    if @glacct is null
		begin
    	select @errtext = 'GL Acct for Cost Type: ' + convert(varchar(3),@costtype) + 'may not be null'
    	exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
    	select @errorcount = @errorcount + 1
    	goto PMSL_loop
    	end
    
     -- check units to UM
    if @um = 'LS' and @units <> 0
        BEGIN
        ----#141349
        select @errtext = 'Units must be zero when UM is (LS).' + @slitemerr
        exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
        select @errorcount = @errorcount + 1
        goto PMSL_loop
        end
    
    -- check unit cost to UM
    if @um = 'LS' and @unitcost <> 0
        BEGIN
        ----#141349
        select @errtext = 'Unit cost must be zero when UM is (LS).' + @slitemerr
        exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
        select @errorcount = @errorcount + 1
        goto PMSL_loop
        end

	---- #131843 if units = 0, amount <> 0, and @um <> 'LS' we do not want to send to Acct. Committed Cost get closed
	if isnull(@units,0) = 0 and isnull(@amount,0) <> 0 and isnull(@um,'LS') <> 'LS'
		BEGIN
		----#141349
        select @errtext = 'Units and Amount cannot be zero when UM is not (LS).' + @slitemerr
        exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
        select @errorcount = @errorcount + 1
        goto PMSL_loop
		end
		
	if @taxtype is null and @taxcode is not null
		BEGIN
		----#141349
		select @errtext = 'Tax Code assigned, but missing Tax Type for item.' + @slitemerr
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
		end
    
    -- check for duplicate item record with different phase/costtype/um combination
    if isnull(@pco,'') <> ''
    	begin
    	if exists(select 1 from bPMSL where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
    		and SLCo=@slco and Vendor=@vendor and SL=@sl and SLItem=@slitem and Seq<>@pmslseq and InterfaceDate is null
    		and SendFlag = 'Y'  and RecordType='C' and (Phase<>@phase or CostType<>@costtype or UM<>@um))
    		begin
    		select @errtext = 'SL: ' + isnull(@sl,'') + ' SLItem: ' + convert(varchar(8),isnull(@slitem,'')) + ' - Multiple records set up for same item with different Phase/CostType/UM combination.'
    	    exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
    	    select @errorcount = @errorcount + 1
    	    goto PMSL_loop
    	    end
    	end
    else
    	begin
    	if exists(select 1 from bPMSL where PMCo=@pmco and Project=@project and ACO=@aco and SLCo=@slco
    		and Vendor=@vendor and SL=@sl and SLItem=@slitem and Seq<>@pmslseq and InterfaceDate is null
    		and SendFlag = 'Y'  and RecordType='C' and (Phase<>@phase or CostType<>@costtype or UM<>@um))
    		begin
    		select @errtext = 'SL: ' + isnull(@sl,'') + ' SLItem: ' + convert(varchar(8),isnull(@slitem,'')) + ' - Multiple records set up for same item with different Phase/CostType/UM combination.'
    	    exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
    	    select @errorcount = @errorcount + 1
    	    goto PMSL_loop
    	    end
    	end

	---- issue #29868 - if interfacing pco and @itemtype = 1 check if item exists in SLIT. If it does then @slchangeorder is required (>0)
	if isnull(@pco,'') <> '' and @itemtype = 1
		begin
		---- check if item exists in SLIT
		if exists(select 1 from bSLIT with (nolock) where SLCo=@slco and SL=@sl and SLItem=@slitem)
			begin
			if isnull(@slchangeorder,0) = 0 goto PMSL_loop
			end
		end

	---- get next available sequence # for this batch
	if exists (select 1 from bSLHB with (nolock) where Co=@slco and Mth=@mth and BatchId=@slbatchid and SL=@sl)
		begin
		select @slhbseq=BatchSeq from bSLHB with (nolock) where Co=@slco and Mth=@mth and BatchId=@slbatchid and SL=@sl
		end
	else
		begin
		select @slhbseq = isnull(max(BatchSeq),0)+1 from bSLHB where Co=@slco and Mth=@mth and BatchId=@slbatchid
		insert into bSLHB (Co, Mth, BatchId, BatchSeq, BatchTransType, SL, JCCo, Job, Description, VendorGroup,
					Vendor, HoldCode, PayTerms, CompGroup, Status, OrigDate, OldJCCo, OldJob, OldDesc, OldVendor, OldHoldCode,
					OldPayTerms, OldCompGroup, OldStatus, UniqueAttchID, Notes,
					----#142798
					MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN, MaxRetgDistStyle
					----TK-18033
					,ApprovalRequired)
		select @slco, @mth, @slbatchid, @slhbseq, 'C', @sl, JCCo, Job, /*@pmco, @project,*/ Description, @vendorgroup,
					@vendor, HoldCode, PayTerms, CompGroup, 0, OrigDate, JCCo, Job, /*@pmco, @project,*/ Description, @vendor, HoldCode,
					PayTerms, CompGroup, @status, @uniqueattchid, Notes,
					----#142798
					MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN, MaxRetgDistStyle
					----TK-18033
					,ApprovalRequired
		from bSLHD where SLCo=@slco and SL=@sl
		if @@rowcount <> 1
			begin
			select @errtext = 'Could not insert SL: ' + isnull(@sl,'') + ' into batch'
			exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1
			goto PMSL_loop
			end
		else
			begin
			-- -- -- update user memo to SLHB batch table- BatchUserMemoInsertExisting
			exec @rcode = dbo.bspBatchUserMemoInsertExisting @slco, @mth, @slbatchid, @slhbseq, 'SL Entry', 0, @errmsg output
			if @rcode <> 0
				begin
				select @errtext = 'Unable to update user memo to SL: ' + isnull(@sl,'') + ' Batch'
				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMSL_loop
				end
				
			-- Insert SL Inclusions/Exclusions - JG TFS# 491
			INSERT INTO vSLInExclusionsBatch (Co, BatchId, Mth, BatchSeq, Seq
			, BatchTransType, [Type], PhaseGroup, Phase, Detail, DateEntered, EnteredBy
			, Notes, UniqueAttchID)
			SELECT @slco, @slbatchid, @mth, @slhbseq, Seq, 'C', [Type], PhaseGroup, Phase
			, Detail, DateEntered, EnteredBy, Notes, UniqueAttchID
			FROM vSLInExclusions
			WHERE Co=@slco and SL=@sl 
				
			end
		end

	-- -- -- validate hold code and pay terms for SLHB
	select @holdcode=HoldCode, @payterms=PayTerms
	from bSLHB with (nolock) where Co=@slco and Mth=@mth and BatchId=@slbatchid and BatchSeq=@slhbseq
	if @@rowcount <> 0
		begin
   		-- -- -- validate Hold Code
   		if isnull(@holdcode,'') <> ''
   			begin
   			if not exists(select top 1 1 from bHQHC where HoldCode=@holdcode)
   				begin
   				select @errtext = 'Invalid hold code: ' + isnull(@holdcode,'') + ' for SL: ' + isnull(@sl,'') + '.'
   				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
   				select @errorcount = @errorcount + 1
   				goto PMSL_loop
   				end
   			end
   		-- -- -- validate pay terms
   		if isnull(@payterms,'') <> ''
   			begin
   			if not exists(select top 1 1 from bHQPT where PayTerms=@payterms)
   				begin
   				select @errtext = 'Invalid pay terms: ' + isnull(@payterms,'') + ' for SL: ' + isnull(@sl,'') + '.'
   				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
   				select @errorcount = @errorcount + 1
   				goto PMSL_loop
   				end
   			end
   		end

-- -- -- if tax code assigned, validate tax phase and cost type then calculate tax
---- ANY CHANGES MADE TO THIS ROUTINE NEED TO ALSO BE DONE IN bspPMSLInterface,
---- bspPMPOInterface, bspPMPOACOInterface, and vspPMSLCreateSLItem. The logic should
---- be similar between the procedures working with tax codes.
if @taxcode is null
	begin
	select @taxamount=0,
			@taxrate = 0, @gstrate = 0  --DC #130175
	end
else
	begin
	select @taxphase = null, @taxct = null
	-- -- -- validate Tax Code
	exec @rcode = bspPOTaxCodeVal @taxgroup, @taxcode, @taxtype, @taxphase output, @taxct output, @errmsg output
	if @rcode <> 0
		begin
		select @errtext = isnull(@errmsg,'')
		exec @rcode = bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
		end
	-- -- -- validate Tax Phase if Job Type
	if @taxphase is null select @taxphase = @phase
	if @taxct is null select @taxct = @costtype
	-- -- -- validate tax phase - if does not exist try to add it
	exec @rcode = bspJCADDPHASE @pmco, @project, @phasegroup, @taxphase, 'Y', null, @errmsg output
	-- if phase/cost type does not exist in JCCH try to add it
	if not exists(select top 1 1 from bJCCH where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup
					and Phase=@taxphase and CostType=@taxct)
		begin
		-- -- -- insert cost header record
		insert into bJCCH (JCCo,Job,PhaseGroup,Phase,CostType,UM,BillFlag,ItemUnitFlag,PhaseUnitFlag,BuyOutYN,Plugged,ActiveYN,SourceStatus)
		select @pmco, @project, @phasegroup, @taxphase, @taxct, 'LS', 'C', 'N', 'N', 'N', 'N', 'Y', 'I'
		end
	-- -- -- validate Tax phase and Tax Cost Type
	exec @rcode = bspJobTypeVal @pmco, @phasegroup, @project, @taxphase, @taxct, @taxjcum output, @errmsg output
	if @rcode <> 0
		begin
		select @errtext = 'Tax: ' + isnull(@errmsg,'')
		exec @rcode = bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
		end

	---- calculate tax
	select @taxrate = 0, @gstrate = 0, @pstrate = 0
	--DC #130175
	exec @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, @actdate, @valueadd output, @taxrate output, @gstrate output, @pstrate output, 
				null, null, @HQTXdebtGLAcct output, null, null, null, NULL, NULL,@errmsg output
	
	--DC #130175	
	if @gstrate = 0 and @pstrate = 0 and @valueadd = 'Y'
		begin
		-- We have an Intl VAT code being used as a Single Level Code
		if (select GST from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
			begin
			select @gstrate = @taxrate
			end
		end

	--select @taxamount = (@amount * @taxrate)		--Full TaxAmount:  This is correct whether US, Intl GST&PST, Intl GST only, Intl PST only		1000 * .155 = 155
	--select @gsttaxamt = case @taxrate when 0 then 0 else case @valueadd when 'Y' then (@taxamount * @gstrate) / @taxrate else 0 end end --GST Tax Amount.  (Calculated)					(155 * .05) / .155 = 50
	--select @psttaxamt = case @valueadd when 'Y' then @taxamount - @gsttaxamt else 0 end			--PST Tax Amount.  (Rounding errors to PST)		
	
	end

-- -- -- Check existence and Item Type
select @slititem=SLItem
from bSLIT with (nolock) where SLCo=@slco and SL=@sl and SLItem=@slitem
if @@rowcount = 0
	begin
	--DC #130175  New records use the current tax rate
	select @taxamount = (@amount * @taxrate)		--Full TaxAmount:  This is correct whether US, Intl GST&PST, Intl GST only, Intl PST only		1000 * .155 = 155
	select @gsttaxamt = case @taxrate when 0 then 0 else case @valueadd when 'Y' then (@taxamount * @gstrate) / @taxrate else 0 end end --GST Tax Amount.  (Calculated)					(155 * .05) / .155 = 50
	select @psttaxamt = case @valueadd when 'Y' then @taxamount - @gsttaxamt else 0 end			--PST Tax Amount.  (Rounding errors to PST)			
	
	-- -- -- check original PMSL for item not interfaced yet
	if exists (select 1 from bPMSL with (nolock) where PMCo=@pmco and Project=@project and SL=@sl and SLItem=@slitem
                         and SLCo=@slco and RecordType='O' and InterfaceDate is null)
		BEGIN
		----#141349
		select @errtext = 'SL: ' + ISNULL(@sl,'') + ' SL Item: ' + ltrim(convert(varchar(10),isnull(@slitem,''))) + ' exists in PMSL and must be interfaced first.'
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
		end

	-- -- -- if reg type and does not exist in slit then add it as an original
	if @itemtype = 1
		begin
		if exists(select * from bSLIB where Co=@slco and Mth=@mth and BatchId=@slbatchid and BatchSeq=@slhbseq and SLItem=@slitem)
			begin
			update bSLIB set OrigUnits = OrigUnits + isnull(@units,0), OrigCost = OrigCost + isnull(@amount,0)
			where Co=@slco and Mth=@mth and BatchId=@slbatchid and BatchSeq=@slhbseq and SLItem=@slitem
			end
		else
			begin
			insert into bSLIB(Co, Mth, BatchId, BatchSeq, SLItem, BatchTransType, ItemType, Addon, AddonPct, 
    					JCCo, Job, PhaseGroup, Phase, JCCType, Description, UM, GLCo, GLAcct, WCRetPct, SMRetPct, 
    					VendorGroup, Supplier, OrigUnits, OrigUnitCost, OrigCost,
					TaxType, TaxCode, TaxGroup, OrigTax, Notes,
					JCCmtdTax, TaxRate, GSTRate)  --DC#130175)
			select @slco, @mth, @slbatchid, @slhbseq, @slitem, 'A', @itemtype,
					case when @itemtype = 4 then @addon else null end, 
   					case when @itemtype = 4 then isnull(@addonpct,0) else 0 end,
    				@pmco, @project, @phasegroup, @phase, @costtype, @slitemdesc, @um, @glco, @glacct, 
    				isnull(@wcretpct,0), isnull(@smretpct,0), @vendorgroup, @supplier, isnull(@units,0), 
    				isnull(@unitcost,0), isnull(@amount,0),
					@taxtype, @taxcode, @taxgroup, isnull(@taxamount,0), Notes,
					isnull(@taxamount,0) - (case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end),
					isnull(@taxrate,0), isnull(@gstrate,0) --DC #130175
			from bPMSL with (nolock) where PMCo=@pmco and Project=@project and SL=@sl and SLItem=@slitem and Seq=@pmslseq
			if @@rowcount <> 1
				BEGIN
				----#141349
				select @errtext = 'Could not insert SL: ' + ISNULL(@sl,'') + ' SL Item: ' + ltrim(convert(varchar(10),isnull(@slitem,''))) + ' into batch'
				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMSL_loop
				end
			end

		-- -- -- update IntFlag in PMSL to 'I', needed to update interface date in bspSLHBPost
		Update bPMSL set IntFlag='I'
		where PMCo=@pmco and Project=@project and SL=@sl and SLItem=@slitem and Seq=@pmslseq
		end

	-- -- -- if co type and does not exist in slit then add it with 0 amounts and add to slcd with change amount
	if @itemtype = 2
		begin
		set @slitemrowcount = 0
		if isnull(@pco,'') <> ''
			begin
			if not exists(select * from bSLIT where SLCo=@slco and SL=@sl and SLItem=@slitem)
				begin
				insert into bSLIT(SLCo, SL, SLItem, ItemType, Addon, AddonPct,JCCo, Job, PhaseGroup, Phase, 
    					JCCType, Description, UM, GLCo, GLAcct, WCRetPct, SMRetPct, VendorGroup, Supplier, 
    					OrigUnits, OrigUnitCost, OrigCost, CurUnits, CurUnitCost, CurCost, StoredMatls, InvUnits, 
    					InvCost, TaxType, TaxCode, TaxGroup, OrigTax, CurTax, InvTax, Notes, AddedMth, AddedBatchID,
    					JCCmtdTax, TaxRate, GSTRate)  --DC #130175
				select @slco, @sl, @slitem, @itemtype,
						case when @itemtype = 4 then @addon else null end, 
						case when @itemtype = 4 then isnull(@addonpct,0) else 0 end,
						@pmco, @project, @phasegroup, @phase, 
						@costtype, @slitemdesc, @um, @glco, @glacct, isnull(@wcretpct,0), isnull(@smretpct,0), 
    					@vendorgroup, @supplier, 0, 0, 0, 0, 0, 0, 0, 0, 0,
						@taxtype, @taxcode, @taxgroup, 0, 0, 0,
    					Notes, @mth, @slcbbatchid, 0, @taxrate, @gstrate --DC #130175
    			from bPMSL with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype 
    					and PCO=@pco and SL=@sl and SLItem=@slitem and Seq=@pmslseq
				select @slitemrowcount = @@rowcount
				if @slitemrowcount = 1
					begin
					-- -- -- #25100 update user memos from bPMSL to bSLIT
					exec @rcode = dbo.bspBatchUserMemoUpdatePMSL @slco, @mth, @slbatchid, @slhbseq, @sl, @slitem,
    									@pmco, @project, @pmslseq, 'SLIT', @errmsg output
					if @rcode <> 0
						BEGIN
						----#141349
						select @errtext = 'Could not update user memo for SL: ' + ISNULL(@sl,'') + ' SL Item: ' + convert(varchar(10),@slitem)
						exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output 
						select @errorcount = @errorcount + 1
						goto PMSL_loop
						end
					end
				end
			end
		else
			begin
			if not exists(select * from bSLIT where SLCo=@slco and SL=@sl and SLItem=@slitem)
				begin
				insert into bSLIT(SLCo, SL, SLItem, ItemType, Addon, AddonPct,JCCo, Job, PhaseGroup, Phase, JCCType,
						Description, UM, GLCo, GLAcct, WCRetPct, SMRetPct, VendorGroup, Supplier, OrigUnits, OrigUnitCost,
    					OrigCost, CurUnits, CurUnitCost, CurCost, StoredMatls, InvUnits, InvCost,
						TaxType, TaxCode, TaxGroup, OrigTax, CurTax, InvTax, Notes, AddedMth, AddedBatchID,
						JCCmtdTax, TaxRate, GSTRate)  --DC #130175)
				select @slco, @sl, @slitem, @itemtype,
   						case when @itemtype = 4 then @addon else null end, 
   						case when @itemtype = 4 then isnull(@addonpct,0) else 0 end,
   						@pmco, @project, @phasegroup, @phase,
    					@costtype, @slitemdesc, @um, @glco, @glacct, isnull(@wcretpct,0), isnull(@smretpct,0),
						@vendorgroup, @supplier, 0, 0, 0, 0, 0, 0, 0, 0, 0,
						@taxtype, @taxcode, @taxgroup, 0, 0, 0,
						Notes, @mth, @slcbbatchid,
						isnull(@taxamount,0) - (case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end), @taxrate, @gstrate --DC #130175 
				from bPMSL with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco 
						and SL=@sl and SLItem=@slitem and Seq=@pmslseq
				select @slitemrowcount = @@rowcount
				if @slitemrowcount = 1
					begin
					-- -- -- #25100 update user memos from bPMSL to bSLIT
					exec @rcode = dbo.bspBatchUserMemoUpdatePMSL @slco, @mth, @slbatchid, @slhbseq, @sl, @slitem,
    									@pmco, @project, @pmslseq, 'SLIT', @errmsg output
					if @rcode <> 0
						BEGIN
						----#141349
						select @errtext = 'Could not update user memo for SL: ' + ISNULL(@sl,'') + ' SL Item: ' + convert(varchar(10),@slitem)
						exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output 
						select @errorcount = @errorcount + 1
						goto PMSL_loop
						end
					end
				end
			end

		if @slitemrowcount = 1
			begin
			select @slseq=isnull(max(SLSeq),0)+1 from bPMBC with (nolock) 
			insert into bPMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
			select @pmco, @project, @mth, 'SLCB', @slcbbatchid, @slco, @slseq, @sl, @slitem, null, null
			end
		else
			BEGIN
			----#141349
			select @errtext = 'Could not insert SL: ' + ISNULL(@sl,'') + 'SL Item: ' + ltrim(convert(varchar(10),isnull(@slitem,''))) + ' into SLIT'
			exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1 
			goto PMSL_loop
			end

		-- -- -- add SL change order transaction to batch
		if isnull(@pco,'') <> ''
			begin
			select @slcbseq = isnull(max(BatchSeq),0)+1 from bSLCB where Co=@slco and Mth=@mth and BatchId=@slcbbatchid
			insert into bSLCB (Co, Mth, BatchId, BatchSeq, BatchTransType, SLTrans, SL, SLItem, SLChangeOrder, 
    					AppChangeOrder, ActDate, Description, UM, ChangeCurUnits, CurUnitCost, ChangeCurCost,
						PMSLSeq, ChgToTax, Notes)
			select @slco, @mth, @slcbbatchid, @slcbseq, 'A', null, @sl, @slitem, isnull(@slchangeorder,0), 
    					null, @actdate, @slitemdesc, @um, isnull(@units,0), isnull(@unitcost,0), isnull(@amount,0),
						@pmslseq, isnull(@taxamount,0),
    					Notes from bPMSL with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype
    					and PCO=@pco and SL=@sl and SLItem=@slitem and Seq=@pmslseq
			if @@rowcount <> 1
				BEGIN
				----#141349
				select @errmsg = 'Could not insert SL: ' + ISNULL(@sl,'') + ' SL Item: ' + ltrim(convert(varchar(10),isnull(@slitem,''))) + ' into SLCB'
				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slcbbatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMSL_loop
				end
			end
		else
			begin
			select @slcbseq = isnull(max(BatchSeq),0)+1 from bSLCB where Co=@slco and Mth=@mth and BatchId=@slcbbatchid
			insert into bSLCB (Co, Mth, BatchId, BatchSeq, BatchTransType, SLTrans, SL, SLItem, SLChangeOrder, 
    					AppChangeOrder, ActDate, Description, UM, ChangeCurUnits, CurUnitCost, ChangeCurCost,
						PMSLSeq, ChgToTax, Notes)
			select @slco, @mth, @slcbbatchid, @slcbseq, 'A', null, @sl, @slitem, isnull(@slchangeorder,0), 
    					@aco, @actdate, @slitemdesc, @um, isnull(@units,0), isnull(@unitcost,0), isnull(@amount,0),
						@pmslseq, isnull(@taxamount,0),
    					Notes from bPMSL with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and SL=@sl 
    					and SLItem=@slitem and Seq=@pmslseq
			if @@rowcount <> 1
				BEGIN
				----#141349
				select @errmsg = 'Could not insert SL: ' + ISNULL(@sl,'') + ' SL Item: ' + ltrim(convert(varchar(10),isnull(@slitem,''))) + ' into SLCB'
				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slcbbatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMSL_loop
				end
			end
		end

	if @itemtype = 3 or @itemtype = 4
		begin
		select @errtext = 'SL Item: ' + ltrim(convert(varchar(10),isnull(@slitem,''))) + ' must exist in SLIT.'
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
		end
	end
else
	-- -- -- insert into SLCB
	begin
	--DC #130175  -change orders to existing records use the tax rate stored in SLIt
	select @taxrate=TaxRate,@gstrate = GSTRate from bSLIT with (nolock) where SLCo=@slco and SL=@sl and SLItem=@slitem

	--DC #130175  New records use the current tax rate
	select @taxamount = (@amount * @taxrate)		--Full TaxAmount:  This is correct whether US, Intl GST&PST, Intl GST only, Intl PST only		1000 * .155 = 155
	select @gsttaxamt = case @taxrate when 0 then 0 else case @valueadd when 'Y' then (@taxamount * @gstrate) / @taxrate else 0 end end --GST Tax Amount.  (Calculated)					(155 * .05) / .155 = 50
	select @psttaxamt = case @valueadd when 'Y' then @taxamount - @gsttaxamt else 0 end			--PST Tax Amount.  (Rounding errors to PST)			

	---- #136053
	set @slcbunitcost = 0
	set @slcbcost = @amount
	-- -- -- get next available sequence # for this batch
	select @slcbseq = isnull(max(BatchSeq),0)+1 from bSLCB with (nolock) where Co = @slco and Mth = @mth and BatchId = @slcbbatchid
	-- -- -- add SL change order transaction to batch
	if isnull(@pco,'') <> ''
		begin
		select @slcbdesc = @slitemdesc
		insert into bSLCB (Co, Mth, BatchId, BatchSeq, BatchTransType, SLTrans, SL, SLItem, SLChangeOrder, 
    				AppChangeOrder, ActDate, Description, UM, ChangeCurUnits, CurUnitCost, ChangeCurCost,
					PMSLSeq, ChgToTax, Notes)
		select @slco, @mth, @slcbbatchid, @slcbseq, 'A', null, @sl, @slitem, isnull(@slchangeorder,0), 
    				null, @actdate, @slcbdesc, @um, isnull(@units,0), isnull(@slcbunitcost,0), isnull(@slcbcost,0),
					@pmslseq, isnull(@taxamount,0),
    				Notes from bPMSL with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype
    				and PCO=@pco and SL=@sl and SLItem=@slitem and Seq=@pmslseq
		if @@rowcount <> 1
			begin
			select @errmsg = 'Could not insert SL: ' + ISNULL(@sl,'') + ' SL Item: ' + convert(varchar(10),isnull(@slitem,'')) + 'into batch'
			exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slcbbatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1
			goto PMSL_loop
			end
		end
	else
		begin
		select @slcbdesc = @slitemdesc
		insert into bSLCB (Co, Mth, BatchId, BatchSeq, BatchTransType, SLTrans, SL, SLItem, SLChangeOrder, 
    				AppChangeOrder, ActDate, Description, UM, ChangeCurUnits, CurUnitCost, ChangeCurCost,
					PMSLSeq, ChgToTax, Notes)
		select @slco, @mth, @slcbbatchid, @slcbseq, 'A', null, @sl, @slitem, isnull(@slchangeorder,0), 
    				@aco, @actdate, @slcbdesc, @um, isnull(@units,0), isnull(@slcbunitcost,0), isnull(@slcbcost,0),
					@pmslseq, isnull(@taxamount,0),
    				Notes from bPMSL with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and SL=@sl and SLItem=@slitem and Seq=@pmslseq
		if @@rowcount <> 1
			begin
			select @errmsg = 'Could not insert SL: ' + ISNULL(@sl,'') + ' SL Item: ' + convert(varchar(10),isnull(@slitem,'')) + 'into batch'
			exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slcbbatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1
			goto PMSL_loop
			end
		end
	end


goto PMSL_loop


PMSL_end:
if @opencursor <> 0
	begin
	close bcPMSL
	deallocate bcPMSL
	select @opencursor = 0
	end

if @errorcount > 0
    begin
	-- -- -- undo everything
	delete bSLIB where Co=@slco and Mth=@mth and BatchId=@slbatchid
	delete bSLHB where Co=@slco and Mth=@mth and BatchId=@slbatchid
	delete bSLCB where Co=@slco and Mth=@mth and BatchId=@slcbbatchid

	if @slbatchid <> 0
		begin
		exec @rcode = dbo.bspHQBCExitCheck @slco,@mth,@slbatchid,'PM Intface','SLHB',@errmsg output
		if @rcode <> 0
			begin
			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel SLHB batch '
			end
		end

	if @slcbbatchid <> 0
		begin
		exec @rcode = dbo.bspHQBCExitCheck @slco,@mth,@slcbbatchid,'PM Intface','SLCB',@errmsg output
		if @rcode <> 0
			begin
			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel SLCB batch '
			end
		end

	select @slseq=min(SLSeq) from bPMBC with (nolock) where Co=@pmco and Project=@project and Mth=@mth
	and BatchId=@slcbbatchid and BatchTable='SLCB' and SL is not null
	while @slseq is not null
	begin
		select @sl=SL, @slitem=SLItem from bPMBC with (nolock) where Co=@pmco and Project=@project and Mth=@mth
		and BatchId=@slcbbatchid and BatchTable='SLCB' and BatchCo=@slco and SLSeq=@slseq
		delete bSLIT where SLCo=@slco and SL=@sl and SLItem=@slitem
    
		select @slseq=min(SLSeq) from bPMBC with (nolock) where Co=@pmco and Project=@project and Mth=@mth
		and BatchId=@slcbbatchid and BatchTable='SLCB' and SL is not null and SLSeq>@slseq
	end
    
	delete bPMBC where Co=@pmco and Project=@project and Mth=@mth
	and BatchId=@slcbbatchid and BatchTable='SLCB' and BatchCo=@slco

	update bPMSL set IntFlag=Null
	where PMCo=@pmco and Project=@project and SL is not null and InterfaceDate is null and IntFlag='I'
	select @rcode = 1
end




bspexit:
	if @opencursor <> 0
		begin
		close bcPMSL
		deallocate bcPMSL
		select @opencursor = 0
		end

	select @slstatus=Status from bHQBC with (nolock) 
	where Co=@slco and Mth=@mth and BatchId=@slbatchid and TableName='SLHB'
	select @slcbstatus=Status from bHQBC with (nolock) 
	where Co=@slco and Mth=@mth and BatchId=@slcbbatchid and TableName='SLCB'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSLACOInterface] TO [public]
GO
