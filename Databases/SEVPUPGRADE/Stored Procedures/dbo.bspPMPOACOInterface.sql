SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPOACOInterface    Script Date: 8/28/99 9:36:46 AM ******/
CREATE   proc [dbo].[bspPMPOACOInterface]
/*************************************
* CREATED BY:   LM  4/17/98
* MODIFIED By : GF 03/21/2000 - Added check for different phase\material\um.
*               GF 04/11/2000 - Added check for unit price difference
*               GF 09/21/2000 - Update POCB notes.
*               GF 12/15/2000 - issue #11649
*               GF 02/13/2001 - replaced pseudo cursor with cursor
*               GF 02/23/2001 - changed insert into bPMBC for columns
*               GF 10/20/2001 - fixed to null out ecm if UM='LS'
*				 GF 01/22/2002 - added validation for units = 0, amount <> 0 and UM <> 'LS'
*               allenn 02/22/2002 - issue 14175. new phase override gl accounts from JC Department Master.
*				 GF 03/22/2002 - issue #16717 - fix to interface requisition number.
*				 GF 07/30/2002 - issue #17354 - Added Attention column to bPOHB.
*				 GF 08/07/2002 - issue #18232 - error during interface converting varchar to numeric. Problem
*								 Problem was that the requisitionnum column was out of sequence in insert statement.
*				DANF 09/05/02 - 17738 Added phase group to bspJCADDCOSTTYPE
*				MV 11/07/02 - #18037 insert PayAddressSeq and POAddressSeq in bPOHB from bPOHD
*				GF 12/13/2002 - issue #19663 - fixed for wrong gl acct when cost type changed.
*				GF 02/19/2003 - #20456 added check for null taxtype with tax code. throw error.
*				GF 12/10/2003 - #23212 - check error messages, wrap concatenated values with isnull
*				GF 12/16/2003 - #21541 - added Address2 to insert into bPOHB from bPOHD
*				GF 04/30/2004 - #24486 - added POItem is not null to cursor where clause
*				GF 06/01/2004 - #24142 - update users memos when inserting POHB batch row for PO.
*				GF 11/03/2004 - issue #24409-#25054 use the PMOI.ApprovedDate as Actual Date for PO change orders
*				GF 11/30/2004 - #26331 - validate PMMF PO items where unit based must have unit cost.
*				GF 01/04/2005 - #26666 - update PMMF.IntFlag for PO items added to POIB as originals. needed for interface date update.
*				GF 02/15/2005 - issue #27096 calculate POCB.ChgTotCost and insert into POCB. Enhancement #22320
*				GF 04/04/2005 - #27559 - added validation for tax phase and tax cost type.
*				GF 06/06/2005 - issue #28816 - change bPOCB insert to only update ChgTotCost and ChgBOCost when UM = LS
*				GF 06/28/2005 - issue #29071 - when a tax phase/ct exists, try to add to JCJP and JCCH.
*				GF 07/05/2005 - issue #29182 - do not assign JCCo, Job to @pmco, @project when adding POHD to POHB.
*				GF 09/23/2005 - issue #29903 - when UM='LS' set @pocbchgtotcost = @amount
*				GF 09/27/2005 - ISSUE #29922 - update POHB.UniqueAttchID from POHD when adding to POHB batch.
*				GF 10/06/2005 - issue #30006 - back out of issue #26331 zero unit cost
*				GF 08/09/2007 - issue #125251 - check POIT item for zero units,uc,amount. if all zero keep pmmf uc.
*				DC 01/29/2008 - issue #121529 - Increase the PO change order line description to 60.
*				GF 03/12/2008 - issue #127076 insert Country, OldCountry into POHB
*				DC 05/07/2008 - issue #120634 - Add a column to POCD for ChgToTax
*				GF 09/30/2008 - issue #130033 fix to update POIB.JCCmtdTax with tax amount or if GST/PST then pst part.
*				GP 12/08/2008 - Issue 131019, added Supplier to bcPMMF cursor and Supplier/SupplierGroup to bPOIB insert.
*				GF 01/25/2009 - issue #131992 insert AddedMth, AddedBatchID into POIT
*				GF 09/01/2009 - issue #135391 added JCCo to insert for bPOIT
*				GF 11/21/2009 - issue #136679 exclude PO's without vendor
*				GF 12/02/2009 - issue #136807 when creating zero value item in POIT, set unit cost if not 'LS'.
*				GF 12/15/2009 - issue #137088 - null material group use HQCO.MatlGroup
*				DC 12/22/2009 - issue #122288 - Store Tax Rate in POIT
*				MV 02/04/10 - issue #136500 - bspHQTaxRateGetAll added NULL output param
*				GF 09/28/2010 - issue #141349 better error messages (with PO)
*				GF 10/07/2010 - issue #141562 POHB batch sequence changed to integer.
*				GF 04/16/2011 - TK-03989 POCONum
*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				MV 10/25/2011 - TK-09243 - bspHQTaxRateGetAll added NULL output param
*
*
* USAGE:
* used by PMInterface to interface a change order from PM to PO as specified
*
* Pass in :
*	PMCo, Project, Mth, ACO, GLCo
*
*
* Returns
*	POHB Batchid, Error message and return code
*
*******************************/
(@pmco bCompany, @project bJob, @mth bMonth, @aco bACO, @glco bCompany, @pobatchid int output,
 @pocbbatchid int output, @postatus tinyint output, @pocbstatus tinyint output,
 @errmsg varchar(255) output)
