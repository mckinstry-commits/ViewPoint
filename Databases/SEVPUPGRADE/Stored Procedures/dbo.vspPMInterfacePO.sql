SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/************************************/
CREATE   proc [dbo].[vspPMInterfacePO]
/*************************************
* Created By:  TRL 05/03/2011 TK-04412
* Modified By: GF 05/21/2011 TK-05347
*				GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
*				MV 10/25/2011 - TK-09243 - added NULL param to bspHQTaxRateGetAll
*				GF 04/09/2012 TK-13873 #145073 validate comp group
*				DAN SO 06/18/2012 - TK-15746 - validate Unit of Measure
*				GF 09/17/2012 - TK-17969 use vspHQTaxRateGet for gst rate (single level)
*				GF 10/09/2012 TK-18382 147184 display pending POCO for interface if approved
*				GF 10/10/2012 TK-18416 write out JCCo to POIB table
*				AW 01/08/2013 TK-20643 return error if GLAcct is invalid
*
* USAGE:
* used by PMInterfaceProjects to interface a project or change order from PM to PO as specified
*
* Pass in :
*	PMCo, Project, Mth, GLCo
*
* Returns
*	POHB Batchid, Error message and return code
*
*******************************/
(@pmco bCompany = NULL, @project bJob = NULL, @po varchar(30) = NULL,
 @mth bMonth = NULL, @glco bCompany = NULL,
 @pobatchid int output, @postatus tinyint output, 
 @errmsg varchar(600) output)

AS
SET NOCOUNT ON

declare @rcode int, @pohbseq int, @opencursor tinyint, @vendorgroup bGroup, @vendor bVendor, @reqdate bDate,
		@materialgroup bGroup, @materialcode bMatl, @vendmtlid varchar(30), @um bUM, @recvyn bYN, @location bLoc,
		@phasegroup bGroup, @phase bPhase, @costtype bJCCType, @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint,
		@units bUnits, @unitcost bUnitCost, @ecm bECM, @amount bDollar, @taxrate bRate, @taxamount bDollar,
		@glacct bGLAcct, @errtext varchar(255), @pmmfpo varchar(30), @poitem bItem, @errorcount int, @department bDept,
		@mtldesc bItemDesc, @contract bContract, @contractitem bContractItem, @requisitionnum varchar(20),
		@slseq int, @inusebatchid bBatchID, @source bSource, @inusemth bMonth, @poco bCompany, @approved bYN,
		@pohdstatus tinyint, @pmmfseq int, @activeyn bYN, @poitemerr varchar(30), @taxphase bPhase,
		@taxct bJCCType, @taxjcum bUM, @valueadd varchar(1)

		
---- #130033
declare @gstrate bRate, @pstrate bRate, @HQTXcrdGLAcct bGLAcct, @HQTXcrdGLAcctPST bGLAcct,  
		@HQTXdebtGLAcct bGLAcct, @oldreqdate bDate, @dflt_matl_group bGroup,
		@oldtaxrate bRate, @oldgstrate bRate, @oldpstrate bRate, @oldHQTXdebtGLAcct bGLAcct,  
		@jccmtdtax bDollar, @supplier bVendor
		----TK-13873
		,@CompGroup VARCHAR(10), @PayTerms bPayTerms, @HoldCode bHoldCode

select @rcode = 0, @errorcount = 0, @opencursor = 0

if @pmco is null or @project is null or @mth is null or @po is null
begin
	select @errmsg = 'Missing PO information!', @rcode = 1
	goto vspexit
end

---- get PO Company from PM Company
select @poco=APCo 
from dbo.PMCO   
where PMCo=@pmco

---- get Default Material Group from HQ Company #137088
select @dflt_matl_group=MatlGroup
from dbo.HQCO   
where HQCo=@poco
if @@rowcount = 0
begin
	select @dflt_matl_group=MatlGroup
	from dbo.HQCO   
	where HQCo=@pmco
