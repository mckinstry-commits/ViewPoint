SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE  proc [dbo].[vspPMInterfaceSL]
/*************************************
* CREATED BY:	TRL 05/03/2011 TK-04412 new proced for PM Interface Projects (old proc 6.3.2 bspPMSLInterface)
* MODIFIED By:	GF 02/21/2011 - TK-05347
*				MV 10/25/2011 - TK-09243 - added NULL param to bspHQTaxRateGetAll
*				GF 12/19/2011 TK-11048 #145021 SL batch stuck in status 3
*				GF 01/17/2012 TK-11757 #145274 not recording HQBE row for inactive GL Account
*				GF 04/09/2012 TK-13873 #145073 validate comp group
*				GF 04/25/2012 TK-14423 146347 change to original subcontract list to show pending subct change orders
*				GF 04/30/2012 TK-14595 #146332 change to check HQBC for stuck PM interface batches
*				DAN SO 06/18/2012 - TK-15746 - validate Unit of Measure
*				GF 09/17/2012 - TK-17969 use vspHQTaxRateGet for gst rate (single level)
*				GF 10/09/2012 TK-18382 147184 display pending POCO for interface if approved
*				GF 11/09/2012 TK-18033 SL Claim Enhancement. Changed to Use ApprovalRequired
*				TL  01/24/2013 TK-20732 Added code to prevent a change order item from being udpated before the orginal item has been enterfaced
*
*
*
* USAGE:
* used by PMInterfaceProjects to interface a project or change order from PM to SL as specified
*
* Pass in :
*	PMCo, Project, Mth, GLCo
*
* Returns
*	Error message and return code
*
*******************************/
(@pmco bCompany, @project bJob, @sl VARCHAR(30), @mth bMonth, @glco bCompany, @slbatchid int output, @slhbstatus tinyint output,
@slcbbatchid int output, @slcbstatus tinyint output, @errmsg varchar(600) output)
as

set nocount on

declare @rcode int, @slhbseq int, @opencursor tinyint, @slco bCompany, @vendorgroup bGroup, @vendor bVendor,
@holdcode bHoldCode, @payterms bPayTerms, @compgroup varchar(10), @um bUM, @phasegroup bGroup,
@phase bPhase, @costtype bJCCType, @addon tinyint, @addonpct bPct, @units bUnits, @unitcost bUnitCost,
@amount bDollar, @wcretpct bPct, @smretpct bPct, @glacct bGLAcct, @errtext varchar(255), @pmslsl VARCHAR(30),
@slitem bItem, @errorcount int, @department bDept, @itemtype tinyint,
@contract bContract, @contractitem bContractItem, @approved bYN, @status tinyint,
@supplier bVendor, @pmslseq int, @subco smallint, @slcbseq tinyint, @aco bACO, @actdate bDate,
@slitemdesc bItemDesc, @slseq int, @activeyn bYN, @slitemexists tinyint, @slunitcost bUnitCost,
@slcbdesc bItemDesc, @inusebatchid bBatchID, @source bSource, @inusemth bMonth,
@uniqueattchid uniqueidentifier, @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint,
@taxphase bPhase, @taxct bJCCType, @taxjcum bUM, @taxrate bRate, @taxamount bDollar,
@valueadd varchar(1),
@gstrate bRate, @pstrate bRate, @HQTXdebtGLAcct bGLAcct, @gsttaxamt bDollar, @psttaxamt bDollar, --DC #130175
----#141349
@slitemerr varchar(50)

----TK-11048
select @rcode = 0, @errorcount = 0, @subco = 0, @slcbseq = 0,
	   @aco = null, @opencursor = 0
	   ----,@slcbbatchid = 0

---- get SLCo for this PMCo
select @slco=APCo 
from dbo.PMCO    
where PMCo=@pmco

---- set actual date
select @actdate = dbo.vfDateOnly()