as
set nocount on
   
declare @rcode int, @pohbseq int, @opencursor tinyint, @poco bCompany, @vendorgroup bGroup, @vendor bVendor,
		@reqdate bDate, @materialgroup bGroup, @materialcode bMatl, @vendmtlid varchar(30), @um bUM,
		@recvyn bYN, @location bLoc, @phasegroup bGroup, @phase bPhase, @costtype bJCCType,
		@taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @units bUnits, @unitcost bUnitCost,
		@ecm bECM, @amount bDollar, @taxrate bRate, @taxamount bDollar, @glacct bGLAcct,
		@errtext varchar(255), @po varchar(30), @poitem bItem, @errorcount int, @mtldesc bItemDesc,
		@porowcount int,
		@batchtranstype char(1), @contract bContract, @contractitem bContractItem, @requisitionnum varchar(20),
		@department bDept, @actdate bDate, @approved bYN, @status tinyint, @pocbseq tinyint,
		@pocurunits bUnits, @pocurunitcost bUnitCost, @pocurcost bDollar, @poecm bECM, @pocbunits bUnits,
		@pocbunitcost bUnitCost, @pocbcost bDollar, @factor int, @pmmfseq int, @slseq int, @activeyn bYN,
		@pophase bPhase, @pomaterial bMatl, @poum bUM, @mtldescription bItemDesc, @poitemerr varchar(30),
		@approved_date bDate, @acoitem bACOItem, @pocbchgtotcost bDollar, @taxphase bPhase,
		@taxct bJCCType, @taxjcum bUM, @chgtotax bDollar, @valueadd varchar(1)

---- #130033
declare @gstrate bRate, @pstrate bRate, @HQTXcrdGLAcct bGLAcct, @HQTXcrdGLAcctPST bGLAcct,  
		@HQTXdebtGLAcct bGLAcct, @oldreqdate bDate, @dflt_matl_group bGroup,
		@oldtaxrate bRate, @oldgstrate bRate, @oldpstrate bRate, @oldHQTXdebtGLAcct bGLAcct,  
		@jccmtdtax bDollar, @supplier bVendor, @POCONum SMALLINT
		
select @rcode = 0, @errorcount = 0, @porowcount = 0, @opencursor = 0, @pobatchid = 0, @pocbbatchid = 0
   
