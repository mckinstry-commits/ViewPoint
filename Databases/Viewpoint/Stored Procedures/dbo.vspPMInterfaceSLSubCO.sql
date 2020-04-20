SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/****************************************/
CREATE  proc [dbo].[vspPMInterfaceSLSubCO]
/*****************************************
 * Created By:	TRL 05/03/2011 TK-04412 
 * Modified By:	GF 05/26/2011 TK-05347 TK-05531 TK-05548
 *				MV 10/25/2011 TK-09243 added NULL param to bspHQTaxRateGetAll
 *				DAN SO 11/21/2011 D-03631 - SubCO error message not being recorded properly
 *				GF 01/08/2011 TK-11623 #145454 PCO detail not validating
 *				GF TK-12623 ISSUE #145842 possible duplicate index error inserting SLIB rows
 *				GF 03/08/2012 TK-13086 allow for different jobs to SL/SCO to inteface
 *				GF 04/30/2012 TK-14595 #146332 change to check HQBC for stuck PM interface batches
 *				DAN SO 06/18/2012 - TK-15746 - validate Unit of Measure
 *				GF 09/17/2012 - TK-17969 use vspHQTaxRateGet for gst rate (single level)
 *				GF 10/09/2012 TK-18382 147184 display pending POCO for interface if approved
 *              JayR TK-16099 Fix issue with overlapping variables.
 *				GF 11/09/2012 TK-18033 SL Claim Enhancement. Changed to Use ApprovalRequired
 *              AW 01/08/2013 TK-20643 return error if GLAcct is invalid
 *
 * USAGE:
 * used by PMInterface to interface a project or change order from PM to SL as specified
 *
 * Pass in :
 *	PMCo, Project, Mth, GLCo, SL Batchid, Batch Status, errmsg
 *
 *
 * Returns
 *	SL Batchid, Batch Status, Error message and return code
 *
 *******************************************************/
(@pmco bCompany = NULL, @project bJob = NULL, @mth bMonth = NULL,
 @glco bCompany = NULL, @sl VARCHAR(30) = NULL, @SubCO SMALLINT = NULL,
 @slbatchid INT = NULL OUTPUT, @slcbbatchid INT = NULL OUTPUT,
 @slstatus TINYINT = NULL OUTPUT, @slcbstatus TINYINT = NULL OUTPUT,
 @errmsg varchar(max) output)
 
AS
SET NOCOUNT ON

declare @rcode int, @slhbseq int, @opencursor tinyint, @slco bCompany, @vendorgroup bGroup,
        @vendor bVendor, @holdcode bHoldCode, @payterms bPayTerms, @compgroup varchar(10),
        @um bUM, @phasegroup bGroup, @phase bPhase, @costtype bJCCType, @addon tinyint, @addonpct bPct,
        @pmslseq int, @units bUnits, @unitcost bUnitCost, @ecm bECM, @amount bDollar, @wcretpct bPct, 
        @smretpct bPct, @glacct bGLAcct, @errtext varchar(255), @pmslsl VARCHAR(30),
        @slitem bItem, @errorcount int, @status tinyint, @itemtype tinyint,
        @slitemrowcount int,
        @contract bContract, @contractitem bContractItem, @department bDept, @slcbseq int, @approved bYN,
        @slchangeorder smallint, @supplier bVendor, @activeyn bYN, @slcbunitcost bUnitCost, @slcbcost bDollar,
        @slitemdesc bItemDesc, @slseq int, @slititem bItem, @slcbdesc bItemDesc, @pcotext varchar(100),
   		@ApprovedDate bDate, @inusebatchid bBatchID, @source bSource, @inusemth bMonth,
   		@uniqueattchid uniqueidentifier, @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint,
		@taxphase bPhase, @taxct bJCCType, @taxjcum bUM, @taxrate bRate, @taxamount bDollar,
		@valueadd varchar(1), @gstrate bRate, @pstrate bRate, @HQTXdebtGLAcct bGLAcct,
		@gsttaxamt bDollar, @psttaxamt bDollar, @PCOType bDocType, @PCO bACO, @PCOItem bACOItem,
		@ACO bACO, @ACOItem bACOItem, @PMSL_KeyID BIGINT, @slitemerr VARCHAR(MAX),
		----TK-13086
		@PMSL_Project bJob, @SLIT_JCCo bCompany, @SLIT_Job bJob, @SLItemExists CHAR(1)
		
SET @rcode = 0
SET @errorcount = 0
SET @slitemrowcount = 0
SET @opencursor = 0

-- -- -- get SLCo for this PMCo
select @slco=APCo 
from dbo.PMCO    
where PMCo=@pmco

---------------------
-- D-03631 (start) --
---------------------
---- check for data and then create batch
if exists (select 1 from dbo.PMSL a where a.PMCo=@pmco
				----TK-13086
				----AND a.Project=@project
				AND a.SLCo=@slco
				AND a.SL=@sl
				AND a.SubCO = @SubCO
				AND a.SendFlag='Y' 
				AND a.InterfaceDate IS NULL
				----TK-11623
				----and (a.RecordType='O' OR (a.RecordType = 'C' AND a.ACO IS NOT NULL))
		and exists(select 1 from dbo.SLHD b where b.SLCo=a.SLCo and b.SL=a.SL and ISNULL(b.Approved,'Y') = 'Y'))
	begin
		--Reset Batch Status to Open to allow posting of new records
		If @slbatchid <> 0 and @slstatus =3 
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
-------------------
-- D-03631 (end) --
-------------------