end

    
-- check for data then create batch
if exists (select 1 from dbo.bPMMF a where a.PMCo=@pmco AND a.Project=@project AND a.POCo=@poco
				AND a.PO = @po AND a.POCONum IS NULL AND a.SendFlag = 'Y' AND a.InterfaceDate IS NULL
				AND a.MaterialOption = 'P'
				----TK-18382
				----and (a.RecordType='O' OR (a.RecordType = 'C' AND a.ACO IS NOT NULL))
		AND EXISTS(select 1 from dbo.bPOHD b where b.POCo=a.POCo and b.PO=a.PO AND ISNULL(b.Approved,'Y') = 'Y'))
	begin
		--Reset Batch Status to Open to allow posting of new records
		If @pobatchid <> 0 and @postatus =3 --and @interfacestatus=0 
		begin
			Update dbo.HQBC
			set [Status] = 0
			Where Co=@poco and Mth=@mth and BatchId=@pobatchid
		end
		
		If @pobatchid = 0 or @pobatchid is null
		begin
			exec @pobatchid = dbo.bspHQBCInsert @poco, @mth, 'PM Intface', 'POHB', 'N', 'N', null, null, @errmsg output
			if @pobatchid = 0
			begin
				select @errmsg = @errmsg + ' - Cannot create PO batch', @rcode = 1
				exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto vspexit
			end
		end
		
		-- insert batchid into PMBC
		select @slseq=isnull(max(SLSeq),0)+1 from dbo.PMBC 

		insert into dbo.PMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
		select @pmco, @project, @mth, 'POHB', @pobatchid, @poco, @slseq, null, null, null, null
	end
else
	begin
		goto vspexit
	end

-- declare cursor on PMMF Material Detail for interface to POHB and POIT
declare bcPMMF cursor LOCAL FAST_FORWARD
	for select Seq, PO, POItem, VendorGroup, Vendor, MaterialGroup, MaterialCode, VendMatId,
			MtlDescription, UM, RecvYN, Location, PhaseGroup, Phase, CostType, ReqDate, TaxGroup,
			TaxCode, TaxType, isnull(Units,0), isnull(UnitCost,0), ECM, isnull(Amount,0),
			RequisitionNum, Supplier
FROM dbo.PMMF    
WHERE PMCo=@pmco AND Project=@project
	AND POCo=@poco
	AND PO=@po
	AND POItem IS NOT NULL
	AND Vendor IS NOT NULL
	AND POCONum IS NULL 
	AND SendFlag = 'Y'
	AND MaterialOption='P' 
	AND InterfaceDate IS NULL
	----TK-18382
	--AND (RecordType = 'O' OR
	--	 (RecordType = 'C' AND ACO IS NOT NULL))
GROUP BY PO, POItem, Seq, VendorGroup, Vendor, MaterialGroup, MaterialCode, VendMatId,
		MtlDescription, UM, RecvYN, Location, PhaseGroup, Phase, CostType, ReqDate,
		TaxGroup, TaxCode, TaxType, Units, UnitCost, ECM, Amount, RequisitionNum,
		Supplier


-- open cursor
open bcPMMF
select @opencursor = 1

PMMF_loop:
fetch next from bcPMMF into @pmmfseq, @pmmfpo, @poitem, @vendorgroup, @vendor, @materialgroup,
		@materialcode, @vendmtlid, @mtldesc, @um, @recvyn, @location, @phasegroup, @phase,
		@costtype, @reqdate, @taxgroup, @taxcode, @taxtype, @units, @unitcost, @ecm,
		@amount, @requisitionnum, @supplier
			
if @@fetch_status <> 0 goto PMMF_end

-- get needed PO information
select @approved=Approved, @pohdstatus=[Status]
from dbo.POHD 
where POCo=@poco and PO=@po and VendorGroup=@vendorgroup and Vendor=@vendor

if @pohdstatus = 3 and ISNULL(@approved,'Y') = 'N' goto PMMF_loop

-- Validate record prior to inserting into batch table
select @inusebatchid=InUseBatchId, @inusemth=InUseMth
from dbo.POHD 
where POCo=@poco and PO=@po
if @inusebatchid is not null
begin
	select @source=[Source] 
	from dbo.HQBC 
	where Co=@poco and BatchId=@inusebatchid and Mth=@inusemth
	if @@rowcount<>0
		begin
			select @errtext = 'Transaction already in use by ' +
			convert(varchar(2),DATEPART(month, @inusemth)) + '/' + substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) +
		' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
		end
	else
		begin
			select @errtext='Transaction already in use by another batch!', @rcode=1
		end

	exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
	select @errorcount = @errorcount + 1
	goto PMMF_loop
end

-- Insert POHB record
if exists(select 1 from dbo.POHB where Co=@poco and Mth=@mth and BatchId=@pobatchid and PO=@po)
	begin
		select @pohbseq=BatchSeq 
		from dbo.POHB  
		where Co=@poco and Mth=@mth and BatchId=@pobatchid and PO=@po
	end