---- get PO Company from PM Company
select @poco=APCo from bPMCO with (nolock) where PMCo=@pmco
---- get Default Material Group from HQ Company #137088
select @dflt_matl_group=MatlGroup
from dbo.HQCO with (nolock) where HQCo=@poco
if @@rowcount = 0
	begin
	select @dflt_matl_group=MatlGroup
	from dbo.HQCO with (nolock) where HQCo=@pmco
	end

-- set actual date
select @actdate=CONVERT(varchar(12), getdate())
   
-- declare cursor on PMMF Material Detail for interface to POCB
declare bcPMMF cursor LOCAL FAST_FORWARD
for select Seq,PO,POItem,VendorGroup,Vendor,MaterialGroup,MaterialCode,VendMatId,MtlDescription,
	UM,RecvYN,Location,PhaseGroup,Phase,CostType,ReqDate,TaxGroup,TaxCode,TaxType,
	isnull(Units,0),isnull(UnitCost,0),ECM,isnull(Amount,0),MtlDescription, RequisitionNum,
	ACOItem, Supplier, POCONum
from bPMMF where PMCo=@pmco and Project=@project and ACO=@aco and POCo=@poco
and PO is not null and RecordType='C' and SendFlag='Y'
and MaterialOption='P' and InterfaceDate is null
and POItem is not null and Vendor is not null
group by PO,POItem,Seq,VendorGroup,Vendor,MaterialGroup,MaterialCode,VendMatId,MtlDescription,
UM,RecvYN,Location,PhaseGroup,Phase,CostType,ReqDate,TaxGroup,TaxCode,TaxType,Units,UnitCost,
ECM,Amount,MtlDescription,RequisitionNum,ACOItem, Supplier, POCONum
   
   -- open cursor
   open bcPMMF
   
   --set open cursor flag to true
   select @opencursor = 1
   
   PMMF_loop:
   fetch next from bcPMMF into @pmmfseq,@po,@poitem,@vendorgroup,@vendor,@materialgroup,@materialcode,@vendmtlid,
           @mtldesc,@um,@recvyn,@location,@phasegroup,@phase,@costtype,@reqdate,@taxgroup,@taxcode,@taxtype,
           @units,@unitcost,@ecm,@amount,@mtldescription,@requisitionnum, @acoitem, @supplier,
           ---- TK-03989
           @POCONum
   
   if @@fetch_status <> 0 goto PMMF_end
   
   -- get needed PO information
   select @approved=Approved, @status=Status
   from bPOHD with (nolock) where POCo=@poco and PO=@po and VendorGroup=@vendorgroup and Vendor=@vendor
   
   if @status = 3 and @approved in ('N',NULL) goto PMMF_loop
   
	---- TK-03989 if POCO then ready for accounting flag must be checked
	IF ISNULL(@POCONum,0) > 0
		BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM dbo.PMPOCO c WHERE c.POCo=@poco AND c.PO=@po
						AND c.POCONum=@POCONum AND c.ReadyForAcctg = 'N')
			BEGIN
			GOTO PMMF_loop
			END
		END
   
   
   if @pobatchid = 0
       begin
       exec @pobatchid = dbo.bspHQBCInsert @poco,@mth,'PM Intface','POHB','N','N',null,null,@errmsg output
       if @pobatchid = 0
           begin
           select @errmsg = @errmsg + ' - Cannot create POHB batch'
           goto bspexit
           end
       -- insert batchid into PMBC
       select @slseq=isnull(max(SLSeq),0)+1 from bPMBC with (nolock) 
       insert into bPMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
       select @pmco, @project, @mth, 'POHB', @pobatchid, @poco, @slseq, null, null, @po, @poitem
       end
   
   if @pocbbatchid=0
       begin
       exec @pocbbatchid = dbo.bspHQBCInsert @poco,@mth,'PM Intface','POCB','N','N',null,null,@errmsg output
       if @pocbbatchid = 0
           begin
           select @errmsg = @errmsg + ' - Cannot create POCB batch'
           goto bspexit
           end
       -- insert batchid into PMBC
       select @slseq=isnull(max(SLSeq),0)+1 from bPMBC with (nolock) 
       insert into bPMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
       select @pmco, @project, @mth, 'POCB', @pocbbatchid, @poco, @slseq, null, null, @po, @poitem
       end
   
	-- get next available sequence # for this batch
	select @pohbseq = isnull(max(BatchSeq),0)+1 from bPOHB with (nolock) where Co = @poco and Mth = @mth and BatchId = @pobatchid
	insert into bPOHB (Co, Mth, BatchId, BatchSeq, BatchTransType, PO, VendorGroup, Vendor, Description,
			OrderDate, OrderedBy, ExpDate, Status, JCCo, Job, INCo, Loc, ShipLoc, Address, City, State,
			Zip, ShipIns, HoldCode, PayTerms, CompGroup, OldVendorGroup, OldVendor, OldDesc, OldOrderDate,
			OldOrderedBy, OldExpDate, OldStatus, OldJCCo, OldJob, OldINCo, OldLoc, OldShipLoc, OldAddress,
			OldCity, OldState, OldZip, OldShipIns, OldHoldCode, OldPayTerms, OldCompGroup, Attention, OldAttention,
			Notes, PayAddressSeq, OldPayAddressSeq, POAddressSeq, OldPOAddressSeq, Address2, OldAddress2,
			UniqueAttchID, Country, OldCountry)
	select @poco, @mth, @pobatchid, @pohbseq, 'C', @po, @vendorgroup, @vendor, Description,
			OrderDate, OrderedBy, ExpDate, 0, JCCo, Job, INCo, Loc, ShipLoc, Address, City, State,
			Zip, ShipIns, HoldCode, PayTerms, CompGroup, @vendorgroup, @vendor, Description, OrderDate,
			OrderedBy, ExpDate, 3, JCCo, Job, INCo, Loc, ShipLoc, Address, City, State, Zip,
			ShipIns, HoldCode, PayTerms, CompGroup, Attention, Attention, Notes, PayAddressSeq, PayAddressSeq,
			POAddressSeq, POAddressSeq, Address2, Address2, UniqueAttchID, Country, Country
	from bPOHD with (nolock) where POCo=@poco and PO=@po
	select @porowcount = @@rowcount
   if @porowcount <> 1
       begin
       select @errtext = 'Could not insert PO: ' + isnull(@po,'') + ' into batch'
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
     		select @errmsg = 'Unable to update user memo to PO: ' + isnull(@po,'') + ' Batch'
     		select @errorcount = @errorcount + 1
                 goto PMMF_loop
     		end
     	end
   
   
   select @poitemerr = ' PO: ' + isnull(@po,'') + ' Item: ' + convert(varchar(6),isnull(@poitem,''))
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
   from bJCCH with (nolock) where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
   if @activeyn <> 'Y'
       begin
       update bJCCH set ActiveYN='Y'
       where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
       end
   
   -- Get GLAcct
   select @contract=Contract, @contractitem=Item
   from bJCJP with (nolock) where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
   select @department=Department
   from bJCCI with (nolock) where JCCo=@pmco and Contract=@contract and Item=@contractitem
   
   
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
   