-- declare cursor on PMSL Subcontract Detail for interface to SLCB Change Order Batch
declare bcPMSL cursor LOCAL FAST_FORWARD for 
SELECT Seq, SL, SLItem, VendorGroup, Vendor, SLItemType, SLAddon, isnull(SLAddonPct,0),
		PhaseGroup, Phase, CostType, SLItemDescription, UM, isnull(WCRetgPct,0),
		isnull(SMRetgPct,0), Supplier, isnull(SubCO,0), isnull(Units,0), isnull(UnitCost,0),
		isnull(Amount,0), TaxGroup, TaxType, TaxCode, PCOType, PCO, PCOItem,
		ACO, ACOItem, KeyID,
		----TK-13086
		Project
FROM dbo.bPMSL 
WHERE PMCo=@pmco 
	----TK-13086
	----AND Project=@project
	AND SLCo=@slco 
	AND SL = @sl
	AND SubCO = @SubCO
	AND SendFlag='Y'
	AND InterfaceDate IS NULL
GROUP BY SL, SLItem, SLItemType, Seq, VendorGroup, Vendor, SLAddon, SLAddonPct, PhaseGroup,
		Phase, CostType, SLItemDescription, UM, WCRetgPct, SMRetgPct, Supplier, SubCO,
		Units, UnitCost, Amount, TaxGroup, TaxType, TaxCode, PCOType, PCO, PCOItem,
		ACO, ACOItem, KeyID
		----TK-13086
		,Project

-- open cursor
open bcPMSL

-- set open cursor flag to true
select @opencursor = 1

PMSL_loop:
fetch next from bcPMSL into @pmslseq, @pmslsl, @slitem, @vendorgroup, @vendor, @itemtype,
		@addon, @addonpct, @phasegroup, @phase, @costtype, @slitemdesc, @um, @wcretpct,
		@smretpct, @supplier, @slchangeorder, @units, @unitcost, @amount, @taxgroup,
		@taxtype, @taxcode, @PCOType, @PCO, @PCOItem, @ACO, @ACOItem, @PMSL_KeyID
		----TK-13086
		,@PMSL_Project
		
if @@fetch_status <> 0 goto PMSL_end

-- get needed SLHD information
select @holdcode=HoldCode, @payterms=PayTerms, @compgroup=CompGroup, @approved=Approved, @status=[Status],
		@inusebatchid=InUseBatchId, @inusemth=InUseMth, @uniqueattchid=UniqueAttchID
from dbo.SLHD    
where SLCo=@slco and SL=@pmslsl and VendorGroup=@vendorgroup and Vendor=@vendor

if @status=3 AND ISNULL(@approved,'Y') = 'N' GOTO PMSL_loop

-------- issue #2 9868 - if interfacing a pco and @itemtype = 2 then @slchangeorder required (>0)
----if isnull(@pco,'') <> '' and @itemtype = 2 and isnull(@slchangeorder,0) = 0 goto PMSL_loop

---- valudate POCONum must be ready for accounting and get approved date
SELECT @ApprovedDate = DateApproved
FROM dbo.PMSubcontractCO
WHERE SLCo=@slco 
	AND SL=@sl
	AND SubCO=@SubCO 
	AND ReadyForAcctg = 'Y'
---- if SubCO then ready for accounting flag must be checked
IF @@ROWCOUNT = 0 GOTO PMSL_loop

---- Validate SL record prior to inserting into batch table
if @inusebatchid is not null
	BEGIN
	SELECT @source=[Source] from dbo.HQBC    
	WHERE Co=@slco and BatchId=@inusebatchid and Mth=@inusemth
	if @@rowcount <> 0
		BEGIN
		SELECT @errtext = 'SL: ' + isnull(@pmslsl,'') + ' already in use by ' +
				convert(varchar(2),DATEPART(month, @inusemth)) + '/' + substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) +
				' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
		END
	ELSE
		BEGIN
		SELECT @errtext='SL already in use by another batch!', @rcode=1
		END

	exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
	select @errorcount = @errorcount + 1
	goto PMSL_loop
	END


---- if no approved date use system date
IF @ApprovedDate IS NULL SET @ApprovedDate = dbo.vfDateOnly()

---- check first for an existing batch to add to. if found
---- we need to set the status back to 0 - open othrewise will
---- not be able to add to. TK-05531
IF @slbatchid <> 0 ----AND @slcbbatchid <> 0
	BEGIN
	---- update the status for batch to 0 - open for additional entries
	UPDATE dbo.bHQBC SET Status = 0
	where Co = @slco and Mth = @mth and BatchId = @slbatchid
	if @@rowcount = 0
		BEGIN
		SELECT @errmsg = 'Unable to update Batch Control information!', @rcode = 1
		GOTO vspexit
		END
	END

---- CHECK FOR EXISTING SLCB batch
IF @slcbbatchid <> 0
	BEGIN
	---- try to use existing SL Change order batch id
	UPDATE dbo.bHQBC SET Status = 0
	where Co = @slco and Mth = @mth and BatchId = @slcbbatchid
	if @@rowcount = 0
		BEGIN
		SELECT @errmsg = 'Unable to update Batch Control information!', @rcode = 1
		GOTO vspexit
		END
	END
	
---- if no batch id create one
If @slbatchid = 0
	BEGIN
		exec @slbatchid = dbo.bspHQBCInsert @slco,@mth,'PM Intface','SLHB','N','N',null,null,@errmsg output
		if @slbatchid = 0
		begin
			select @errmsg = @errmsg + ' - Cannot create SL batch'
			goto vspexit
		end

		-- insert batchid into PMBC
		select @slseq=isnull(max(SLSeq),0)+1 
		from dbo.PMBC    
		----TK-05548
		insert into dbo.PMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem, ChangeOrderHeaderBatch)
		select @pmco, @project, @mth, 'SLHB', @slbatchid, @slco, @slseq, null, null, null, NULL, 'Y'
	END
  
