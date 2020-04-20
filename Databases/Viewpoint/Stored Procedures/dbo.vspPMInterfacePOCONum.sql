SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*************************************/
CREATE proc [dbo].[vspPMInterfacePOCONum]
/*************************************
* CREATED BY:   TRL 05/03/2011 TK-04412
* MODIFIED By:	GF 05/26/2011 TK-05347 TK-05531 TK-05548 TK-06406
*				GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
*				MV 10/25/2011 - TK-09243 - added NULL param to bspHQTaxRateGetAll
*				GF 10/31/2011 TK-09503
*				DAN SO 11/21/2011 D-03631 - POCONum error message not being recorded properly
*				GF 01/08/2011 TK-11760 #145512 PCO detail not validating
*				GF 04/05/2012 TK-13836 #145969 update ChgToTax in POCB
*				GF 04/30/2012 TK-14595 #146332 change to check HQBC for stuck PM interface batches
*				DAN SO 06/18/2012 - TK-15746 - validate Unit of Measure
*				GF 09/17/2012 - TK-17969 use vspHQTaxRateGet for gst rate (single level)
*				GF 10/09/2012 TK-18382 147184 display pending POCO for interface if approved
*				GF 10/10/2012 TK-18416 write out JCCo to POIB table
*				AW 01/08/2013 TK-20643 return error if GLAcct is invalid
*
*
*
* USAGE:
* used by PMInterface to interface a PO change order
* from PM to PO as specified
*
* Pass in :
* PMCo, Project, Mth, GLCo, PO, POCONum
*
* Returns
*	POHB Batchid, Error message and return code
*
*******************************/
(@pmco bCompany = NULL, @project bJob = NULL, @mth bMonth = NULL,
 @glco bCompany = NULL, @po varchar(30) = NULL, @POCONum SMALLINT = NULL, 
 @pobatchid int = NULL OUTPUT, @pocbbatchid int = NULL OUTPUT,
 @postatus tinyint = NULL OUTPUT, @pocbstatus tinyint = NULL output,
 @errmsg varchar(600) output)
AS
SET NOCOUNT ON
   
declare @rcode int, @pohbseq int, @opencursor tinyint, @poco bCompany, @vendorgroup bGroup, @vendor bVendor,
		@reqdate bDate, @materialgroup bGroup, @materialcode bMatl, @vendmtlid varchar(30), @um bUM,
		@recvyn bYN, @location bLoc, @phasegroup bGroup, @phase bPhase, @costtype bJCCType,
		@taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @units bUnits, @unitcost bUnitCost,
		@ecm bECM, @amount bDollar, @taxrate bRate, @taxamount bDollar, @glacct bGLAcct,
		@errtext varchar(255), @pmmfpo varchar(30), @poitem bItem, @errorcount int, @mtldesc bItemDesc,
		@porowcount int,
		@batchtranstype char(1), @contract bContract, @contractitem bContractItem, @requisitionnum varchar(20),
		@department bDept, @approved bYN, @status tinyint, @pocbseq tinyint,
		@pocurunits bUnits, @pocurunitcost bUnitCost, @pocurcost bDollar, @poecm bECM, @pocbunits bUnits,
		@pocbunitcost bUnitCost, @pocbcost bDollar, @factor int, @pmmfseq int, @slseq int, @activeyn bYN,
		@pophase bPhase, @pomaterial bMatl, @poum bUM, @mtldescription bItemDesc, @poitemerr varchar(30),
		@ApprovedDate bDate, @pocbchgtotcost bDollar, @taxphase bPhase,
		@taxct bJCCType, @taxjcum bUM, @chgtotax bDollar, @valueadd varchar(1)

declare @gstrate bRate, @pstrate bRate, @HQTXcrdGLAcct bGLAcct, @HQTXcrdGLAcctPST bGLAcct,  
		@HQTXdebtGLAcct bGLAcct, @oldreqdate bDate, @dflt_matl_group bGroup,
		@oldtaxrate bRate, @oldgstrate bRate, @oldpstrate bRate, @oldHQTXdebtGLAcct bGLAcct,  
		@jccmtdtax bDollar, @supplier bVendor, @ACO bACO, @PMMF_KeyID BIGINT,
		@inusebatchid bBatchID, @source bSource, @inusemth bMonth
		
select @rcode = 0, @errorcount = 0, @porowcount = 0, @opencursor = 0