if @taxtype is null and @taxcode is not null
	begin
	select @errtext = 'Tax Code assigned, but missing Tax Type for material.' + @poitemerr
	exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
	select @errorcount = @errorcount + 1
	goto PMMF_loop
	end
 
-- -- -- if tax code assigned, validate tax phase and cost type then calculate tax
---- ANY CHANGES MADE TO THIS ROUTINE NEED TO ALSO BE DONE IN bspPMSLACOInterface,
---- bspPMPOInterface, bspPMSLInterface, and vspPMSLCreateSLItem. The logic should
---- be similar between the procedures working with tax codes.
if @taxcode is null
	begin
	select @taxamount=0, @jccmtdtax = 0
	end
else
   	begin
   	select @taxphase = null, @taxct = null
   	-- -- -- validate Tax Code
   	exec @rcode = bspPOTaxCodeVal @taxgroup, @taxcode, @taxtype, @taxphase output, @taxct output, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errtext = isnull(@errmsg,'') + ' ' + @poitemerr
   		exec @rcode = bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
   		select @errorcount = @errorcount + 1
   		goto PMMF_loop
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
   			select @errtext = 'Tax: ' + isnull(@errmsg,'') + ' ' + @poitemerr
   			exec @rcode = bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
   			select @errorcount = @errorcount + 1
   			goto PMMF_loop
   			end
   
	---- calculate tax
	exec @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, @reqdate, @valueadd output, @taxrate output, @gstrate output, @pstrate output, 
			@HQTXcrdGLAcct output, null, @HQTXdebtGLAcct output, null, @HQTXcrdGLAcctPST output, null, NULL, NULL, @errmsg output
	if @rcode <> 0
		begin
   		select @errtext = @errmsg + 'Could not get tax rate.' + @poitemerr
		exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
		select @errorcount = @errorcount + 1
		goto PMMF_loop
		end

	---- calculate tax amount
	select @taxamount = @amount * @taxrate
	select @jccmtdtax = 0
	---- if tax code is value added then calculate tht JC tax that will only be the PST portion
	if isnull(@valueadd,'N') = 'Y' and @pstrate <> 0
		begin
		select @jccmtdtax = @amount * @pstrate
		end			
	else
		begin
		select @jccmtdtax = @taxamount
		end	
   	end


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
   
  -- -- --  if @um <> 'LS' and @unitcost = 0
  -- -- --  	begin
  -- -- --  	select @errtext = 'Must have unit cost when UM is not lump sum (LS).' + @poitemerr
  -- -- --      exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
  -- -- --      select @errorcount = @errorcount + 1
  -- -- --      goto PMMF_loop
  -- -- --      end
   