---- if no change order batch id create one
if @slcbbatchid = 0
	BEGIN
		exec @slcbbatchid = dbo.bspHQBCInsert @slco,@mth,'PM Intface','SLCB','N','N',null,null,@errmsg output
		if @slcbbatchid = 0
		begin
			select @errmsg = @errmsg + ' - Cannot create SLCB batch'
			goto vspexit
		end
		-- insert batchid into PMBC
		select @slseq=isnull(max(SLSeq),0)+1 
		from dbo.PMBC    
		
		insert into dbo.PMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
		select @pmco, @project, @mth, 'SLCB', @slcbbatchid, @slco, @slseq, null, null, null, NULL
	END


    -- -- -- if sending PCO sub CO's then use the @internal_date if not null else system date
    -- -- -- if sending ACO sub CO's then use the @ApprovedDate if not null else system date
    ----if isnull(@pco,'') <> '' and isnull(@internal_date,'') <> '' set @ActualDate = @internal_date
    ----if isnull(@aco,'') <> '' and isnull(@ApprovedDate,'') <> '' set @ActualDate = @ApprovedDate


select @slitemerr = ' SL: ' + isnull(@pmslsl,'') + ' Item: ' + convert(varchar(6),isnull(@slitem,''))


-- validate Phase
exec @rcode = dbo.bspJCADDPHASE @pmco, @PMSL_Project,@phasegroup,@phase,'Y',null,@errmsg output
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
	exec @rcode = dbo.bspJCADDCOSTTYPE @jcco=@pmco,@job=@PMSL_Project,@phasegroup=@phasegroup,@phase=@phase,@costtype=@costtype,@um=@um,@override= 'P',@msg=@errmsg output
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
	from dbo.JCCH    
	where JCCo=@pmco and Job=@PMSL_Project and Phase=@phase and CostType=@costtype
	if @activeyn <> 'Y'
	begin
		update dbo.JCCH 
		set ActiveYN='Y'
		where JCCo=@pmco and Job=@PMSL_Project and Phase=@phase and CostType=@costtype
	end
    
    -- get GLAcct
    select @contract=[Contract], @contractitem=Item
    from dbo.JCJP    
    where JCCo=@pmco and Job=@PMSL_Project and PhaseGroup=@phasegroup and Phase=@phase
    
    select @department=Department
    from dbo.JCCI    
    where JCCo=@pmco and [Contract]=@contract and Item=@contractitem
    
    select @glacct = null
    
    exec @rcode = dbo.bspJCCAGlacctDflt @pmco, @PMSL_Project, @phasegroup, @phase, @costtype, 'N', @glacct output, @errmsg output
    if @glacct is null
	begin
    	select @errtext = 'GL Acct for Cost Type: ' + convert(varchar(3),@costtype) + 'may not be null'
    	exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
    	select @errorcount = @errorcount + 1
    	goto PMSL_loop
    end

	exec @rcode = dbo.bspGLACfPostable @glco, @glacct, 'J', @errmsg output
	if @rcode <> 0
	begin
		select @errtext = '- GLAcct:' + isnull(@glacct,'') + ':  ' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg OUTPUT
		SELECT @errorcount = @errorcount + 1
		GOTO PMSL_loop
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
        ----#141349
        select @errtext = 'Units must be zero when UM is (LS).' + @slitemerr
        exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
        select @errorcount = @errorcount + 1
        goto PMSL_loop
     end
    
    -- check unit cost to UM
    if @um = 'LS' and @unitcost <> 0
    begin
        ----#141349
        select @errtext = 'Unit cost must be zero when UM is (LS).' + @slitemerr
        exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
        select @errorcount = @errorcount + 1
        goto PMSL_loop
     end

	---- #131843 if units = 0, amount <> 0, and @um <> 'LS' we do not want to send to Acct. Committed Cost get closed
	if isnull(@units,0) = 0 and isnull(@amount,0) <> 0 and isnull(@um,'LS') <> 'LS'
	begin
		----#141349
        select @errtext = 'Units and Amount cannot be zero when UM is not (LS).' + @slitemerr
        exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
        select @errorcount = @errorcount + 1
        goto PMSL_loop
	end
		
	if @taxtype is null and @taxcode is not null
	begin
		----#141349
		select @errtext = 'Tax Code assigned, but missing Tax Type for item.' + @slitemerr
		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMSL_loop
	end
    
    -- check for duplicate item record with different phase/costtype/um combination
  --  if isnull(@pco,'') <> ''
		--begin
  --  		if exists(select 1 from dbo.PMSL where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
  --  			and SLCo=@slco and Vendor=@vendor and SL=@pmslsl and SLItem=@slitem and Seq<>@pmslseq and InterfaceDate is null
  --  			and SendFlag = 'Y'  and RecordType='C' and (Phase<>@phase or CostType<>@costtype or UM<>@um))
  --  		begin
  --  			select @errtext = 'SL: ' + isnull(@pmslsl,'') + ' SLItem: ' + convert(varchar(8),isnull(@slitem,'')) + ' - Multiple records set up for same item with different Phase/CostType/UM combination.'
  --  			exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
  --  			select @errorcount = @errorcount + 1
  --  			goto PMSL_loop
		--	end
		--end
  --  else
    	--begin
			if exists(select 1 from dbo.PMSL where PMCo=@pmco and SLCo=@slco
    				and Vendor=@vendor and SL=@pmslsl and SLItem=@slitem and Seq<>@pmslseq and InterfaceDate is null
    				and SendFlag = 'Y' and (Phase<>@phase or CostType<>@costtype or UM<>@um))
    		begin
    			select @errtext = 'SL: ' + isnull(@pmslsl,'') + ' SLItem: ' + convert(varchar(8),isnull(@slitem,'')) + ' - Multiple records set up for same item with different Phase/CostType/UM combination.'
    			exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
    			select @errorcount = @errorcount + 1
    			goto PMSL_loop
    	    end
    	--end

	-- issue #29868 - if interfacing pco and @itemtype = 1 check if item exists in SLIT. If it does then @slchangeorder is required (>0)
	--if isnull(@pco,'') <> '' and @itemtype = 1
	--begin
	--	-- check if item exists in SLIT
	--	if exists(select 1 from dbo.SLIT    where SLCo=@slco and SL=@pmslsl and SLItem=@slitem)
	--	begin
	--		if isnull(@slchangeorder,0) = 0 goto PMSL_loop
	--	end
	--end

	-- get next available sequence # for this batch
	if exists (select 1 from dbo.SLHB where Co=@slco and Mth=@mth and BatchId=@slbatchid and SL=@pmslsl)
		begin
		select @slhbseq=BatchSeq from dbo.SLHB where Co=@slco and Mth=@mth and BatchId=@slbatchid and SL=@pmslsl
		end
	else
		begin
			select @slhbseq = isnull(max(BatchSeq),0)+1 
			from dbo.SLHB 
			where Co=@slco and Mth=@mth and BatchId=@slbatchid
			
			INSERT INTO dbo.SLHB (Co, Mth, BatchId, BatchSeq, BatchTransType, SL, JCCo, Job, [Description], VendorGroup,
				Vendor, HoldCode, PayTerms, CompGroup, [Status], OrigDate, OldJCCo, OldJob, OldDesc, OldVendor, OldHoldCode,
				OldPayTerms, OldCompGroup, OldStatus, UniqueAttchID, Notes,
				MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN, MaxRetgDistStyle
				----TK-18033
				,ApprovalRequired)
			SELECT @slco, @mth, @slbatchid, @slhbseq, 'C', @pmslsl, JCCo, Job, [Description], @vendorgroup,
				@vendor, HoldCode, PayTerms, CompGroup, 0, OrigDate, JCCo, Job, [Description], @vendor, HoldCode,
				PayTerms, CompGroup, @status, @uniqueattchid, Notes,
				MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN, MaxRetgDistStyle
				----TK-18033
				,ApprovalRequired
			FROM dbo.SLHD 
			where SLCo=@slco and SL=@pmslsl
			if @@rowcount <> 1
				begin
					select @errtext = 'Could not insert SL: ' + isnull(@pmslsl,'') + ' into batch'
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
						select @errtext = 'Unable to update user memo to SL: ' + isnull(@pmslsl,'') + ' Batch'
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
					WHERE Co=@slco and SL=@pmslsl 
				end
		end

	-- validate hold code and pay terms for SLHB
	select @holdcode=HoldCode, @payterms=PayTerms
	from dbo.SLHB    
	where Co=@slco and Mth=@mth and BatchId=@slbatchid and BatchSeq=@slhbseq
	if @@rowcount <> 0
	begin
   		-- validate Hold Code
   		if isnull(@holdcode,'') <> ''
   		begin
   			if not exists(select top 1 1 from dbo.HQHC where HoldCode=@holdcode)
   			begin
   				select @errtext = 'Invalid hold code: ' + isnull(@holdcode,'') + ' for SL: ' + isnull(@pmslsl,'') + '.'
   				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
   				select @errorcount = @errorcount + 1
   				goto PMSL_loop
   			end
   		end
   		-- -- -- validate pay terms
   		if isnull(@payterms,'') <> ''
   		begin
   			if not exists(select top 1 1 from dbo.HQPT where PayTerms=@payterms)
   			begin
   				select @errtext = 'Invalid pay terms: ' + isnull(@payterms,'') + ' for SL: ' + isnull(@pmslsl,'') + '.'
   				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
   				select @errorcount = @errorcount + 1
   				goto PMSL_loop
   			end
   		end
   	end

	-- if tax code assigned, validate tax phase and cost type then calculate tax
	-- ANY CHANGES MADE TO THIS ROUTINE NEED TO ALSO BE DONE IN bspPMSLInterface,
	-- bspPMPOInterface, bspPMPOACOInterface, and vspPMSLCreateSLItem. The logic should
	-- be similar between the procedures working with tax codes.
	if @taxcode is null
		begin
			select @taxamount=0,@taxrate = 0, @gstrate = 0  --DC #130175
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
			exec @rcode = dbo.bspJCADDPHASE @pmco, @PMSL_Project, @phasegroup, @taxphase, 'Y', null, @errmsg output
			-- if phase/cost type does not exist in JCCH try to add it
			if not exists(select top 1 1 from dbo.JCCH where JCCo=@pmco and Job=@PMSL_Project and PhaseGroup=@phasegroup
					and Phase=@taxphase and CostType=@taxct)
			begin
				-- insert cost header record
				insert into dbo.JCCH (JCCo,Job,PhaseGroup,Phase,CostType,UM,BillFlag,ItemUnitFlag,PhaseUnitFlag,BuyOutYN,Plugged,ActiveYN,SourceStatus)
				select @pmco, @PMSL_Project, @phasegroup, @taxphase, @taxct, 'LS', 'C', 'N', 'N', 'N', 'N', 'Y', 'I'
			end
			-- validate Tax phase and Tax Cost Type
			exec @rcode = dbo.bspJobTypeVal @pmco, @phasegroup, @PMSL_Project, @taxphase, @taxct, @taxjcum output, @errmsg output
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
			--exec @rcode = dbo.bspHQTaxRateGetAll @taxgroup, @taxcode, @ApprovedDate, @valueadd output,
			--		@taxrate output, @gstrate output, @pstrate output, null, null,
			--		@HQTXdebtGLAcct output, null, null, null, NULL,NULL,@errmsg output
			----TK-17969		
			exec @rcode = dbo.vspHQTaxRateGet    @taxgroup, @taxcode, @ApprovedDate, @valueadd output, @taxrate output, NULL, NULL, 
						@gstrate output, @pstrate output, null, null, @HQTXdebtGLAcct output, null, null, null, @errmsg output
			
			----DC #130175	
			--if @gstrate = 0 and @pstrate = 0 and @valueadd = 'Y'
			--begin
			--	-- We have an Intl VAT code being used as a Single Level Code
			--	if (select GST from dbo.HQTX  where TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
			--	begin
			--		select @gstrate = @taxrate
			--	end
			--end
		end

		-- Check existence and Item Type
		----TK-12623
		SET @SLItemExists = 'N'
		select @slititem=SLItem,
				----TK-13086
				@SLIT_JCCo = JCCo, @SLIT_Job = Job
		from dbo.SLIT   
		where SLCo=@slco and SL=@pmslsl and SLItem=@slitem
		---- TK-13086 if item exists in SLIT validate job is the same
		IF @@ROWCOUNT <> 0
			BEGIN
			IF @SLIT_JCCo <> @pmco
				BEGIN
				select @errtext = 'SL: ' + dbo.vfToString(@pmslsl) + ' SL Item: ' + dbo.vfToString(@slitem) + ' exists in SLIT and is assigned to different JC Company.'
				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMSL_loop
				END
				
			IF @SLIT_Job <> @PMSL_Project
				BEGIN
				select @errtext = 'SL: ' + dbo.vfToString(@pmslsl) + ' SL Item: ' + dbo.vfToString(@slitem) + ' exists in SLIT and is assigned to different JC Job.'
				exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMSL_loop
				END
			----TK-12623
			SET @SLItemExists = 'Y'
			END
		----TK-12623
		if @SLItemExists = 'N'
			begin
			--DC #130175  New records use the current tax rate
			select @taxamount = (@amount * @taxrate)		--Full TaxAmount:  This is correct whether US, Intl GST&PST, Intl GST only, Intl PST only		1000 * .155 = 155
			select @gsttaxamt = case @taxrate when 0 then 0 else case @valueadd when 'Y' then (@taxamount * @gstrate) / @taxrate else 0 end end --GST Tax Amount.  (Calculated)					(155 * .05) / .155 = 50
			select @psttaxamt = case @valueadd when 'Y' then @taxamount - @gsttaxamt else 0 end			--PST Tax Amount.  (Rounding errors to PST)			
			
			-- check original PMSL for item not interfaced yet
			if exists (select 1 from dbo.PMSL where PMCo=@pmco and SL=@pmslsl and SLItem=@slitem
							 and SLCo=@slco and RecordType='O' and InterfaceDate is NULL AND Seq <> @pmslseq
							 ----TK-14595 
							 AND SubCO IS NULL)
				begin
					--#141349
					select @errtext = 'The original SL: ' + ISNULL(@pmslsl,'') + ' SL Item: ' + ltrim(convert(varchar(10),isnull(@slitem,''))) + ' exists in PMSL and must be interfaced first.'
					exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
					select @errorcount = @errorcount + 1
					goto PMSL_loop
				end

			-- if reg type and does not exist in slit then add it as an original
			if @itemtype = 1
				begin
				if exists(select * from dbo.SLIB where Co=@slco and Mth=@mth and BatchId=@slbatchid and BatchSeq=@slhbseq and SLItem=@slitem)
					begin
					UPDATE dbo.SLIB SET OrigUnits = OrigUnits + isnull(@units,0),
										OrigCost = OrigCost + isnull(@amount,0)
					WHERE Co=@slco and Mth=@mth and BatchId=@slbatchid and BatchSeq=@slhbseq and SLItem=@slitem
					end
				else
					BEGIN
					INSERT INTO dbo.SLIB(Co, Mth, BatchId, BatchSeq, SLItem, BatchTransType, ItemType, Addon, AddonPct, 
    							JCCo, Job, PhaseGroup, Phase, JCCType, [Description], UM, GLCo, GLAcct, WCRetPct, SMRetPct, 
    							VendorGroup, Supplier, OrigUnits, OrigUnitCost, OrigCost,
								TaxType, TaxCode, TaxGroup, OrigTax, Notes,
								JCCmtdTax, TaxRate, GSTRate)  --DC#130175)
								select @slco, @mth, @slbatchid, @slhbseq, @slitem, 'A', @itemtype,
								case when @itemtype = 4 then @addon else null end, 
   								case when @itemtype = 4 then isnull(@addonpct,0) else 0 end,
    							@pmco, @PMSL_Project, @phasegroup, @phase, @costtype, @slitemdesc, @um, @glco, @glacct, 
    							isnull(@wcretpct,0), isnull(@smretpct,0), @vendorgroup, @supplier, isnull(@units,0), 
    							isnull(@unitcost,0), isnull(@amount,0),
								@taxtype, @taxcode, @taxgroup, isnull(@taxamount,0), Notes,
								isnull(@taxamount,0) - (case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end),
								isnull(@taxrate,0), isnull(@gstrate,0)
						FROM dbo.bPMSL 
						WHERE KeyID = @PMSL_KeyID   
						if @@rowcount <> 1
						begin
							--#141349
							select @errtext = 'Could not insert SL: ' + ISNULL(@pmslsl,'') + ' SL Item: ' + ltrim(convert(varchar(10),isnull(@slitem,''))) + ' into batch'
							exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
							select @errorcount = @errorcount + 1
							goto PMSL_loop
						end
					end

				---- update IntFlag in PMSL to 'I', needed to update interface date in bspSLHBPost
				update dbo.bPMSL set IntFlag='I'
				WHERE KeyID = @PMSL_KeyID
			end

		-- if co type and does not exist in slit then add it with 0 amounts and add to slcd with change amount
		if @itemtype = 2
			begin
			--set @slitemrowcount = 0
				--if isnull(@pco,'') <> ''
				--begin
				--	--if not exists(select * from dbo.SLIT where SLCo=@slco and SL=@pmslsl and SLItem=@slitem)
				--	--begin
				--	--	insert into dbo.SLIT(SLCo, SL, SLItem, ItemType, Addon, AddonPct,JCCo, Job, PhaseGroup, Phase, 
    --	--				JCCType, [Description], UM, GLCo, GLAcct, WCRetPct, SMRetPct, VendorGroup, Supplier, 
    --	--				OrigUnits, OrigUnitCost, OrigCost, CurUnits, CurUnitCost, CurCost, StoredMatls, InvUnits, 
    --	--				InvCost, TaxType, TaxCode, TaxGroup, OrigTax, CurTax, InvTax, Notes, AddedMth, AddedBatchID,
    --	--				JCCmtdTax, TaxRate, GSTRate)  --DC #130175
				--	--	select @slco, @pmslsl, @slitem, @itemtype,
				--	--	case when @itemtype = 4 then @addon else null end, 
				--	--	case when @itemtype = 4 then isnull(@addonpct,0) else 0 end,
				--	--	@pmco, @project, @phasegroup, @phase, 
				--	--	@costtype, @slitemdesc, @um, @glco, @glacct, isnull(@wcretpct,0), isnull(@smretpct,0), 
    --	--				@vendorgroup, @supplier, 0, 0, 0, 0, 0, 0, 0, 0, 0,
				--	--	@taxtype, @taxcode, @taxgroup, 0, 0, 0,
    --	--				Notes, @mth, @slcbbatchid, 0, @taxrate, @gstrate --DC #130175
    --	--				from dbo.PMSL   
    --	--				where PMCo=@pmco and Project=@project and PCOType=@pcotype 
    --	--				and PCO=@pco and SL=@pmslsl and SLItem=@slitem and Seq=@pmslseq
				--	--	select @slitemrowcount = @@rowcount
			
				--	--	--if @slitemrowcount = 1
				--	--	--begin
				--	--	--	-- #25100 update user memos from bPMSL to SLIT
				--	--	--	exec @rcode = dbo.bspBatchUserMemoUpdatePMSL @slco, @mth, @slbatchid, @slhbseq, @pmslsl, @slitem,
    --	--	--							@pmco, @project, @pmslseq, 'SLIT', @errmsg output
				--	--	--	if @rcode <> 0
				--	--	--	begin
				--	--	--		--#141349
				--	--	--		select @errtext = 'Could not update user memo for SL: ' + ISNULL(@pmslsl,'') + ' SL Item: ' + convert(varchar(10),@slitem)
				--	--	--		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output 
				--	--	--		select @errorcount = @errorcount + 1
				--	--	--		goto PMSL_loop
				--	--	--	end
				--	--	--end
				--	--end
				--end
		--else
			--begin
			if not exists(select * from dbo.SLIT where SLCo=@slco and SL=@pmslsl and SLItem=@slitem)
				BEGIN
				INSERT INTO dbo.SLIT(SLCo, SL, SLItem, ItemType, Addon, AddonPct,JCCo, Job, PhaseGroup, Phase, JCCType,
						[Description], UM, GLCo, GLAcct, WCRetPct, SMRetPct, VendorGroup, Supplier, OrigUnits, OrigUnitCost,
						OrigCost, CurUnits, CurUnitCost, CurCost, StoredMatls, InvUnits, InvCost,
						TaxType, TaxCode, TaxGroup, OrigTax, CurTax, InvTax, Notes, AddedMth, AddedBatchID,
						JCCmtdTax, TaxRate, GSTRate)
				SELECT @slco, @pmslsl, @slitem, @itemtype,
						case when @itemtype = 4 then @addon else null end, 
						case when @itemtype = 4 then isnull(@addonpct,0) else 0 end,
						@pmco, @PMSL_Project, @phasegroup, @phase,
						@costtype, @slitemdesc, @um, @glco, @glacct, isnull(@wcretpct,0), isnull(@smretpct,0),
						@vendorgroup, @supplier, 0, 0, 0, 0, 0, 0, 0, 0, 0,
						@taxtype, @taxcode, @taxgroup, 0, 0, 0,
						Notes, @mth, @slcbbatchid,
						isnull(@taxamount,0) - (case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end),
						@taxrate, @gstrate
				FROM dbo.bPMSL
				WHERE KeyID = @PMSL_KeyID
				IF @@ROWCOUNT <> 1
					BEGIN
					--#141349
					select @errtext = 'Could not insert SL: ' + ISNULL(@pmslsl,'') + 'SL Item: ' + ltrim(convert(varchar(10),isnull(@slitem,''))) + ' into SLIT'
					exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
					select @errorcount = @errorcount + 1 
					goto PMSL_loop
					END
				ELSE
					BEGIN
					SET @slitemrowcount = 1
					-- #25100 update user memos from bPMSL toSLIT
					exec @rcode = dbo.bspBatchUserMemoUpdatePMSL @slco, @mth, @slbatchid, @slhbseq, @pmslsl, @slitem,
									@pmco, @PMSL_Project, @pmslseq, 'SLIT', @errmsg output
					if @rcode <> 0
						BEGIN
						--#141349
						select @errtext = 'Could not update user memo for SL: ' + ISNULL(@pmslsl,'') + ' SL Item: ' + convert(varchar(10),@slitem)
						exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output 
						select @errorcount = @errorcount + 1
						goto PMSL_loop
						END
						
					---- insert record into PMBC to note the SL and SLItem we have added in case of error
					select @slseq=isnull(max(SLSeq),0)+1 from dbo.PMBC    
					insert into dbo.PMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
					select @pmco, @project, @mth, 'SLCB', @slcbbatchid, @slco, @slseq, @pmslsl, @slitem, null, NULL
					END
				END
			--end

		--if @slitemrowcount = 1
		--	begin
		--		select @slseq=isnull(max(SLSeq),0)+1 from dbo.PMBC    
		--		insert into dbo.PMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
		--		select @pmco, @project, @mth, 'SLCB', @slcbbatchid, @slco, @slseq, @pmslsl, @slitem, null, NULL
		--	end
		--else
		--	begin
		--	--#141349
		--		select @errtext = 'Could not insert SL: ' + ISNULL(@pmslsl,'') + 'SL Item: ' + ltrim(convert(varchar(10),isnull(@slitem,''))) + ' into SLIT'
		--		exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slbatchid, @errtext, @errmsg output
		--		select @errorcount = @errorcount + 1 
		--		goto PMSL_loop
		--	end

		-- add SL change order transaction to batch
		--if isnull(@pco,'') <> ''
		--	begin
		--		select @slcbseq = isnull(max(BatchSeq),0)+1 from dbo.SLCB where Co=@slco and Mth=@mth and BatchId=@slcbbatchid
		--		insert into dbo.SLCB (Co, Mth, BatchId, BatchSeq, BatchTransType, SLTrans, SL, SLItem, SLChangeOrder, 
  --  			AppChangeOrder, ActDate, [Description], UM, ChangeCurUnits, CurUnitCost, ChangeCurCost,
		--		PMSLSeq, ChgToTax, Notes)
		--		select @slco, @mth, @slcbbatchid, @slcbseq, 'A', null, @pmslsl, @slitem, isnull(@slchangeorder,0), 
  --  			null, @ApprovedDate, @slitemdesc, @um, isnull(@units,0), isnull(@unitcost,0), isnull(@amount,0),
		--		@pmslseq, isnull(@taxamount,0),Notes
		--		from dbo.PMSL   
  --  			where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and SL=@pmslsl and SLItem=@slitem and Seq=@pmslseq
		--		if @@rowcount <> 1
		--		begin
		--			--#141349
		--			select @errmsg = 'Could not insert SL: ' + ISNULL(@pmslsl,'') + ' SL Item: ' + ltrim(convert(varchar(10),isnull(@slitem,''))) + ' into SLCB'
		--			exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slcbbatchid, @errtext, @errmsg output
		--			select @errorcount = @errorcount + 1
		--			goto PMSL_loop
		--		end
		--	end
		--else
		--	begin
				SELECT @slcbseq = isnull(max(BatchSeq),0)+1 from dbo.SLCB where Co=@slco and Mth=@mth and BatchId=@slcbbatchid
				INSERT INTO dbo.SLCB (Co, Mth, BatchId, BatchSeq, BatchTransType, SLTrans, SL, SLItem, SLChangeOrder, 
    					AppChangeOrder, ActDate, [Description], UM, ChangeCurUnits, CurUnitCost, ChangeCurCost,
						PMSLSeq, ChgToTax, Notes)
						select @slco, @mth, @slcbbatchid, @slcbseq, 'A', null, @pmslsl, @slitem, isnull(@slchangeorder,0), 
    					@ACO, @ApprovedDate, @slitemdesc, @um, isnull(@units,0), isnull(@unitcost,0), isnull(@amount,0),
						@pmslseq, isnull(@taxamount,0),Notes
				from dbo.bPMSL
				WHERE KeyID = @PMSL_KeyID
				if @@rowcount <> 1
				begin
					--#141349
					select @errmsg = 'Could not insert SL: ' + ISNULL(@pmslsl,'') + ' SL Item: ' + ltrim(convert(varchar(10),isnull(@slitem,''))) + ' into SLCB'
					exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slcbbatchid, @errtext, @errmsg output
					select @errorcount = @errorcount + 1
					goto PMSL_loop
				end
			--end
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
	-- insert into SLCB
	begin
		--DC #130175  -change orders to existing records use the tax rate stored in SLIt
		select @taxrate=TaxRate,@gstrate = GSTRate 
		from dbo.SLIT    
		where SLCo=@slco and SL=@pmslsl and SLItem=@slitem

		--DC #130175  New records use the current tax rate
		select @taxamount = (@amount * @taxrate)--Full TaxAmount:  This is correct whether US, Intl GST&PST, Intl GST only, Intl PST only		1000 * .155 = 155
		select @gsttaxamt = case @taxrate when 0 then 0 else case @valueadd when 'Y' then (@taxamount * @gstrate) / @taxrate else 0 end end --GST Tax Amount.  (Calculated)					(155 * .05) / .155 = 50
		select @psttaxamt = case @valueadd when 'Y' then @taxamount - @gsttaxamt else 0 end	--PST Tax Amount.  (Rounding errors to PST)			

		-- #136053
		set @slcbunitcost = 0
		set @slcbcost = @amount
		
		-- get next available sequence # for this batch
		select @slcbseq = isnull(max(BatchSeq),0)+1 
		from dbo.SLCB    
		where Co = @slco and Mth = @mth and BatchId = @slcbbatchid
		
		-- add SL change order transaction to batch
		--if isnull(@pco,'') <> ''
		--	begin
		--		select @slcbdesc = @slitemdesc
		--		insert into dbo.SLCB (Co, Mth, BatchId, BatchSeq, BatchTransType, SLTrans, SL, SLItem, SLChangeOrder, 
  --  			AppChangeOrder, ActDate, [Description], UM, ChangeCurUnits, CurUnitCost, ChangeCurCost,
		--		PMSLSeq, ChgToTax, Notes)
		--		select @slco, @mth, @slcbbatchid, @slcbseq, 'A', null, @pmslsl, @slitem, isnull(@slchangeorder,0), 
  --  			null, @ApprovedDate, @slcbdesc, @um, isnull(@units,0), isnull(@slcbunitcost,0), isnull(@slcbcost,0),
		--		@pmslseq, isnull(@taxamount,0),	Notes 
		--		from dbo.PMSL   
		--		where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and SL=@pmslsl and SLItem=@slitem and Seq=@pmslseq
		--		if @@rowcount <> 1
		--		begin
		--			select @errmsg = 'Could not insert SL: ' + ISNULL(@pmslsl,'') + ' SL Item: ' + convert(varchar(10),isnull(@slitem,'')) + 'into batch'
		--			exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slcbbatchid, @errtext, @errmsg output
		--			select @errorcount = @errorcount + 1
		--			goto PMSL_loop
		--		end
		--	end
		--else
		--	begin
				select @slcbdesc = @slitemdesc
				
				INSERT INTO dbo.SLCB (Co, Mth, BatchId, BatchSeq, BatchTransType, SLTrans, SL, SLItem, SLChangeOrder, 
    					AppChangeOrder, ActDate, [Description], UM, ChangeCurUnits, CurUnitCost, ChangeCurCost,
						PMSLSeq, ChgToTax, Notes)
						select @slco, @mth, @slcbbatchid, @slcbseq, 'A', null, @pmslsl, @slitem, isnull(@slchangeorder,0), 
    					@ACO, @ApprovedDate, @slcbdesc, @um, isnull(@units,0), isnull(@slcbunitcost,0), isnull(@slcbcost,0),
						@pmslseq, isnull(@taxamount,0),Notes 
				from dbo.bPMSL
				WHERE KeyID = @PMSL_KeyID
				if @@rowcount <> 1
				begin
					select @errmsg = 'Could not insert SL: ' + ISNULL(@pmslsl,'') + ' SL Item: ' + convert(varchar(10),isnull(@slitem,'')) + 'into batch'
					exec @rcode = dbo.bspHQBEInsert @slco, @mth, @slcbbatchid, @errtext, @errmsg output
					select @errorcount = @errorcount + 1
					goto PMSL_loop
				end
			--end
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
	delete dbo.SLIB where Co=@slco and Mth=@mth and BatchId=@slbatchid
	delete dbo.SLHB where Co=@slco and Mth=@mth and BatchId=@slbatchid
	delete dbo.SLCB where Co=@slco and Mth=@mth and BatchId=@slcbbatchid

	---- remove slIT rows added via this process zero value items
	DELETE dbo.bSLIT
	FROM dbo.bSLIT i
	INNER JOIN dbo.bPMBC c ON c.BatchCo = i.SLCo AND c.SL = i.SL AND c.SLItem = i.SLItem
	where c.Co=@pmco
		----TK-13086
		----AND c.Project=@project 
		AND c.Mth=@mth 
		AND c.BatchId=@slcbbatchid 
		AND c.BatchTable='SLCB'
		AND c.SL IS NOT NULL
		AND c.SLItem IS NOT NULL


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

	----TK-14595
	delete dbo.PMBC 
	where Co=@pmco and Project=@project 
		and Mth=@mth 
		and BatchId=@slcbbatchid 
		and BatchTable='SLCB' 
		and BatchCo=@slco
		AND SL IS NOT NULL
		AND SLItem IS NOT NULL

	update dbo.PMSL 
	set IntFlag=Null
	where PMCo=@pmco
		----TK-13086
		----and Project=@project
		AND SLCo = @slco
		AND SL = @sl
		AND SubCO = @SubCO
		AND	InterfaceDate is null 
		AND IntFlag='I'
	
	select @rcode = 1
end

vspexit:
	if @opencursor <> 0
	begin
		close bcPMSL
		deallocate bcPMSL
		select @opencursor = 0
	end

	select @slstatus=[Status] 
	from dbo.HQBC    
	where Co=@slco and Mth=@mth and BatchId=@slbatchid and TableName='SLHB'
	
	select @slcbstatus=[Status] 
	from dbo.HQBC    
	where Co=@slco and Mth=@mth and BatchId=@slcbbatchid and TableName='SLCB'

	select @errmsg = isNull(@errmsg,'') + ' ' + isnull(@errtext,'')	
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspPMInterfaceSLSubCO] TO [public]
GO