-- get PO Company from PM Company
select @poco=APCo 
from dbo.PMCO    
where PMCo=@pmco

-- get Default Material Group from HQ Company #137088
select @dflt_matl_group=MatlGroup
from dbo.HQCO   
where HQCo=@poco
if @@rowcount = 0
begin
	select @dflt_matl_group=MatlGroup
	from dbo.HQCO   
	where HQCo=@pmco
end

SET @errorcount = 0

---------------------
-- D-03631 (start) --
---------------------
-- check for data then create batch
if exists (select 1 from dbo.PMMF a where a.PMCo=@pmco AND a.Project=@project AND a.POCo=@poco
				AND a.PO = @po AND a.POCONum = @POCONum AND a.SendFlag = 'Y'
				AND a.MaterialOption = 'P' AND a.InterfaceDate IS NULL
				----TK-11760
				----and (a.RecordType='O' OR (a.RecordType = 'C' AND a.ACO IS NOT NULL))
				AND EXISTS(select 1 from dbo.POHD b where b.POCo=a.POCo and b.PO=a.PO
							AND ISNULL(b.Approved,'Y') = 'Y'))		
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
	
---------------------
-- D-03631 (end) --
---------------------
   
-- declare cursor on PMMF Material Detail for interface to POCB
declare bcPMMF cursor LOCAL FAST_FORWARD
FOR SELECT Seq,PO,POItem,VendorGroup,Vendor,MaterialGroup,MaterialCode,VendMatId,
		MtlDescription, UM,RecvYN,Location,PhaseGroup,Phase,CostType,ReqDate,
		TaxGroup,TaxCode,TaxType, isnull(Units,0),isnull(UnitCost,0),ECM,
		isnull(Amount,0),MtlDescription, RequisitionNum, Supplier, POCONum,
		ACO, KeyID
FROM dbo.bPMMF
WHERE PMCo=@pmco AND Project=@project
	AND POCo = @poco
	AND PO = @po
	AND POCONum = @POCONum
	AND SendFlag='Y'
	AND MaterialOption='P' 
	AND InterfaceDate IS NULL
GROUP BY PO, POItem, Seq, VendorGroup, Vendor, MaterialGroup, MaterialCode, VendMatId,
		MtlDescription, UM, RecvYN, Location, PhaseGroup, Phase, CostType, ReqDate,
		TaxGroup, TaxCode, TaxType, Units, UnitCost, ECM, Amount, MtlDescription,
		RequisitionNum, Supplier, POCONum, ACO, KeyID
   
---- open cursor
OPEN bcPMMF
   
---- set open cursor flag to true
SET @opencursor = 1
   
PMMF_loop:
fetch next from bcPMMF into @pmmfseq, @pmmfpo, @poitem, @vendorgroup, @vendor, @materialgroup,
		@materialcode, @vendmtlid, @mtldesc, @um, @recvyn, @location, @phasegroup, @phase,
		@costtype, @reqdate, @taxgroup, @taxcode, @taxtype, @units, @unitcost, @ecm, @amount,
		@mtldescription, @requisitionnum, @supplier, @POCONum, @ACO, @PMMF_KeyID
   
IF @@fetch_status <> 0 GOTO PMMF_end
IF @@FETCH_STATUS = -1 GOTO PMMF_end


-- get needed PO information
select @approved=Approved, @status=[Status],
		@inusebatchid=InUseBatchId, @inusemth=InUseMth
from dbo.bPOHD   
where POCo=@poco AND PO=@po

---- check header approved when status pending
IF @status = 3 AND ISNULL(@approved,'Y') = 'N' GOTO PMMF_loop


---- valudate POCONum must be ready for accounting and get approved date
SELECT @ApprovedDate = DateApproved
FROM dbo.PMPOCO
WHERE POCo=@poco 
	AND PO=@po
	AND POCONum=@POCONum 
	AND ReadyForAcctg = 'Y'
---- if POCO then ready for accounting flag must be checked
IF @@ROWCOUNT = 0 GOTO PMMF_loop