-- validate units when UM <> 'LS' and Amount <> 0
if @um <> 'LS' and @amount <> 0 and @units = 0
	begin
	select @errtext = 'Must have units when UM is not (LS) and there is an amount.' + @poitemerr
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

-- -- -- get the PMOI.ApprovedDate for ACO Item
set @approved_date = null
if isnull(@aco,'') <> ''
	begin
	select @approved_date = ApprovedDate
	from bPMOI where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
	end

---- if sending ACO sub CO's then use the @approved_date if not null else system date
if isnull(@aco,'') <> '' and isnull(@approved_date,'') <> '' set @actdate = @approved_date

select @pocurunits=isnull(CurUnits,0), @pocurunitcost=isnull(CurUnitCost,0), @pocurcost=isnull(CurCost,0),
      @poecm=isnull(CurECM,'E'), @pophase=Phase, @pomaterial=Material, @poum=UM
from dbo.bPOIT with (nolock) where POCo=@poco and PO=@po and POItem=@poitem
if @@rowcount <> 0
	BEGIN
	if @pophase<>@phase
       BEGIN
       ----#141349
       select @errtext = 'PO: ' + ISNULL(@po,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + '  has different phase'
       exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid,@errtext,@errmsg output
       select @errorcount=@errorcount+1
       goto PMMF_loop
       end
       
   if isnull(@pomaterial,'')<>isnull(@materialcode,'')
       BEGIN
       ----#141349
       select @errtext = 'PO: ' + ISNULL(@po,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + '  has different material code'
       exec @rcode = dbo.bspHQBEInsert @poco,@mth,@pobatchid,@errtext,@errmsg output
       select @errorcount=@errorcount+1
       goto PMMF_loop
       end
       
   if isnull(@poum,'')<>isnull(@um,'')
       BEGIN
       ----#141349
       select @errtext = 'PO: ' + ISNULL(@po,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + '  has different unit of measure'
       exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
       select @errorcount = @errorcount + 1
       goto PMMF_loop
       end

   if isnull(@pocurunitcost,0) <> isnull(@unitcost,0)
       BEGIN
       ----#141349
       select @errtext = 'PO: ' + ISNULL(@po,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + '  has different unit cost'
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

	---- Insert record into POCB
	---- get next available sequence # for this batch
	select @pocbseq = isnull(max(BatchSeq),0)+1 from dbo.bPOCB
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
	---- need to calculate ChgTotCost if not 'LS'
   	if @um <> 'LS'
   		begin
   		exec @rcode = dbo.bspPOCBChgTotCost @poco, @mth, @pocbbatchid, @pocbseq, @po, @poitem,
									@units, @pocbunitcost, 
									@um, --DC #120634
									@pocbchgtotcost output, 
									@chgtotax output, --DC #120634
									@errmsg output
   		end
   	else
   		begin
   		select @pocbchgtotcost = @amount
   		end

       -- add PO change order transaction to batch
       insert bPOCB (Co, Mth, BatchId, BatchSeq, BatchTransType, POTrans, PO, POItem, ChangeOrder, ActDate, Description,
                   UM, ChangeCurUnits, CurUnitCost, ECM, ChangeCurCost, ChangeBOUnits, ChangeBOCost, ChgTotCost,
                   ----TK-03989
                   POCONum, Notes)
       select @poco, @mth, @pocbbatchid, @pocbseq, 'A', null, @po, @poitem, @aco, @actdate, @mtldesc, @um,
                   isnull(@units,0), isnull(@pocbunitcost,0),
                   ECM = case when @um='LS' then null else @ecm end, 
   				ChangeCurCost = case when @um='LS' then isnull(@pocbcost,0) else 0 end,
   				isnull(@units,0),
   				ChangeBOCost = case when @um='LS' then isnull(@pocbcost,0)else 0 end,
   				isnull(@pocbchgtotcost,0),
   				----TK-03989
                POCONum, Notes
                from bPMMF with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and PO=@po and POItem=@poitem and Seq=@pmmfseq
       if @@rowcount = 0
           BEGIN
           ----#141349
           select @errmsg = 'Could not insert PO: ' + ISNULL(@po,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + 'into POCB'
           exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
           select @errorcount = @errorcount + 1
           end
       end
   ELSE
       begin
       -- This is kind of turned around because Carol keeps changing her mind about how this should work.
       -- Sometimes they think a change order item that is not in POIT should automatically be entered into
       -- POIT with 0 orig amounts and sometimes they think an error should be thrown and the user
       -- should enter and interface an original item first.
       -- I'm going to leave this the way it is so this part can easily be removed.
       -- 1/10/99 - now, if the item does not exist and the po is pending (not open), then add
       -- the po item as an original, not a change with $0 original amounts
       -- check PMMF for non interfaced record
       if exists (select 1 from bPMMF with (nolock) where PMCo=@pmco and Project=@project and POCo=@poco and PO=@po
                       and POItem=@poitem and RecordType='O' and InterfaceDate is null)
           BEGIN
           ----#141349
           select @errtext = 'The original PO: ' + ISNULL(@po,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + ' exists in PMMF but must be interfaced first.'
           exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
           select @errorcount = @errorcount + 1
           goto PMMF_loop
           end
   
       if @status = 3 -- insert as original
           begin
           insert into bPOIB(Co, Mth, BatchId, BatchSeq, POItem, BatchTransType, ItemType, MatlGroup, Material, VendMatId,
                   Description, UM, RecvYN, PostToCo, Loc, Job, PhaseGroup, Phase, JCCType, GLCo, GLAcct,
                   ReqDate, TaxGroup, TaxCode, TaxType, OrigUnits, OrigUnitCost, OrigECM, OrigCost, OrigTax, RequisitionNum,
				   JCCmtdTax, Notes, Supplier, SupplierGroup,
				   TaxRate, GSTRate)  --DC #122288
           select @poco, @mth, @pobatchid, @pohbseq, @poitem, 'A', 1, isnull(@materialgroup,@dflt_matl_group), @materialcode, @vendmtlid,
                   @mtldescription, @um, @recvyn, @pmco, @location, @project, @phasegroup, @phase, @costtype, @glco, @glacct,
                   @reqdate, @taxgroup, @taxcode, @taxtype, @units, @unitcost,
                   OrigECM = case when @um='LS' then null else @ecm end, @amount, @taxamount, @requisitionnum,
                   @jccmtdtax, Notes, @supplier, @vendorgroup,
                   isnull(@taxrate,0), isnull(@gstrate,0)  --DC #122288 
                   from bPMMF with (nolock) where PMCo=@pmco and Project=@project and PO=@po and POItem=@poitem and Seq=@pmmfseq
           if @@rowcount <> 1
               BEGIN
               ----#141349
               select @errtext = 'Could not insert PO: ' + ISNULL(@po,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + ' into POIT'
               exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
               select @errorcount = @errorcount + 1
               goto PMMF_loop
               end
   
   		-- -- -- update IntFlag in PMMF to 'I', needed to update interface date in bspPOHBPost
   		Update bPMMF set IntFlag='I'
   		where PMCo=@pmco and Project=@project and PO=@po and POItem=@poitem and Seq=@pmmfseq
        end
   
       if @status = 0
           begin
           ---- #135391
           insert into bPOIT(POCo, PO, POItem, ItemType, MatlGroup, Material, VendMatId, Description, UM, RecvYN,
                   PostToCo, Loc, JCCo, Job, PhaseGroup, Phase, JCCType, GLCo, GLAcct, ReqDate, TaxGroup, TaxCode, TaxType,
                   OrigUnits, OrigUnitCost, OrigECM, OrigCost, OrigTax, CurUnits, CurUnitCost, CurECM, CurCost,
                   CurTax, RecvdUnits, RecvdCost, BOUnits, BOCost, TotalUnits, TotalCost, TotalTax, InvUnits,
                   InvCost, InvTax, RemUnits, RemCost, RemTax, PostedDate, RequisitionNum, Notes,
					Supplier, SupplierGroup, AddedMth, AddedBatchID,
					TaxRate, GSTRate)  --DC #122288
           select @poco, @po, @poitem, 1, isnull(@materialgroup,@dflt_matl_group), @materialcode, @vendmtlid, @mtldescription, @um, @recvyn,
                   @pmco, @location, @pmco, @project, @phasegroup, @phase, @costtype, @glco, @glacct, @reqdate, @taxgroup,
                   @taxcode, @taxtype, 0, 
                   OrigUnitCost = case when @um='LS' then 0 else @unitcost end, ----#136807
                   OrigECM      = case when @um='LS' then null else @ecm end, 0, 0, 0, 0,
                   CurECM       = case when @um='LS' then null else @ecm end, 
                   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @actdate, @requisitionnum,
                   Notes, @supplier, @vendorgroup, @mth, @pocbbatchid,
                   isnull(@taxrate,0), isnull(@gstrate,0)  --DC #122288 
                   from bPMMF with (nolock) where PMCo=@pmco and Project=@project and PO=@po and POItem=@poitem and Seq=@pmmfseq
           if @@rowcount <> 1
               BEGIN
               ----#141349
               select @errtext = 'Could not insert PO: ' + ISNULL(@po,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + ' into POIT'
               exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
               select @errorcount = @errorcount + 1
               goto PMMF_loop
               end
   
           -- get next available sequence # for this batch
           select @pocbseq = isnull(max(BatchSeq),0)+1 from bPOCB with (nolock) where Co = @poco and Mth = @mth and BatchId = @pocbbatchid
   		-- -- -- need to calculate ChgTotCost if not 'LS'
   		select @pocbchgtotcost = 0
   		if @um <> 'LS'
   			begin
   			exec @rcode = dbo.bspPOCBChgTotCost @poco, @mth, @pocbbatchid, @pocbseq, @po, @poitem,
									@units, @unitcost, 
									@um, --DC #120634
									@pocbchgtotcost output, 
									@chgtotax output,  --DC #120634
									@errmsg output
   			end
   		else
   			begin
   			select @pocbchgtotcost = @amount
   			end
   
           -- add PO change order transaction to batch
           insert bPOCB (Co, Mth, BatchId, BatchSeq, BatchTransType, POTrans, PO, POItem, ChangeOrder, ActDate,
                   Description, UM, ChangeCurUnits, CurUnitCost, ECM, ChangeCurCost, ChangeBOUnits, ChangeBOCost, ChgTotCost,
                   ----TK-03989
                   POCONum, Notes)
           select @poco, @mth, @pocbbatchid, @pocbseq, 'A', null, @po, @poitem, @aco, @actdate, @mtldesc, @um,
                   isnull(@units,0), isnull(@unitcost,0),
                   ECM = case when @um='LS' then null else @ecm end,
   				ChangeCurCost = case when @um='LS' then isnull(@amount,0) else 0 end,
   				isnull(@units,0),
   				ChangeBOCost = case when @um='LS' then isnull(@amount,0)else 0 end,
   				isnull(@pocbchgtotcost,0),
   				----TK-03989
                POCONum, Notes
                from bPMMF with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and PO=@po and POItem=@poitem and Seq=@pmmfseq
           if @@rowcount <> 1
               BEGIN
               ----#141349
               select @errtext = 'Could not insert PO: ' + ISNULL(@po,'') + ' PO Item: ' + convert(varchar(10),isnull(@poitem,'')) + ' into POCB'
               exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pocbbatchid, @errtext, @errmsg output
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
       delete bPOIB where Co=@poco and Mth=@mth and BatchId=@pobatchid
       delete bPOHB where Co=@poco and Mth=@mth and BatchId=@pobatchid
       delete bPOCB where Co=@poco and Mth=@mth and BatchId=@pocbbatchid
       if @pobatchid<>0
           begin
           exec @rcode = dbo.bspHQBCExitCheck @poco, @mth, @pobatchid, 'PM Intface', 'POHB', @errmsg output
           if @rcode <> 0
               begin
               select @errmsg = @errmsg + ' - Cannot cancel batch '
               end
           end
       if @pocbbatchid <> 0
           begin
           exec @rcode = dbo.bspHQBCExitCheck @poco, @mth, @pocbbatchid, 'PM Intface', 'POCB', @errmsg output
           if @rcode <> 0
               begin
               select @errmsg = @errmsg + ' - Cannot cancel batch '
               end
           end
   
       delete bPMBC where Co=@pmco and Project=@project and Mth=@mth
       and BatchId=@pocbbatchid and BatchTable='POCB' and BatchCo=@poco
   
   	-- -- -- reset PMMF.IntFlag to null
   	update bPMMF set IntFlag=Null
  
   	where PMCo=@pmco and Project=@project and PO is not null and InterfaceDate is null and IntFlag='I'
   
   	select @rcode = 1
       end
   
   
   
   
   
   bspexit:
   	if @opencursor <> 0
   		begin
           close bcPMMF
           deallocate bcPMMF
           select @opencursor = 0
           end
   
   	select @postatus=Status from bHQBC with (nolock) 
   	where Co=@poco and Mth=@mth and BatchId=@pobatchid and TableName='POHB'
   	select @pocbstatus=Status from bHQBC with (nolock) 
   	where Co=@poco and Mth=@mth and BatchId=@pocbbatchid and TableName='POCB'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPOACOInterface] TO [public]
GO