else
	begin
	-- get next available sequence # for this batch
	select @pohbseq = isnull(max(BatchSeq),0)+1 
	from dbo.POHB 
	where Co = @poco and Mth = @mth and BatchId = @pobatchid
	
	insert into dbo.POHB (Co, Mth, BatchId, BatchSeq, BatchTransType, PO, VendorGroup, Vendor, [Description], OrderDate,
		OrderedBy, ExpDate, [Status], JCCo, Job, INCo, Loc, ShipLoc, [Address], City, [State], Zip, ShipIns,
		HoldCode, PayTerms, CompGroup, OldVendorGroup, OldVendor, OldDesc, OldOrderDate, OldOrderedBy,
		OldExpDate, OldStatus, OldJCCo, OldJob, OldINCo, OldLoc, OldShipLoc, OldAddress, OldCity,
		OldState, OldZip, OldShipIns, OldHoldCode, OldPayTerms, OldCompGroup, Attention, OldAttention,
		Notes, PayAddressSeq, OldPayAddressSeq, POAddressSeq, OldPOAddressSeq, Address2, OldAddress2,
		UniqueAttchID, Country, OldCountry)
	select @poco, @mth, @pobatchid, @pohbseq, 'C', @po, @vendorgroup, @vendor, [Description], OrderDate,
		OrderedBy, ExpDate, 0, JCCo, Job, INCo, Loc, ShipLoc, [Address], City, [State], Zip, ShipIns,
		HoldCode, PayTerms, CompGroup, @vendorgroup, @vendor, [Description], OrderDate, OrderedBy,
		ExpDate, 3, JCCo, Job, INCo, Loc, ShipLoc, [Address], City, [State], Zip, ShipIns, HoldCode,
		PayTerms, CompGroup, Attention, Attention, Notes,PayAddressSeq, PayAddressSeq, POAddressSeq,
		POAddressSeq, Address2, Address2, UniqueAttchID, Country, Country
	from dbo.POHD 
	where POCo=@poco and PO=@po
	if @@rowcount <> 1
		begin
		select @errtext = 'Could not insert PO: ' + isnull(@po,'') + ' into batch'
		exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMMF_loop
		end
	else
		begin
		---- update user memos
		exec @rcode = dbo.bspBatchUserMemoInsertExisting @poco, @mth, @pobatchid, @pohbseq, 'PO Entry', 0, @errmsg output
		if @rcode <> 0
			begin
			select @errmsg = 'Unable to update user memo to PO: ' + isnull(@po,'') + ' Batch'
			select @errorcount = @errorcount + 1
			goto PMMF_loop
			end
		END
		
	---- TK-13873 validate hold code, pay terms, compliance group
	select @HoldCode=HoldCode, @PayTerms=PayTerms, @CompGroup=CompGroup
	from dbo.POHB 
	where Co=@poco and Mth=@mth and BatchId=@pobatchid and BatchSeq=@pohbseq
	if @@rowcount <> 0
		BEGIN
		---- validate Hold Code
		if isnull(@HoldCode,'') <> ''
			begin
			if not exists(select top 1 1 from dbo.HQHC where HoldCode=@HoldCode)
				begin
				select @errtext = 'Invalid hold code: ' + isnull(@HoldCode,'') + ' for PO: ' + isnull(@po,'') + '.'
				exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMMF_loop
				end
			end
		---- validate pay terms
		if isnull(@PayTerms,'') <> ''
			begin
			if not exists(select top 1 1 from dbo.HQPT where PayTerms=@PayTerms)
				begin
				select @errtext = 'Invalid pay terms: ' + isnull(@PayTerms,'') + ' for PO: ' + isnull(@po,'') + '.'
				exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMMF_loop
				end
			END
		---- validate comp group
		if isnull(@CompGroup,'') <> ''
			BEGIN
 			IF NOT EXISTS(SELECT 1 FROM dbo.HQCG WHERE CompGroup = @CompGroup)
	 			BEGIN
	 			SELECT @errtext = 'Invalid Compliance group ' + dbo.vfToString(@CompGroup) + ' for PO: ' + dbo.vfToString(@po)
				EXEC @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
				SELECT @errorcount = @errorcount + 1
				GOTO PMMF_loop
     			END
			END
		END
		
		
		
	end



-- Insert PO Items into POIB
select @poitemerr = ' PO: ' + isnull(@po,'') + ' Item: ' + convert(varchar(5),isnull(@poitem,''))
if exists (select 1 from dbo.POIT where POCo=@poco and PO=@po and POItem=@poitem)
	begin
		select @errtext = 'PO: ' + isnull(@po,'') + ', PO Item: ' + convert(varchar(5),isnull(@poitem,'')) + ' already exists.'
		exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMMF_loop
	end