---- Validate PO record prior to inserting into batch table
if @inusebatchid is not null
	BEGIN
	select @source=[Source] from dbo.HQBC    
	where Co=@poco and BatchId=@inusebatchid and Mth=@inusemth
	if @@rowcount <> 0
		BEGIN
		SELECT @errtext = 'PO: ' + isnull(@pmmfpo,'') + ' already in use by ' +
				convert(varchar(2),DATEPART(month, @inusemth)) + '/' + substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) +
				' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
		END
	ELSE
		BEGIN
		SELECT @errtext='PO already in use by another batch!', @rcode=1
		END

	exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
	select @errorcount = @errorcount + 1
	goto PMMF_loop
	END


---- if no approved date use system date
IF @ApprovedDate IS NULL SET @ApprovedDate = dbo.vfDateOnly()

---- check first for an existing batch to add to. if found
---- we need to set the status back to 0 - open othrewise will
---- not be able to add to. TK-05531
IF @pobatchid <> 0 ----AND @pocbbatchid <> 0
	BEGIN
	---- update the status for batch to 0 - open for additional entries
	UPDATE dbo.bHQBC SET Status = 0
	where Co = @poco and Mth = @mth and BatchId = @pobatchid
	if @@rowcount = 0
		BEGIN
		SELECT @errmsg = 'Unable to update Batch Control information!', @rcode = 1
		select @errorcount = @errorcount + 1
		goto PMMF_loop
		END
	END
	
IF @pocbbatchid <> 0
	BEGIN
	---- try to use existing PO Change order batch id
	UPDATE dbo.bHQBC SET Status = 0
	where Co = @poco and Mth = @mth and BatchId = @pocbbatchid
	if @@rowcount = 0
		BEGIN
		SELECT @errmsg = 'Unable to update Batch Control information!', @rcode = 1
		select @errorcount = @errorcount + 1
		goto PMMF_loop
		END
	END
	
---- no batch existing, so create a POHB batch
if @pobatchid = 0
	BEGIN
	exec @pobatchid = dbo.bspHQBCInsert @poco, @mth,'PM Intface','POHB','N','N',null,null,@errmsg output
	if @pobatchid = 0
		BEGIN
		select @errmsg = @errmsg + ' - Cannot create POHB batch'
		select @errorcount = @errorcount + 1
		goto PMMF_loop
		END

	-- insert batchid into PMBC
	select @slseq=isnull(max(SLSeq),0)+1 
	from dbo.PMBC    
	----TK-05548
	insert into dbo.PMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem, ChangeOrderHeaderBatch)
	select @pmco, @project, @mth, 'POHB', @pobatchid, @poco, @slseq, null, null, NULL, NULL, 'Y'
	END


if @pocbbatchid = 0
	BEGIN
	exec @pocbbatchid = dbo.bspHQBCInsert @poco,@mth,'PM Intface','POCB','N','N',null,null,@errmsg output
	if @pocbbatchid = 0
		BEGIN
		select @errmsg = @errmsg + ' - Cannot create POCB batch'
		select @errorcount = @errorcount + 1
		goto PMMF_loop
		END
		
	-- insert batchid into PMBC
	select @slseq=isnull(max(SLSeq),0)+1
	from dbo.PMBC    

	insert into dbo.PMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
	select @pmco, @project, @mth, 'POCB', @pocbbatchid, @poco, @slseq, null, null, NULL, NULL
	END




-- get next available sequence # for this batch
select @pohbseq = isnull(max(BatchSeq),0)+1
from dbo.POHB    
where Co = @poco and Mth = @mth and BatchId = @pobatchid
	
INSERT INTO dbo.POHB (Co, Mth, BatchId, BatchSeq, BatchTransType, PO, VendorGroup, Vendor, [Description],
		OrderDate, OrderedBy, ExpDate, [Status], JCCo, Job, INCo, Loc, ShipLoc, [Address], City, [State],
		Zip, ShipIns, HoldCode, PayTerms, CompGroup, OldVendorGroup, OldVendor, OldDesc, OldOrderDate,
		OldOrderedBy, OldExpDate, OldStatus, OldJCCo, OldJob, OldINCo, OldLoc, OldShipLoc, OldAddress,
		OldCity, OldState, OldZip, OldShipIns, OldHoldCode, OldPayTerms, OldCompGroup, Attention, OldAttention,
		Notes, PayAddressSeq, OldPayAddressSeq, POAddressSeq, OldPOAddressSeq, Address2, OldAddress2,
		UniqueAttchID, Country, OldCountry)