---- check for data and then create batch
if exists (select 1 from dbo.PMSL a where a.PMCo=@pmco and a.Project=@project and a.SLCo=@slco
				and a.SL=@sl AND a.SubCO IS NULL and a.SendFlag='Y'and a.InterfaceDate is NULL
				----TK-14423
				----and (a.RecordType='O' OR (a.RecordType = 'C' AND (a.ACO IS NOT NULL))
		and exists(select 1 from dbo.SLHD b where b.SLCo=a.SLCo and b.SL=a.SL and ISNULL(b.Approved, 'Y') = 'Y'))
	begin
		--Reset Batch Status to Open to allow posting of new records
		If @slbatchid <> 0 and @slhbstatus =3 
		begin
			Update dbo.HQBC
			set [Status] = 0
			Where Co=@slco and Mth=@mth and BatchId=@slbatchid
		end
			
		If @slbatchid = 0
		begin
			exec @slbatchid = dbo.bspHQBCInsert @slco, @mth, 'PM Intface', 'SLHB', 'N', 'N', null, null, @errmsg output
			if @slbatchid = 0
			begin
				select @errmsg = @errmsg + ' - Cannot create SL batch'
				goto vspexit
			end
		end
		
		-- insert batchid into PMBC
		select @slseq=isnull(max(SLSeq),0)+1 from bPMBC    
		
		insert into dbo.PMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
		select @pmco, @project, @mth, 'SLHB', @slbatchid, @slco, @slseq, null, null, null, null
	end
else
	begin
		goto vspexit
	end


---- declare cursor on PMSL Subcontract Detail for interface to SLHB and SLIT
declare bcPMSL cursor LOCAL FAST_FORWARD
for select Seq,a.SL,SLItem,a.VendorGroup,a.Vendor,SLItemType,SLAddon,isnull(SLAddonPct,0),PhaseGroup,Phase,CostType,
SLItemDescription,UM,isnull(WCRetgPct,0),isnull(SMRetgPct,0),Supplier,SubCO,isnull(Units,0),isnull(UnitCost,0),isnull(Amount,0),
TaxGroup, TaxType, TaxCode
from dbo.PMSL a    
where a.PMCo=@pmco and a.Project=@project
	AND a.SLCo=@slco
	AND a.SL=@sl 
	AND a.SLItem IS NOT NULL
	AND a.SendFlag='Y' 
	AND a.InterfaceDate is NULL
	AND a.SubCO IS NULL
	----TK-14423
	----AND (a.RecordType = 'O' OR
	----	 (a.RecordType = 'C' AND a.ACO IS NOT NULL))
AND (a.RecordType = 'O' OR
		 (a.RecordType = 'C' AND NOT EXISTS(SELECT 1 FROM dbo.bPMSL b
					where b.PMCo = a.PMCo
						and b.Project = a.Project
						AND b.SLCo = a.SLCo
						AND b.SL = a.SL
						AND b.SLItem = a.SLItem
						AND b.SendFlag='Y' 
						AND b.InterfaceDate is NULL
						AND b.SubCO IS NULL
						AND b.RecordType = 'O')))     

	
group by a.SL,SLItem,SLItemType,Seq,a.VendorGroup,a.Vendor,SLAddon,SLAddonPct,PhaseGroup,Phase,CostType,SLItemDescription,UM,
WCRetgPct,SMRetgPct,Supplier,SubCO,Units,UnitCost,Amount,TaxGroup, TaxType, TaxCode

-- open cursor
open bcPMSL

-- set open cursor flag to true
select @opencursor = 1

PMSL_loop:
fetch next from bcPMSL into @pmslseq,@pmslsl,@slitem,@vendorgroup,@vendor,@itemtype,@addon,@addonpct,@phasegroup,@phase,@costtype,
@slitemdesc,@um,@wcretpct,@smretpct,@supplier,@subco,@units,@unitcost,@amount, @taxgroup, @taxtype, @taxcode

if @@fetch_status <> 0 goto PMSL_end

---- get needed SLHD information
select @holdcode=HoldCode, @payterms=PayTerms, @compgroup=CompGroup, @approved=Approved, @status=Status,
@inusebatchid=InUseBatchId, @inusemth=InUseMth, @uniqueattchid=UniqueAttchID
from dbo.SLHD    
where SLCo=@slco and SL=@sl and VendorGroup=@vendorgroup and Vendor=@vendor

if @status=3 and ISNULL(@approved,'Y') = 'N' goto PMSL_loop

---- TK-01723
if ISNULL(@subco,0) > 0
begin
	if exists(select top 1 1 from dbo.PMSubcontractCO c where c.SLCo=@slco and c.SL=@sl
	and c.SubCO=@subco and c.ReadyForAcctg = 'N')
	begin
		goto PMSL_loop
	end
end

-- Validate record prior to inserting into batch table
if @inusebatchid is not null
begin
	select @source=Source from dbo.HQBC    
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

--#141349 - TK-01723 
select @slitemerr = ' SL: ' + isnull(@sl,'') + ' SL Item: ' + convert(varchar(6),isnull(@slitem,''))
-- #129258
if @itemtype <> 2 and (@subco = 0 OR @subco is null) 
and exists(select 1 from dbo.SLIT    where SLCo=@slco and SL=@sl and SLItem=@slitem)
	begin
		----#141349
		select @errtext = @slitemerr + ' already exists.'
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
	end
else
begin
	-- Validate Phase and Costtype
	exec @rcode = dbo.bspJCADDPHASE @pmco,@project,@phasegroup,@phase,'Y',null,@errmsg output
	if @rcode <> 0
	BEGIN
		--#141349
		select @errtext = @errmsg + @slitemerr
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
	end

	--#141264 the vendor cannot equal the supplier
	IF @supplier IS NOT NULL AND @supplier = @vendor
	BEGIN
		select @errtext = 'Supplier cannot be the same as the vendor.' + @slitemerr
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
	END

	-- validate cost type
	exec @rcode = dbo.bspJCADDCOSTTYPE @jcco=@pmco, @job=@project, @phasegroup=@phasegroup, @phase=@phase, @costtype=@costtype, @um=@um, @override= 'P', @msg=@errmsg output
	if @rcode<>0
	begin
		--#141349
		select @errtext = @errmsg + @slitemerr
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
	end

	-- update active flag if needed
	select @activeyn=ActiveYN 
	from dbo.JCCH    
	where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
	if @activeyn <> 'Y'
	begin
		update dbo.JCCH 
		set ActiveYN = 'Y'
		where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
	end

	-- Get GLAcct
	select @contract=Contract, @contractitem=Item
	from dbo.JCJP    
	where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase

	select @department=Department
	from dbo.JCCI    
	where JCCo=@pmco and Contract=@contract and Item=@contractitem
	if @department is null
	begin
		select @errtext = 'Department for Contract: ' + convert(varchar(10),isnull(@contract,'')) + 'may not be null'
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
	end

	-- Get GLAcct
	select @glacct = null
	exec @rcode = dbo.bspJCCAGlacctDflt @pmco, @project, @phasegroup, @phase, @costtype, 'N', @glacct output, @errmsg output

	if @glacct is null
	begin
		select @errtext = 'GL Acct for Cost Type: ' + convert(varchar(3),isnull(@costtype,'')) + ' may not be null'
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
	end

	exec @rcode = dbo.bspGLACfPostable @glco, @glacct, 'J', @errmsg output
	if @rcode <> 0
	begin
		select @errtext = '- GLAcct:' + isnull(@glacct,'') + ':  ' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg OUTPUT
		----TK-11757
		SELECT @errorcount = @errorcount + 1
		GOTO PMSL_loop
		----if @rcode <> 0 goto vspexit
	end

	exec @rcode = dbo.bspGLMonthVal @glco, @mth, @errmsg output
	if @rcode <> 0
	begin
		select @errtext = ' - ' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg OUTPUT
		----TK-11757
		SELECT @errorcount = @errorcount + 1
		GOTO PMSL_loop
		----if @rcode <> 0 goto vspexit
	end

	-- VALIDATE UM -- TK-15746 --
	EXEC @rcode = dbo.bspHQUMVal @um, @errmsg output
	IF @rcode <> 0
		BEGIN
			SET @errtext = ISNULL(@errmsg,'') + '('+ ISNULL(@um,'') + ') ' + @slitemerr
			EXEC @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
			SET @errorcount = @errorcount + 1
			GOTO PMSL_loop
		END

	-- check units to UM
	if @um = 'LS' and @units <> 0
	begin
		--#141349
		select @errtext = 'Units must be zero when UM is (LS).' + @slitemerr
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
	end

	-- check unit cost to UM
	if @um = 'LS' and @unitcost <> 0
	begin
		--#141349
		select @errtext = 'Unit cost must be zero when UM is (LS).' + @slitemerr
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
	end

	-- #131843 if units = 0, amount <> 0, and @um <> 'LS' we do not want to send to Acct. Committed Cost get closed
	if isnull(@units,0) = 0 and isnull(@amount,0) <> 0 and isnull(@um,'LS') <> 'LS'
	begin
		--#141349
		select @errtext = 'Units and Amount cannot be zero when UM is not (LS).' + @slitemerr
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
	end

	if @taxtype is null and @taxcode is not null
	begin
		--#141349
		select @errtext = 'Tax Code assigned, but missing Tax Type for subcontract item.' + @slitemerr
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
	end

	-- check for duplicate item record with different phase/costtype/um combination
	if exists(select 1 from dbo.PMSL where PMCo=@pmco and Project=@project and SLCo=@slco
					and Vendor=@vendor and SL=@sl and SLItem=@slitem and Seq<>@pmslseq and InterfaceDate is null
					and SendFlag = 'Y'  and (Phase<>@phase or CostType<>@costtype or UM<>@um))
					----TK-14423
					--and RecordType='O' 
	begin
		select @errtext = 'SL: ' + isnull(@sl,'') + ' SLItem: ' + convert(varchar(8),isnull(@slitem,0)) + ' - Multiple records set up for same item with different Phase/CostType/UM combination.'
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
	end

	---- check original PMSL for item not interfaced yet
	--if exists (select 1 from dbo.PMSL where PMCo=@pmco and Project=@project
	--					AND	SL=@pmslsl AND SLItem=@slitem AND SLCo=@slco 
	--					AND RecordType='O' AND Seq <> @pmslseq 
	--					AND InterfaceDate is NULL AND SubCO IS NULL)
	--begin
	--	select @errtext = 'SL: ' + ISNULL(@pmslsl,'') + ' SL Item: ' + ltrim(convert(varchar(10),isnull(@slitem,''))) + ' exists in PMSL and must be interfaced first.'
	--	exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
	--	select @errorcount = @errorcount + 1
	--	goto PMSL_loop
	--END
	
	-- if tax code assigned, validate tax phase and cost type then calculate tax
	-- ANY CHANGES MADE TO THIS ROUTINE NEED TO ALSO BE DONE IN bspPMSLACOInterface,
	-- bspPMPOInterface, bspPMPOACOInterface, and vspPMSLCreateSLItem. The logic should
	-- be similar between the procedures working with tax codes.
	if @taxcode is null
		begin
			select @taxamount=0,@taxrate = 0, @gstrate = 0 --DC #130175
		end
	else
		begin
			select @taxphase = null, @taxct = null
			
			-- validate Tax Code
			exec @rcode = dbo.bspPOTaxCodeVal @taxgroup, @taxcode, @taxtype, @taxphase output, @taxct output, @errmsg output
			if @rcode <> 0
			begin
				select @errtext = isnull(@errmsg,'')
				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMSL_loop
			end
			-- validate Tax Phase if Job Type
			if @taxphase is null select @taxphase = @phase
			if @taxct is null select @taxct = @costtype
			-- validate tax phase - if does not exist try to add it
			exec @rcode = dbo.bspJCADDPHASE @pmco, @project, @phasegroup, @taxphase, 'Y', null, @errmsg output
			-- if phase/cost type does not exist in JCCH try to add it
			if not exists(select top 1 1 from dbo.JCCH where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup
				and Phase=@taxphase and CostType=@taxct)
			begin
				-- insert cost header record
				insert into dbo.JCCH (JCCo,Job,PhaseGroup,Phase,CostType,UM,BillFlag,ItemUnitFlag,PhaseUnitFlag,BuyOutYN,Plugged,ActiveYN,SourceStatus)
				select @pmco, @project, @phasegroup, @taxphase, @taxct, 'LS', 'C', 'N', 'N', 'N', 'N', 'Y', 'I'
			end
			-- validate Tax phase and Tax Cost Type
			exec @rcode = dbo.bspJobTypeVal @pmco, @phasegroup, @project, @taxphase, @taxct, @taxjcum output, @errmsg output
			if @rcode <> 0
			begin
				select @errtext = 'Tax: ' + isnull(@errmsg,'')
				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMSL_loop
			end

			-- calculate tax
			select @taxrate = 0, @gstrate = 0, @pstrate = 0	
			--DC #130175
			--exec @rcode = dbo.bspHQTaxRateGetAll @taxgroup, @taxcode, @actdate, @valueadd output, @taxrate output, @gstrate output, @pstrate output, 
			--null, null, @HQTXdebtGLAcct output, null, null, null, NULL, @errmsg output
			----TK-17969		
			exec @rcode = dbo.vspHQTaxRateGet    @taxgroup, @taxcode, @actdate, @valueadd output, @taxrate output, NULL, NULL, 
						@gstrate output, @pstrate output, null, null, @HQTXdebtGLAcct output, null, null, null, @errmsg output
	

			----DC #130175	
			--if @gstrate = 0 and @pstrate = 0 and @valueadd = 'Y'
			--begin
			---- We have an Intl VAT code being used as a Single Level Code
			--	if (select GST from dbo.HQTX    where TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
			--	begin
			--		select @gstrate = @taxrate
			--	end
			--end
			--Full TaxAmount: This is correct whether US, Intl GST&PST, Intl GST only, Intl PST only 1000 * .155 = 155
			select @taxamount = (@amount * @taxrate)
			 --GST Tax Amount. (Calculated)(155 * .05) / .155 = 50
			select @gsttaxamt = case @taxrate when 0 then 0 else case @valueadd when 'Y' then (@taxamount * @gstrate) / @taxrate else 0 end end
			--PST Tax Amount. (Rounding errors to PST)
			select @psttaxamt = case @valueadd when 'Y' then @taxamount - @gsttaxamt else 0 end			
		end   

	-- Insert record
	-- get next available sequence # for slhb batch
	if exists (select 1 from dbo.SLHB    where Co=@slco and Mth=@mth and BatchId=@slbatchid and SL=@sl)
		begin
			select @slhbseq=BatchSeq from dbo.SLHB    where Co=@slco and Mth=@mth and BatchId=@slbatchid and SL=@sl
		end
	else
begin
	select @slhbseq = isnull(max(BatchSeq),0)+1 from dbo.SLHB    where Co = @slco and Mth = @mth and BatchId = @slbatchid
	insert into dbo.SLHB (Co, Mth, BatchId, BatchSeq, BatchTransType, SL, JCCo, Job,[Description],VendorGroup,
	Vendor, HoldCode, PayTerms, CompGroup, [Status], OrigDate, OldJCCo, OldJob, OldDesc, OldVendor,OldHoldCode,
	OldPayTerms, OldCompGroup, OldStatus, UniqueAttchID, Notes,
	----#142798
	MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN, MaxRetgDistStyle
	----TK-18033
	,ApprovalRequired)
	select @slco, @mth, @slbatchid, @slhbseq, 'C', @sl, JCCo, Job, [Description], @vendorgroup,
	@vendor, HoldCode, PayTerms, CompGroup, 0, OrigDate, JCCo, Job, [Description], @vendor, HoldCode,
	PayTerms, CompGroup, 3, @uniqueattchid, Notes,
	----#142798
	MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN, MaxRetgDistStyle
	----TK-18033
	,ApprovalRequired
	from dbo.SLHD    
	where SLCo=@slco and SL=@sl
	if @@rowcount <> 1
		begin
			select @errtext = 'Could not insert SL: ' + isnull(@sl,'') + ' into batch'
			exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1
			goto PMSL_loop
		end
	else
		begin
			-- update user memo to SLHB batch table- BatchUserMemoInsertExisting
			exec @rcode = dbo.bspBatchUserMemoInsertExisting @slco, @mth, @slbatchid, @slhbseq, 'SL Entry', 0, @errmsg output
			if @rcode <> 0
			begin
				select @errtext = 'Unable to update user memo to SL: ' + isnull(@sl,'') + ' Batch'
				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMSL_loop
			end

			-- Insert SL Inclusions/Exclusions - JG TFS# 491
			INSERT INTO dbo.SLInExclusionsBatch (Co, BatchId, Mth, BatchSeq, Seq,
					BatchTransType, [Type], PhaseGroup, Phase, Detail, DateEntered, EnteredBy,
					Notes, UniqueAttchID)
			SELECT @slco, @slbatchid, @mth, @slhbseq, Seq, 'C', [Type], PhaseGroup, Phase,
					Detail, DateEntered, EnteredBy, Notes, UniqueAttchID
			FROM dbo.SLInExclusions
			WHERE Co=@slco and SL=@sl 
		end
	end

	-- validate hold code, pay terms, compliance group for SLHB
	select @holdcode=HoldCode, @payterms=PayTerms, @compgroup = CompGroup
	from dbo.SLHB 
	where Co=@slco and Mth=@mth and BatchId=@slbatchid and BatchSeq=@slhbseq
	if @@rowcount <> 0
		BEGIN
		-- validate Hold Code
		if isnull(@holdcode,'') <> ''
			begin
			if not exists(select top 1 1 from dbo.HQHC where HoldCode=@holdcode)
				begin
				select @errtext = 'Invalid hold code: ' + isnull(@holdcode,'') + ' for SL: ' + isnull(@sl,'') + '.'
				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMSL_loop
				end
			end
		-- validate pay terms
		if isnull(@payterms,'') <> ''
			begin
			if not exists(select top 1 1 from dbo.HQPT where PayTerms=@payterms)
				begin
				select @errtext = 'Invalid pay terms: ' + isnull(@payterms,'') + ' for SL: ' + isnull(@sl,'') + '.'
				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMSL_loop
				end
			END
		----TK-13873 validate comp group
		if isnull(@compgroup,'') <> ''
			BEGIN
 			IF NOT EXISTS(SELECT 1 FROM dbo.HQCG WHERE CompGroup = @compgroup)
	 			BEGIN
	 			SELECT @errtext = 'Invalid Compliance group ' + dbo.vfToString(@compgroup) + ' for SL: ' + dbo.vfToString(@sl)
				EXEC @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
				SELECT @errorcount = @errorcount + 1
				GOTO PMSL_loop
     			END
			END
		END

	-- when item type 2 - change order and no subco, try to insert into SLIB
	if @itemtype <> 2 and (@subco = 0 or @subco is null)
		begin
			insert into dbo.SLIB(Co, Mth, BatchId, BatchSeq, SLItem, BatchTransType, ItemType, Addon, AddonPct,
			JCCo, Job, PhaseGroup, Phase, JCCType, [Description], UM, GLCo, GLAcct, WCRetPct,
			SMRetPct, VendorGroup, Supplier, OrigUnits, OrigUnitCost, OrigCost,
			TaxType, TaxCode, TaxGroup, OrigTax, Notes,
			JCCmtdTax, TaxRate, GSTRate)  --DC#130175
			select @slco, @mth, @slbatchid, @slhbseq, @slitem, 'A', @itemtype, 
			case when @itemtype = 4 then @addon else null end, 
			case when @itemtype = 4 then isnull(@addonpct,0) else 0 end,
			@pmco, @project, @phasegroup, @phase, @costtype, @slitemdesc, @um, @glco, @glacct, @wcretpct,
			@smretpct, @vendorgroup, @supplier, @units, @unitcost, @amount, @taxtype, @taxcode, @taxgroup, @taxamount,
			Notes,
			isnull(@taxamount,0) - (case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end), @taxrate, @gstrate --DC #130175
			from dbo.PMSL    
			where PMCo=@pmco and Project=@project and SL=@sl and SLItem=@slitem and Seq=@pmslseq
			if @@rowcount = 1
			begin
				-- #25100 update user memos from PMSL to SLIB or SLIT depending on the table being inserted
				exec @rcode = dbo.bspBatchUserMemoUpdatePMSL @slco, @mth, @slbatchid, @slhbseq, @sl, @slitem,
				@pmco, @project, @pmslseq, 'SLIB', @errmsg output
				if @rcode <> 0
				begin
					select @errtext = 'Could not update user memo for SL: ' + ISNULL(@sl,'') + ' SL Item: ' + convert(varchar(10),@slitem)
					exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output 
					select @errorcount = @errorcount + 1
					goto PMSL_loop
				end
			end
		end
	else
		begin
			--Reset Batch Status to Open to allow posting of new records
			If @slcbbatchid <> 0 and @slcbstatus =3
			begin
				Update dbo.HQBC
				set [Status] = 0
				----TK-11048
				Where Co=@slco and Mth=@mth and BatchId=@slcbbatchid
			end
			
			if @slcbbatchid = 0
			begin
				exec @slcbbatchid = dbo.bspHQBCInsert @slco, @mth, 'PM Intface', 'SLCB', 'N', 'N', null, null, @errmsg output
				if @slcbbatchid = 0
				begin
					select @errmsg = isnull(@errmsg,'') + ' - Cannot create SLCB batch'
					goto vspexit
				end

				-- insert batchid into PMBC
				select @slseq=isnull(max(SLSeq),0)+1 
				from dbo.PMBC 
				
				insert into bPMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
				select @pmco, @project, @mth, 'SLCB', @slcbbatchid, @slco, @slseq, null, null, null, null
			end

			select @slcbseq = isnull(max(BatchSeq),0)+1 from dbo.SLCB where Co = @slco and Mth = @mth and BatchId = @slcbbatchid
			select @slitemexists=1
			if not exists (select top 1 1 from dbo.SLIT where SLCo=@slco and SL=@sl and SLItem=@slitem)
			begin
				select @slitemexists=0
				insert into dbo.SLIT(SLCo, SL, SLItem, ItemType, Addon, AddonPct, JCCo, Job, PhaseGroup, Phase,
						JCCType, [Description], UM, GLCo, GLAcct, WCRetPct, SMRetPct, VendorGroup, Supplier,
						OrigUnits, OrigUnitCost, OrigCost, CurUnits, CurUnitCost, CurCost, StoredMatls,
						InvUnits, InvCost, TaxType, TaxCode, TaxGroup, OrigTax, CurTax, InvTax, Notes,
						JCCmtdTax, TaxRate, GSTRate)  --DC #130175
				select @slco, @sl, @slitem, @itemtype,
						case when @itemtype = 4 then @addon else null end, 
						case when @itemtype = 4 then isnull(@addonpct,0) else 0 end,
						@pmco, @project, @phasegroup, @phase,
						@costtype, @slitemdesc, @um, @glco, @glacct, isnull(@wcretpct,0), isnull(@smretpct,0),
						@vendorgroup, @supplier, 0, 0, 0, 0, 0, 0, 0, 0, 0,
						@taxtype, @taxcode, @taxgroup, 0, 0, 0, Notes,
						isnull(@taxamount,0) - (case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end), @taxrate, @gstrate --DC #130175				  
				from dbo.PMSL 
				where PMCo=@pmco and Project=@project and SL=@sl and SLItem=@slitem and Seq=@pmslseq
				if @@rowcount <> 1
					begin
						select @errtext = 'Could not insert SL: ' + ISNULL(@sl,'') + ' SL Item: ' + convert(varchar(10),@slitem) + 'into batch'
						exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
						select @errorcount = @errorcount + 1
						goto PMSL_loop
					end
				else
					begin
					-- #25100 update user memos from bPMSL to SLIT
					exec @rcode = dbo.bspBatchUserMemoUpdatePMSL @slco, @mth, @slbatchid, @slhbseq, @sl, @slitem,
					@pmco, @project, @pmslseq, 'SLIT', @errmsg output
					if @rcode <> 0
						begin
						select @errtext = 'Could not update user memo for SL: ' + ISNULL(@sl,'') + ' SL Item: ' + convert(varchar(10),@slitem)
						exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output 
						select @errorcount = @errorcount + 1
						goto PMSL_loop
						END
					---- insert SLBC record to note that a SLIT zero item has been added in case error occurs
					select @slseq=isnull(max(SLSeq),0)+1 from bPMBC    
					insert into dbo.PMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
					select @pmco, @project, @mth, 'SLCB', @slcbbatchid, @slco, @slseq, @sl, @slitem, null, null
					end
			end


			if @slitemexists=1
				begin
					select @slunitcost=0
				end
			else
				begin
					select @slunitcost=@unitcost
				end

			select @slcbdesc = @slitemdesc
			insert into dbo.SLCB (Co, Mth, BatchId, BatchSeq, BatchTransType, SLTrans, SL, SLItem, SLChangeOrder,
			AppChangeOrder, ActDate, [Description], UM, ChangeCurUnits, CurUnitCost, ChangeCurCost,
			PMSLSeq, ChgToTax, Notes)
			select @slco, @mth, @slcbbatchid, @slcbseq, 'A', null, @sl, @slitem, isnull(@subco,0),
			@aco, @actdate, @slcbdesc, @um, isnull(@units,0), @slunitcost, isnull(@amount,0),
			@pmslseq, @taxamount,Notes 
			from dbo.PMSL 
			where PMCo=@pmco and Project=@project and SL=@sl and SLItem=@slitem and Seq=@pmslseq
			if @@rowcount <> 1
			begin
				select @errmsg = 'Could not insert SL: ' + ISNULL(@sl,'') + ' SL Change Item: ' + ltrim(convert(varchar(10),@slitem)) + ' into SLCB'
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
	-- clear SLHB, SLIB and SL Inclusion/Exclusion batches
	exec @rcode = dbo.bspSLBatchClear @slco, @mth, @slbatchid, @errmsg output
	if @rcode <> 0
	begin
		select @errmsg = @errmsg + ' - cannot cancel SLHB batch'
	end

	-- clear SLCB batch if applicable
	if @slcbbatchid <> 0
	begin
		exec @rcode = dbo.bspSLBatchClear @slco, @mth, @slcbbatchid, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = @errmsg + ' - cannot cancel SLCB batch'
		end

		select @slseq=min(SLSeq)
		from dbo.PMBC 
		where Co=@pmco and Project=@project and Mth=@mth
		and BatchId=@slcbbatchid and BatchTable='SLCB' and SL is not null
		while @slseq is not null
		begin
			select @sl=SL, @slitem=SLItem 
			from dbo.PMBC 
			where Co=@pmco and Project=@project and Mth=@mth and BatchId=@slcbbatchid
			and BatchTable='SLCB' and BatchCo=@slco and SLSeq=@slseq

			delete dbo.SLIT 
			where SLCo=@slco and SL=@sl and SLItem=@slitem

			select @slseq=min(SLSeq)
			from dbo.PMBC 
			where Co=@pmco and Project=@project and Mth=@mth and BatchId=@slcbbatchid and 
			BatchTable='SLCB' and SL is not null and SLSeq>@slseq
		end

		----TK-14595
		delete dbo.PMBC 
		where Co=@pmco and Project=@project
			and Mth=@mth
			and BatchId=@slcbbatchid
			and BatchTable='SLCB' 
			and BatchCo=@slco
			AND SL IS NOT NULL
			AND SLItem IS NOT NULL
	end
	select @rcode = 1
end



vspexit:
	if @opencursor <> 0
	begin
		close bcPMSL
		deallocate bcPMSL
		select @opencursor = 0
	end

	select @slhbstatus=[Status]
	from dbo.HQBC 
	where Co=@slco and Mth=@mth and BatchId=@slbatchid
	
	select @slcbstatus=[Status] 
	from dbo.HQBC 
	where Co=@slco and Mth=@mth and BatchId=@slcbbatchid

	select @errmsg = IsNull(@errmsg,'') + ' ' + isnull(@errtext,'')
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspPMInterfaceSL] TO [public]
GO