else
	begin
		-- Validate Phase
		exec @rcode = dbo.bspJCADDPHASE @pmco,@project,@phasegroup,@phase,'Y',null,@errmsg output
		if @rcode <> 0
		begin
			select @errtext = @errmsg + @poitemerr
			exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1
			goto PMMF_loop
		end

		-- validate cost type
		exec @rcode = dbo.bspJCADDCOSTTYPE @jcco=@pmco, @job=@project, @phasegroup=@phasegroup, @phase=@phase, @costtype=@costtype, @um=@um, @override= 'P', @msg=@errmsg output
		if @rcode<>0
		begin
			select @errtext = @errmsg + @poitemerr
			exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1
			goto PMMF_loop
		end

		-- update active flag if needed
		select @activeyn=ActiveYN 
		from dbo.JCCH    
		where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
		if @activeyn <> 'Y'
		begin
			update dbo.JCCH 
			set ActiveYN='Y'
			where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
		end

		-- Get Contract
		select @contract=[Contract], @contractitem=Item 
		from dbo.JCJP    
		where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase

		-- get department
		select @department=Department 
		from dbo.JCCI 
		where JCCo=@pmco and [Contract]=@contract and Item=@contractitem

		-- Get GLAcct
		select @glacct = null
		exec @rcode = dbo.bspJCCAGlacctDflt @pmco, @project, @phasegroup, @phase, @costtype, 'N', @glacct output, @errmsg output

		if @glacct is null
		begin
			select @errtext = 'GL Acct for Cost Type: ' + convert(varchar(3),isnull(@costtype,'')) + 'may not be null. ' + @poitemerr
			exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1
			goto PMMF_loop
		end

		exec @rcode = dbo.bspGLACfPostable @glco, @glacct, 'J', @errmsg output
		if @rcode <> 0
		begin
			select @errtext = '- GLAcct:' + isnull(@glacct,'') + ':  ' + isnull(@errmsg,'')
			exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg OUTPUT
			SELECT @errorcount = @errorcount + 1
			GOTO PMMF_loop
		end

		-- VALIDATE UM -- TK-15746 --
		EXEC @rcode = dbo.bspHQUMVal @um, @errmsg output
		IF @rcode <> 0
			BEGIN
				SET @errtext = ISNULL(@errmsg,'') + '('+ ISNULL(@um,'') + ') ' + @poitemerr
				EXEC @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
				SET @errorcount = @errorcount + 1
				GOTO PMMF_loop
			END

		-- check units to UM
		if @um = 'LS' and @units <> 0
		begin
			select @errtext = 'Units must be zero when UM is (LS).' + @poitemerr
			exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1
			goto PMMF_loop
		end

		-- check unit cost to UM
		if @um = 'LS' and @unitcost <> 0
		begin
			select @errtext = 'Unit cost must be zero when UM is (LS).' + @poitemerr
			exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1
			goto PMMF_loop
		end

		-- validate units when UM <> 'LS' and Amount <> 0
		if @um <> 'LS' and @amount <> 0 and @units = 0
		begin
			select @errtext = 'Must have units when UM is not lump sum (LS) and there is an amount.' + @poitemerr
			exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1
			goto PMMF_loop
		end

		if @um <> 'LS'
		begin
			if @ecm not in ('E', 'C', 'M')
			begin
				select @errtext = 'Missing ECM, must be (E,C,M).' + @poitemerr
				exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMMF_loop
			end
		end

		if @taxtype is null and @taxcode is not null
		begin
			select @errtext = 'Tax Code assigned, but missing Tax Type for material.' + @poitemerr
			exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1
			goto PMMF_loop
		end
	
		-- if tax code assigned, validate tax phase and cost type then calculate tax
		-- ANY CHANGES MADE TO THIS ROUTINE NEED TO ALSO BE DONE IN bspPMSLACOInterface,
		-- bspPMSLInterface, bspPMPOACOInterface, and vspPMSLCreateSLItem. The logic should
		-- be similar between the procedures working with tax codes.
	if @taxcode is null
		begin
			select @taxamount=0, @jccmtdtax = 0,
			@taxrate = 0, @gstrate = 0  --DC #122288
		end
	else
		begin
			select @taxphase = null, @taxct = null
			-- validate Tax Code
			exec @rcode = dbo.bspPOTaxCodeVal @taxgroup, @taxcode, @taxtype, @taxphase output, @taxct output, @errmsg output
			if @rcode <> 0
			begin
				select @errtext = isnull(@errmsg,'') + ' ' + @poitemerr
				exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMMF_loop
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
				select @errtext = 'Tax: ' + isnull(@errmsg,'') + ' ' + @poitemerr
				exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMMF_loop
			end

			-- calculate tax
			--exec @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, @reqdate, @valueadd output, @taxrate output, @gstrate output, @pstrate output, 
			--@HQTXcrdGLAcct output, null, @HQTXdebtGLAcct output, null, @HQTXcrdGLAcctPST output, null, NULL, NULL, @errmsg OUTPUT
			----TK-17969		
			exec @rcode = dbo.vspHQTaxRateGet @taxgroup, @taxcode, @reqdate, @valueadd output, @taxrate output, NULL, NULL, 
						@gstrate output, @pstrate output, null, null, @HQTXdebtGLAcct output, null, null, null, @errmsg output
			if @rcode <> 0
			begin
				select @errtext = 'Tax: ' + isnull(@errmsg,'') + ' ' + @poitemerr
				exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMMF_loop
			end

			-- calculate tax amount
			select @taxamount = @amount * @taxrate
			select @jccmtdtax = 0

			-- if tax code is value added then calculate tht JC tax that will only be the PST portion
			if isnull(@valueadd,'N') = 'Y' and @pstrate <> 0
				begin
					select @jccmtdtax = @amount * @pstrate
				end			
			else
				begin
					select @jccmtdtax = @taxamount
				end	
		end

	-- Insert record
	insert into dbo.POIB(Co, Mth, BatchId, BatchSeq, POItem, BatchTransType, ItemType, MatlGroup, Material, VendMatId,
		[Description], UM, RecvYN, PostToCo, Loc, Job, PhaseGroup, Phase, JCCType, GLCo, GLAcct, ReqDate,
		TaxGroup, TaxCode, TaxType, OrigUnits, OrigUnitCost, OrigECM, OrigCost, OrigTax, RequisitionNum,
		JCCmtdTax, Notes, Supplier, SupplierGroup,
		TaxRate, GSTRate
		----TK-18416
		,JCCo)
	select @poco, @mth, @pobatchid, @pohbseq, @poitem, 'A', 1, isnull(@materialgroup,@dflt_matl_group), @materialcode, @vendmtlid, @mtldesc,
		@um, @recvyn, @pmco, @location, @project, @phasegroup, @phase, @costtype, @glco, @glacct, @reqdate,
		@taxgroup, @taxcode, @taxtype, @units, @unitcost,
		OrigECM = case when @um='LS' then null else @ecm end, @amount, @taxamount, @requisitionnum,
		@jccmtdtax, Notes, @supplier, @vendorgroup,
		isnull(@taxrate,0), isnull(@gstrate,0)
		----TK-18416
		,@pmco
	from dbo.PMMF 
	where PMCo=@pmco and Project=@project and PO=@po and POItem=@poitem and Seq=@pmmfseq
	if @@rowcount <> 1
		begin
			select @errtext = 'Could not insert PO Item: ' + convert(varchar(6),isnull(@poitem,'')) + ' for PO: ' + + isnull(@po,'') + ' into batch'
			exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1
			goto PMMF_loop
		end
	else
		begin
			-- #20618 update user memos from bPMMF to bPOIB 
			exec @rcode = dbo.bspBatchUserMemoUpdatePMPO @poco, @mth, @pobatchid, @pohbseq, @po, @poitem,
			@pmco,@project,@pmmfseq, @errmsg output
			if @rcode <> 0
			begin
				select @errtext = 'Could not update user memo for PO Item: ' + convert(varchar(6),isnull(@poitem,'')) + ' for PO: ' + isnull(@po,'')
				exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output 
				select @errorcount = @errorcount + 1
				goto PMMF_loop
			end
		end
	end

	goto PMMF_loop

	PMMF_end:
	if @opencursor <> 0
	begin
		close bcPMMF
		deallocate bcPMMF
		select @opencursor = 0
	end

	if @errorcount > 0
	begin
		-- undo everything
		delete dbo.POIB where Co=@poco and Mth=@mth and BatchId=@pobatchid
		delete dbo.POHB where Co=@poco and Mth=@mth and BatchId=@pobatchid
		if @pobatchid <> 0
		begin
			exec @rcode = dbo.bspHQBCExitCheck @poco, @mth, @pobatchid, 'PM Intface', 'POHB', @errmsg output
			if @rcode <> 0
			begin
			select @errmsg = @errmsg + ' - Cannot cancel batch '
		end
	end
	select @rcode = 1
end


vspexit:
	if @opencursor <> 0
	begin
		close bcPMMF
		deallocate bcPMMF
		select @opencursor = 0
	end

	select @postatus=[Status]
	from dbo.HQBC  
	where Co=@poco and Mth=@mth and BatchId=@pobatchid
	
	select @errmsg =IsNull(@errmsg,'')+ ' ' +  IsNull(@errtext,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMInterfacePO] TO [public]
GO