SELECT @poco, @mth, @pobatchid, @pohbseq, 'C', @pmmfpo, @vendorgroup, @vendor, [Description],
		OrderDate, OrderedBy, ExpDate, 0, JCCo, Job, INCo, Loc, ShipLoc, [Address], City, [State],
		Zip, ShipIns, HoldCode, PayTerms, CompGroup, @vendorgroup, @vendor, [Description], OrderDate,
		OrderedBy, ExpDate, 3, JCCo, Job, INCo, Loc, ShipLoc, [Address], City, [State], Zip,
		ShipIns, HoldCode, PayTerms, CompGroup, Attention, Attention, Notes, PayAddressSeq, PayAddressSeq,
		POAddressSeq, POAddressSeq, Address2, Address2, UniqueAttchID, Country, Country
from dbo.POHD    
where POCo=@poco and PO=@pmmfpo
SET @porowcount = @@ROWCOUNT

if @porowcount <> 1
	begin
	   select @errtext = 'Could not insert PO: ' + isnull(@pmmfpo,'') + ' into batch'
	   exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
	   select @errorcount = @errorcount + 1
	   goto PMMF_loop
	end
else
	begin
		-- update user memos
		exec @rcode = dbo.bspBatchUserMemoInsertExisting @poco, @mth, @pobatchid, @pohbseq, 'PO Entry', 0, @errmsg output
		if @rcode <> 0
		begin
 			select @errmsg = 'Unable to update user memo to PO: ' + isnull(@pmmfpo,'') + ' Batch'
 			select @errorcount = @errorcount + 1
            goto PMMF_loop
 		end
 	end
   
select @poitemerr = ' PO: ' + isnull(@pmmfpo,'') + ' Item: ' + convert(varchar(6),isnull(@poitem,''))

-- Validate Phase and Costtype
exec @rcode = dbo.bspJCADDPHASE @pmco,@project,@phasegroup,@phase,'Y',null,@errmsg output
if @rcode <> 0
begin
   select @errtext = @errmsg + 'Could not add/validate phase.' + @poitemerr
   exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
   select @errorcount = @errorcount + 1
   goto PMMF_loop
end

-- validate cost type
exec @rcode = dbo.bspJCADDCOSTTYPE @jcco=@pmco, @job=@project, @phasegroup=@phasegroup, @phase=@phase, @costtype=@costtype, @um=@um, @override= 'P', @msg=@errmsg output
if @rcode <> 0
begin
	select @errtext = @errmsg + 'Could not add/validate cost type.' + @poitemerr
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

	-- Get GLAcct
	select @contract=[Contract], @contractitem=Item
	from dbo.JCJP   
	where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
	
	select @department=Department
	from dbo.JCCI   
	where JCCo=@pmco and [Contract]=@contract and Item=@contractitem

	-- Get GLAcct
	select @glacct = null
	exec @rcode = dbo.bspJCCAGlacctDflt @pmco, @project, @phasegroup, @phase, @costtype, 'N', @glacct output, @errmsg output
	if @glacct is null
	begin
		select @errtext = 'GL Acct for Cost Type: ' + convert(varchar(3),isnull(@costtype,'')) + 'may not be null' + @poitemerr
		exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMMF_loop
	end

	--verify GLAcct is valid
	exec @rcode = dbo.bspGLACfPostable @glco, @glacct, 'J', @errmsg output
	if @rcode <> 0
	begin
		select @errtext = '- GLAcct:' + isnull(@glacct,'') + ':  ' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg OUTPUT
		SELECT @errorcount = @errorcount + 1
		GOTO PMMF_loop
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
	-- bspPMPOInterface, bspPMSLInterface, and vspPMSLCreateSLItem. The logic should
	-- be similar between the procedures working with tax codes.
	if @taxcode is null
		begin
			select @taxamount=0, @jccmtdtax = 0
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
			--		@HQTXcrdGLAcct output, null, @HQTXdebtGLAcct output, null, @HQTXcrdGLAcctPST output, null, NULL, NULL, @errmsg OUTPUT
			----TK-17969		
			exec @rcode = dbo.vspHQTaxRateGet @taxgroup, @taxcode, @reqdate, @valueadd output, @taxrate output, NULL, NULL, 
						@gstrate output, @pstrate output, null, null, @HQTXdebtGLAcct output, null, null, null, @errmsg output
			if @rcode <> 0
			begin
   				select @errtext = @errmsg + 'Could not get tax rate.' + @poitemerr
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
	select @errtext = 'Must have units when UM is not (LS) and there is an amount.' + @poitemerr
	exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
	select @errorcount = @errorcount + 1
	goto PMMF_loop
end

if @um <> 'LS'
	BEGIN
	IF @ecm IS NULL
		BEGIN
		select @errtext = 'Missing ECM, must be (E,C,M) when UM is not lump sum (LS).' + @poitemerr
		exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMMF_loop
		END
	if @ecm not in ('E', 'C', 'M')
		BEGIN
		select @errtext = 'Missing ECM, must be (E,C,M) when UM is not lump sum (LS).' + @poitemerr
		exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMMF_loop
		END
	END




select @pocurunits=isnull(CurUnits,0), @pocurunitcost=isnull(CurUnitCost,0),
		@pocurcost=isnull(CurCost,0), @poecm=isnull(CurECM,'E'), 
		@pophase=Phase, @pomaterial=Material, @poum=UM
from dbo.POIT   
where POCo=@poco and PO=@pmmfpo and POItem=@poitem
if @@rowcount <> 0
	begin
		if @pophase<>@phase
		begin
		   --#141349
		   select @errtext = 'PO: ' + ISNULL(@pmmfpo,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + '  has different phase'
		   exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid,@errtext,@errmsg output
		   select @errorcount=@errorcount+1
		   goto PMMF_loop
		end
	       
	   if isnull(@pomaterial,'')<>isnull(@materialcode,'')
	   begin
		   --#141349
		   select @errtext = 'PO: ' + ISNULL(@pmmfpo,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + '  has different material code'
		   exec @rcode = dbo.bspHQBEInsert @poco,@mth,@pobatchid,@errtext,@errmsg output
		   select @errorcount=@errorcount+1
		   goto PMMF_loop
		end
	       
	   if isnull(@poum,'')<>isnull(@um,'')
	   begin
		   --#141349
		   select @errtext = 'PO: ' + ISNULL(@pmmfpo,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + '  has different unit of measure'
		   exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
		   select @errorcount = @errorcount + 1
		   goto PMMF_loop
		 end

	   if isnull(@pocurunitcost,0) <> isnull(@unitcost,0)
	   begin
		   --#141349
		   select @errtext = 'PO: ' + ISNULL(@pmmfpo,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + '  has different unit cost'
		   exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
		   select @errorcount = @errorcount + 1
		   goto PMMF_loop
	   end

	   -- need to find the difference to enter the change into the batch
	   select @factor=1
	   if @poecm <> @ecm
	   begin
		   if @ecm='C'
		   begin
			   select @factor=100
		   end
		   if @ecm='M'
		   begin
			   select @factor=1000
		   end
	   end

		-- Insert record into POCB
		-- get next available sequence # for this batch
		select @pocbseq = isnull(max(BatchSeq),0)+1
		from dbo.POCB
		where Co = @poco and Mth = @mth and BatchId = @pocbbatchid

   		---- if the POIT record may have zeros for units, unitcost, and amount treat like inserting
		---- a PO change order to a new PO Item and keep the unit cost
		if @pocurunits <> 0 or @pocurunitcost <> 0 or @pocurcost <> 0
			begin
				select @pocbunitcost = 0
			end
		else
			begin
				select @pocbunitcost = @unitcost
			end

		select @pocbchgtotcost = 0, @pocbcost=@amount
		-- need to calculate ChgTotCost if not 'LS'
   		if @um <> 'LS'
   			begin
   			exec @rcode = dbo.bspPOCBChgTotCost @poco, @mth, @pocbbatchid, @pocbseq, @pmmfpo, @poitem,
				@units, @pocbunitcost, @um, /*DC #120634*/@pocbchgtotcost output,@chgtotax output,/*DC #120634*/@errmsg output
   			end
   		else
   			begin
   				select @pocbchgtotcost = @amount
   			end

		-- add PO change order transaction to batch
		INSERT dbo.bPOCB (Co, Mth, BatchId, BatchSeq, BatchTransType, POTrans, PO, POItem,
				ChangeOrder, ActDate, [Description], UM, ChangeCurUnits, CurUnitCost, ECM, 
				ChangeCurCost, ChangeBOUnits, ChangeBOCost, ChgTotCost,
				----TK-13836
				ChgToTax, POCONum, Notes)
		SELECT @poco, @mth, @pocbbatchid, @pocbseq, 'A', null, @pmmfpo, @poitem,
			@ACO, @ApprovedDate, @mtldesc, @um,
			isnull(@units,0), isnull(@pocbunitcost,0),
			ECM = case when @um='LS' then null else @ecm end, 
   			ChangeCurCost = case when @um='LS' then isnull(@pocbcost,0) else 0 end,
   			isnull(@units,0),
   			ChangeBOCost = case when @um='LS' then isnull(@pocbcost,0)else 0 end,
   			isnull(@pocbchgtotcost,0),
   			----TK-13856
   			ISNULL(@chgtotax,0), POCONum, Notes
		FROM dbo.PMMF
		WHERE KeyID = @PMMF_KeyID
		if @@rowcount = 0
			begin
			 --#141349
			 select @errmsg = 'Could not insert PO: ' + ISNULL(@pmmfpo,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + 'into POCB'
			 exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
			 select @errorcount = @errorcount + 1
			END
			
		-- update IntFlag in PMMF to 'I', needed to update interface date in bspPOHBPost
		--UPDATE dbo.PMMF SET IntFlag='I'
		--WHERE KeyID = @PMMF_KeyID
	END
else
    begin
		-- This is kind of turned around because Carol keeps changing her mind about how this should work.
		-- Sometimes they think a change order item that is not in POIT should automatically be entered into
		-- POIT with 0 orig amounts and sometimes they think an error should be thrown and the user
		-- should enter and interface an original item first.
		-- I'm going to leave this the way it is so this part can easily be removed.
		-- 1/10/99 - now, if the item does not exist and the po is pending (not open), then add
		-- the po item as an original, not a change with $0 original amounts
		-- check PMMF for non interfaced record
		IF EXISTS(SELECT 1 FROM dbo.PMMF WHERE PMCo=@pmco AND Project=@project AND POCo=@poco
					AND PO=@pmmfpo AND POItem=@poitem AND RecordType='O'
					AND InterfaceDate IS NULL AND Seq <> @pmmfseq)
			begin
			---- must interface the original first
			select @errtext = 'The original PO: ' + ISNULL(@pmmfpo,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + ' exists in PMMF but must be interfaced first.'
			exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
			select @errorcount = @errorcount + 1
			goto PMMF_loop
			end

		if @status = 3 -- insert as original
			begin
			INSERT INTO dbo.POIB(Co, Mth, BatchId, BatchSeq, POItem, BatchTransType, ItemType,
					MatlGroup, Material, VendMatId, [Description], UM, RecvYN, PostToCo, Loc, 
					Job, PhaseGroup, Phase, JCCType, GLCo, GLAcct, ReqDate, TaxGroup, TaxCode, 
					TaxType, OrigUnits, OrigUnitCost, OrigECM, OrigCost, OrigTax, RequisitionNum,
					JCCmtdTax, Notes, Supplier, SupplierGroup, TaxRate, GSTRate
					----TK-18416
					,JCCo)
			SELECT @poco, @mth, @pobatchid, @pohbseq, @poitem, 'A', 1, isnull(@materialgroup,@dflt_matl_group),
					@materialcode, @vendmtlid, @mtldescription, @um, @recvyn, @pmco, @location, 
					@project, @phasegroup, @phase, @costtype, @glco, @glacct, @reqdate, @taxgroup, 
					@taxcode, @taxtype, @units, @unitcost, 
					OrigECM = case when @um='LS' then null else @ecm end, 
					@amount, @taxamount, @requisitionnum, @jccmtdtax, Notes, 
					@supplier, @vendorgroup, isnull(@taxrate,0), isnull(@gstrate,0)
					----TK-18416
					,@pmco
			FROM dbo.PMMF 
			WHERE KeyID = @PMMF_KeyID   
			if @@rowcount <> 1
			begin
				--#141349
				select @errorcount = @errorcount + 1
				select @errtext = 'Could not insert PO: ' + ISNULL(@pmmfpo,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + ' into POIT'
				exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMMF_loop
			end

			-- update IntFlag in PMMF to 'I', needed to update interface date in bspPOHBPost
			UPDATE dbo.PMMF SET IntFlag='I'
			WHERE KeyID = @PMMF_KeyID
		end

		if @status = 0
			begin
			---- insert a record into POIT with zero values
			INSERT INTO dbo.bPOIT(POCo, PO, POItem, ItemType, MatlGroup, Material, VendMatId, 
					[Description], UM, RecvYN, PostToCo, Loc, JCCo, Job, PhaseGroup, Phase, 
					JCCType, GLCo, GLAcct, ReqDate, TaxGroup, TaxCode, TaxType, OrigUnits, 
					OrigUnitCost, OrigECM, OrigCost, OrigTax, CurUnits, CurUnitCost, CurECM, CurCost,
					CurTax, RecvdUnits, RecvdCost, BOUnits, BOCost, TotalUnits, TotalCost, TotalTax,
					InvUnits, InvCost, InvTax, RemUnits, RemCost, RemTax, PostedDate, RequisitionNum,
					Notes, Supplier, SupplierGroup, AddedMth, AddedBatchID, TaxRate, GSTRate)
			SELECT @poco, @pmmfpo, @poitem, 1, isnull(@materialgroup,@dflt_matl_group), @materialcode,
					@vendmtlid, @mtldescription, @um, @recvyn, @pmco, @location, @pmco, @project, 
					@phasegroup, @phase, @costtype, @glco, @glacct, @reqdate, @taxgroup, @taxcode,
					@taxtype, 0, 
					OrigUnitCost = 0, ----case when @um='LS' then 0 else @unitcost end, ----TK-06406
					OrigECM      = case when @um='LS' then null else @ecm end, 0, 0, 0,
					CurrUnitCost = 0, ----case when @um='LS' then 0 else @unitcost end, ----TK-06406
					CurECM       = case when @um='LS' then null else @ecm end, 
					0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @ApprovedDate, @requisitionnum,
					Notes, @supplier, @vendorgroup, @mth, @pocbbatchid,
					isnull(@taxrate,0), isnull(@gstrate,0)
			FROM dbo.bPMMF 
			WHERE KeyID = @PMMF_KeyID 
			if @@rowcount <> 1
				begin
				--#141349
				select @errorcount = @errorcount + 1
				select @errtext = 'Could not insert PO: ' + ISNULL(@pmmfpo,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + ' into POIT'
				exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMMF_loop
				END
			ELSE
				BEGIN
				insert into dbo.bPMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, PO, POItem)
				select @pmco, @project, @mth, 'POCB', @pocbbatchid, @poco, @pmmfseq, @pmmfpo, @poitem
				END

			-- get next available sequence # for this batch
			select @pocbseq = isnull(max(BatchSeq),0)+1
			from dbo.bPOCB   
			where Co = @poco and Mth = @mth and BatchId = @pocbbatchid
			
			-- need to calculate ChgTotCost if not 'LS'
			select @pocbchgtotcost = 0
			if @um <> 'LS'
				begin
					exec @rcode = dbo.bspPOCBChgTotCost @poco, @mth, @pocbbatchid, @pocbseq, @pmmfpo, @poitem,
					@units, @unitcost,@um,@pocbchgtotcost output,@chgtotax output,@errmsg output
				end
			else
				begin
					select @pocbchgtotcost = @amount
				end

			-- add PO change order transaction to batch
			INSERT dbo.bPOCB (Co, Mth, BatchId, BatchSeq, BatchTransType, POTrans, PO, POItem,
					ChangeOrder, ActDate, [Description], UM, ChangeCurUnits, CurUnitCost, ECM, 
					ChangeCurCost, ChangeBOUnits, ChangeBOCost, ChgTotCost,
					----TK-13836
					ChgToTax, POCONum, Notes)
			SELECT @poco, @mth, @pocbbatchid, @pocbseq, 'A', null, @pmmfpo, @poitem,
					@ACO, @ApprovedDate, @mtldesc, @um,
					isnull(@units,0), isnull(@unitcost,0),
					ECM = case when @um='LS' then null else @ecm end,
					ChangeCurCost = case when @um='LS' then isnull(@amount,0) else 0 end,
					isnull(@units,0),
					ChangeBOCost = case when @um='LS' then isnull(@amount,0)else 0 end,
					isnull(@pocbchgtotcost,0),
					----TK-13856
					ISNULL(@chgtotax,0), POCONum, Notes
			FROM dbo.bPMMF  
			WHERE KeyID = @PMMF_KeyID
			if @@rowcount <> 1
				begin
				--#141349
				select @errorcount = @errorcount + 1
				select @errtext = 'Could not insert PO: ' + ISNULL(@pmmfpo,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + ' into POCB'
				exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pocbbatchid, @errtext, @errmsg output
				select @errorcount = @errorcount + 1
				goto PMMF_loop
			END
			
			-- update IntFlag in PMMF to 'I', needed to update interface date in bspPOHBPost
			UPDATE dbo.PMMF SET IntFlag='I'
			WHERE KeyID = @PMMF_KeyID
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
	delete dbo.bPOIB where Co=@poco and Mth=@mth and BatchId=@pobatchid
	delete dbo.bPOHB where Co=@poco and Mth=@mth and BatchId=@pobatchid
	delete dbo.bPOCB where Co=@poco and Mth=@mth and BatchId=@pocbbatchid
	
	---- TK-09503 update purge flag so we can delete line 1
	UPDATE dbo.vPOItemLine SET PurgeYN = 'Y'
	FROM dbo.vPOItemLine l
	INNER JOIN dbo.bPOIT i ON i.KeyID = l.POITKeyID
	INNER JOIN dbo.bPMBC c ON c.BatchCo = i.POCo AND c.PO = i.PO AND c.POItem = i.POItem
	where c.Co=@pmco and c.Project=@project 
		AND c.Mth=@mth 
		AND c.BatchId=@pocbbatchid 
		AND c.BatchTable='POCB'
		AND c.PO IS NOT NULL
		AND c.POItem IS NOT NULL
		AND l.POItemLine = 1
		
	---- TK-09503 remove POItemLines added via this process zero value items and lines
	DELETE dbo.vPOItemLine
	FROM dbo.vPOItemLine l
	INNER JOIN dbo.bPOIT i ON i.KeyID = l.POITKeyID
	INNER JOIN dbo.bPMBC c ON c.BatchCo = i.POCo AND c.PO = i.PO AND c.POItem = i.POItem
	where c.Co=@pmco and c.Project=@project 
		AND c.Mth=@mth 
		AND c.BatchId=@pocbbatchid 
		AND c.BatchTable='POCB'
		AND c.PO IS NOT NULL
		AND c.POItem IS NOT NULL
		AND l.POItemLine = 1
		
	---- remove POIT rows added via this process zero value items
	DELETE dbo.bPOIT
	FROM dbo.bPOIT i
	INNER JOIN dbo.bPMBC c ON c.BatchCo = i.POCo AND c.PO = i.PO AND c.POItem = i.POItem
	where c.Co=@pmco and c.Project=@project 
		AND c.Mth=@mth 
		AND c.BatchId=@pocbbatchid 
		AND c.BatchTable='POCB'
		AND c.PO IS NOT NULL
		AND c.POItem IS NOT NULL
		
		
	if @pobatchid<>0
		begin
		exec @rcode = dbo.bspHQBCExitCheck @poco, @mth, @pobatchid, 'PM Intface', 'POHB', @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = @errmsg + ' - Cannot cancel batch '
		end
		END
	
	if @pocbbatchid <> 0
		begin
		exec @rcode = dbo.bspHQBCExitCheck @poco, @mth, @pocbbatchid, 'PM Intface', 'POCB', @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = @errmsg + ' - Cannot cancel batch '
		end
	end

	----TK-14595
	delete dbo.bPMBC 
	where Co=@pmco and Project=@project 
		AND Mth=@mth 
		AND BatchId=@pocbbatchid 
		AND BatchTable='POCB' 
		AND BatchCo=@poco
		AND PO IS NOT NULL
		AND POItem IS NOT NULL

	update dbo.bPMMF set IntFlag=Null
	where PMCo=@pmco and Project=@project 
		AND PO IS NOT NULL
		AND InterfaceDate is null 
		AND IntFlag='I'

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
	from dbo.bHQBC    
	where Co=@poco and Mth=@mth and BatchId=@pobatchid and TableName='POHB'
	
	select @pocbstatus=[Status] 
	from dbo.bHQBC    
	where Co=@poco and Mth=@mth and BatchId=@pocbbatchid and TableName='POCB'
	
	select @errmsg = isNull(@errmsg,'') + ' ' + isnull(@errtext,'')	
	return @rcode
	
	








GO
GRANT EXECUTE ON  [dbo].[vspPMInterfacePOCONum] TO [public]
GO
