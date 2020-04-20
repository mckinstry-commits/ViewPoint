SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPOInterface    Script Date: 8/28/99 9:36:47 AM ******/
   CREATE   proc [dbo].[bspPMPOInterface]
   /*************************************
    * Created By:  LM   4/1/98
    * Modified By: LM   4/1/98
    *              LM 12/11/99 - Added check and update for inactive costtype - must be set to active for interface.
    *              GF 08/31/2000 - Fixed problem w/header data being replaced with item data
    *              GF 12/15/2000 - issue 11649
    *              GF 02/10/2001 - replaced pseudo cursor with cursor
    *              GF 02/23/2001 - changed insert into bPMBC for columns
    *              GF 04/10/2001 - added check for existing PO in batch when adding items
    *              GF 06/09/2001 - added check of @@rowcount after inserts.
    *              GF 10/20/2001 - fixed to null out ecm if UM='LS'
    *				MV 12/11/2001 - Issue 15576 update ud field in POHB - BatchUserMemoInsertExisting
    *				GF 01/22/2002 - added validation for units = 0, amount <> 0 and UM <> 'LS'
    *              allenn 02/22/2002 - issue 14175. new phase override gl accounts from JC Department Master.
    *				GF 03/22/2002 - issue #16717 - fix to interface requisition number.
    *				RM 04/10/02 - Removed @trans parameter from bspBatchUserMemoUpdate call (#16702)
    *				GF 07/30/2002 - issue #17354 - added attention column to POHD.
    *              DANF 09/06/02 -17738 Added Phase group to  bspJCADDCOSTTYPE
    *				MV 11/07/02 - 18037 insert PayAddressSeq, POAddressSeq in bPOHB from bPOHD
    *				GF 12/13/2002 - #19663 not getting correct GLAcct by cost type.
    *				GF 02/19/2003 - #20456 added check for null taxtype with tax code. throw error.
    *				MV 03/13/2003 - #20618 update ud fields in POIB from PMMF
    *				GF 12/10/2003 - #23212 - check error messages, wrap concatenated values with isnull
    *				GF 12/16/2003 - #21541 - added Address2 to insert into bPOHB from bPOHD
    *				GF 04/30/2004 - #24486 - added POItem is not null to cursor where clause
    *				GF 11/30/2004 - #26331 - validate PMMF PO items where unit based must have unit cost.
    *				GF 04/04/2005 - #27559 - added validation for tax phase and tax cost type.
    *				GF 06/28/2005 - issue #29071 - when a tax phase/ct exists, try to add to JCJP and JCCH.
    *				GF 07/05/2005 - issue #29182 - do not assign JCCo, Job to @pmco, @project when adding POHD to POHB.
    *				GF 09/27/2005 - ISSUE #29922 - update POHB.UniqueAttchID from POHD when adding to POHB batch.
    *				GF 10/06/2005 - issue #30006 - back out of issue #26331 zero unit cost
	*				GF 03/12/2008 - issue #127076 insert Country, OldCountry into POHB
	*				GF 09/30/2008 - issue #130033 fix to update POIB.JCCmtdTax with tax amount or if GST/PST then pst part.
	*				GP 12/08/2008 - Issue 131019, added Supplier to bcPMMF cursor and Supplier/SupplierGroup to bPOIB insert.
	*				DC 10/6/2009 - #122288 - Store tax rate in PO Item
	*				GF 11/21/2009 - issue #136679 exclude PO's without vendor
	*				GF 12/15/2009 - issue #137088 - null material group use HQCO.MatlGroup
	*				MV 02/04/10 - issue #136500 - bspHQTaxRateGetAll added NULL output param
	*				GF 09/28/2010 - issue #141349 better error messages (with PO)
	*				GF 10/07/2010 - issue #141562 POHB batch sequence changed to integer.
	*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
	*				MV 10/25/2011 - TK-09243 - bspHQTaxRateGetAll added NULL output param
    *
    *
    * USAGE:
    * used by PMInterface to interface a project or change order from PM to PO as specified
    *
    * Pass in :
    *	PMCo, Project, Mth, GLCo
    *
    *
    * Returns
    *	POHB Batchid, Error message and return code
    *
    *******************************/
   (@pmco bCompany, @project bJob, @mth bMonth, @glco bCompany, @pobatchid int output,
    @status tinyint output, @errmsg varchar(255) output)
   as
   set nocount on
     
declare @rcode int, @pohbseq int, @opencursor tinyint, @vendorgroup bGroup, @vendor bVendor, @reqdate bDate,
		@materialgroup bGroup, @materialcode bMatl, @vendmtlid varchar(30), @um bUM, @recvyn bYN, @location bLoc,
		@phasegroup bGroup, @phase bPhase, @costtype bJCCType, @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint,
		@units bUnits, @unitcost bUnitCost, @ecm bECM, @amount bDollar, @taxrate bRate, @taxamount bDollar,
		@glacct bGLAcct, @errtext varchar(255), @po varchar(30), @poitem bItem, @errorcount int, @department bDept,
		@mtldesc bItemDesc, @contract bContract, @contractitem bContractItem, @requisitionnum varchar(20),
		@slseq int, @inusebatchid bBatchID, @source bSource, @inusemth bMonth, @poco bCompany, @approved bYN,
		@pohdstatus tinyint, @pmmfseq int, @activeyn bYN, @poitemerr varchar(30), @taxphase bPhase,
		@taxct bJCCType, @taxjcum bUM, @valueadd varchar(1)

---- #130033
declare @gstrate bRate, @pstrate bRate, @HQTXcrdGLAcct bGLAcct, @HQTXcrdGLAcctPST bGLAcct,  
		@HQTXdebtGLAcct bGLAcct, @oldreqdate bDate, @dflt_matl_group bGroup,
		@oldtaxrate bRate, @oldgstrate bRate, @oldpstrate bRate, @oldHQTXdebtGLAcct bGLAcct,  
		@jccmtdtax bDollar, @supplier bVendor


select @rcode = 0, @errorcount = 0, @opencursor = 0
 
if @pmco is null or @project is null or @mth is null
      begin
      select @errmsg = 'Missing PO information!', @rcode = 1
      goto bspexit
      end
     
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


-- check for data then create batch
if exists (select 1 from bPMMF a with (nolock) where a.PMCo=@pmco and a.Project=@project and a.POCo=@poco and a.PO is not null
         and a.RecordType='O' and a.SendFlag='Y' and a.MaterialOption='P' and a.InterfaceDate is null
         and exists(select * from bPOHD b where b.POCo=@poco and b.PO=a.PO and b.Approved in ('Y',null)))
  begin
  exec @pobatchid = dbo.bspHQBCInsert @poco, @mth, 'PM Intface', 'POHB', 'N', 'N', null, null, @errmsg output
  if @pobatchid = 0
      begin
      select @errmsg = @errmsg + ' - Cannot create PO batch', @rcode = 1
      exec @rcode = dbo.bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
      select @errorcount = @errorcount + 1
      goto bspexit
      end

 -- insert batchid into PMBC
 select @slseq=isnull(max(SLSeq),0)+1 from bPMBC with (nolock) 
 insert into bPMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)

 select @pmco, @project, @mth, 'POHB', @pobatchid, @poco, @slseq, null, null, null, null
 end
else
  begin
  goto bspexit
  end

-- declare cursor on PMMF Material Detail for interface to POHB and POIT
declare bcPMMF cursor LOCAL FAST_FORWARD
for select Seq,PO,POItem,VendorGroup,Vendor,MaterialGroup,MaterialCode,VendMatId,
	MtlDescription,UM,RecvYN,Location,PhaseGroup,Phase,CostType,ReqDate,TaxGroup,TaxCode,TaxType,
	isnull(Units,0),isnull(UnitCost,0),ECM,isnull(Amount,0), RequisitionNum, Supplier
from bPMMF with (nolock) where PMCo=@pmco and Project=@project and POCo=@poco
and PO is not null and RecordType = 'O' and SendFlag = 'Y'
and MaterialOption='P' and InterfaceDate is null
and POItem is not null and Vendor is not null
group by PO,POItem,Seq,VendorGroup,Vendor,MaterialGroup,MaterialCode,VendMatId,MtlDescription,UM,RecvYN,Location,
PhaseGroup,Phase,CostType,ReqDate,TaxGroup,TaxCode,TaxType,Units,UnitCost,ECM,Amount,RequisitionNum, Supplier

-- open cursor
open bcPMMF
select @opencursor = 1
 
PMMF_loop:
fetch next from bcPMMF into @pmmfseq,@po,@poitem,@vendorgroup,@vendor,@materialgroup,@materialcode,@vendmtlid,
     @mtldesc,@um,@recvyn,@location,@phasegroup,@phase,@costtype,@reqdate,@taxgroup,@taxcode,@taxtype,
     @units,@unitcost,@ecm,@amount,@requisitionnum, @supplier
     
     if @@fetch_status <> 0 goto PMMF_end
     
     -- get needed PO information
     select @approved=Approved, @pohdstatus=Status
     from bPOHD with (nolock) where POCo=@poco and PO=@po and VendorGroup=@vendorgroup and Vendor=@vendor
     
     if @pohdstatus = 3 and @approved in ('N',NULL) goto PMMF_loop
     
     -- Validate record prior to inserting into batch table
     select @inusebatchid=InUseBatchId, @inusemth=InUseMth
     from bPOHD with (nolock) where POCo=@poco and PO=@po
     if @inusebatchid is not null
         begin
         select @source=Source from HQBC with (nolock) 
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
	if exists(select 1 from bPOHB with (nolock) where Co=@poco and Mth=@mth and BatchId=@pobatchid and PO=@po)
		begin
		select @pohbseq=BatchSeq from bPOHB with (nolock) where Co=@poco and Mth=@mth and BatchId=@pobatchid and PO=@po
		end
	else
		begin
		-- get next available sequence # for this batch
		select @pohbseq = isnull(max(BatchSeq),0)+1 from bPOHB where Co = @poco and Mth = @mth and BatchId = @pobatchid
		insert into bPOHB (Co, Mth, BatchId, BatchSeq, BatchTransType, PO, VendorGroup, Vendor, Description, OrderDate,
				OrderedBy, ExpDate, Status, JCCo, Job, INCo, Loc, ShipLoc, Address, City, State, Zip, ShipIns,
				HoldCode, PayTerms, CompGroup, OldVendorGroup, OldVendor, OldDesc, OldOrderDate, OldOrderedBy,
				OldExpDate, OldStatus, OldJCCo, OldJob, OldINCo, OldLoc, OldShipLoc, OldAddress, OldCity,
				OldState, OldZip, OldShipIns, OldHoldCode, OldPayTerms, OldCompGroup, Attention, OldAttention,
				Notes, PayAddressSeq, OldPayAddressSeq, POAddressSeq, OldPOAddressSeq, Address2, OldAddress2,
				UniqueAttchID, Country, OldCountry)
		select @poco, @mth, @pobatchid, @pohbseq, 'C', @po, @vendorgroup, @vendor, Description, OrderDate,
				OrderedBy, ExpDate, 0, JCCo, Job, INCo, Loc, ShipLoc, Address, City, State, Zip, ShipIns,
				HoldCode, PayTerms, CompGroup, @vendorgroup, @vendor, Description, OrderDate, OrderedBy,
				ExpDate, 3, JCCo, Job, INCo, Loc, ShipLoc, Address, City, State, Zip, ShipIns, HoldCode,
				PayTerms, CompGroup, Attention, Attention, Notes,PayAddressSeq, PayAddressSeq, POAddressSeq,
				POAddressSeq, Address2, Address2, UniqueAttchID, Country, Country
		from bPOHD with (nolock) where POCo=@poco and PO=@po
		if @@rowcount <> 1
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
		end
     
     
     -- Insert PO Items into POIB
     select @poitemerr = ' PO: ' + isnull(@po,'') + ' Item: ' + convert(varchar(5),isnull(@poitem,''))
     if exists (select 1 from bPOIT with (nolock) where POCo=@poco and PO=@po and POItem=@poitem)
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
         select @activeyn=ActiveYN from bJCCH with (nolock) 
         where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
         if @activeyn <> 'Y'
             begin
             update bJCCH set ActiveYN='Y'
             where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
             end
     
    	-- Get Contract
        select @contract=Contract, @contractitem=Item from bJCJP with (nolock) 
        where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
    	-- get department
        select @department=Department from bJCCI with (nolock) where JCCo=@pmco and Contract=@contract and Item=@contractitem
    
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

-- -- -- if tax code assigned, validate tax phase and cost type then calculate tax
---- ANY CHANGES MADE TO THIS ROUTINE NEED TO ALSO BE DONE IN bspPMSLACOInterface,
---- bspPMSLInterface, bspPMPOACOInterface, and vspPMSLCreateSLItem. The logic should
---- be similar between the procedures working with tax codes.
if @taxcode is null
	begin
	select @taxamount=0, @jccmtdtax = 0,
		@taxrate = 0, @gstrate = 0  --DC #122288
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
		select @errtext = 'Tax: ' + isnull(@errmsg,'') + ' ' + @poitemerr
		exec @rcode = bspHQBEInsert @poco, @mth, @pobatchid, @errtext, @errmsg output
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

     -- Insert record
     insert into bPOIB(Co, Mth, BatchId, BatchSeq, POItem, BatchTransType, ItemType, MatlGroup, Material, VendMatId,
                 Description, UM, RecvYN, PostToCo, Loc, Job, PhaseGroup, Phase, JCCType, GLCo, GLAcct, ReqDate,
                 TaxGroup, TaxCode, TaxType, OrigUnits, OrigUnitCost, OrigECM, OrigCost, OrigTax, RequisitionNum,
				 JCCmtdTax, Notes, Supplier, SupplierGroup,
				 TaxRate, GSTRate)  --DC #122288
	 ----#137088
     select @poco, @mth, @pobatchid, @pohbseq, @poitem, 'A', 1, isnull(@materialgroup,@dflt_matl_group), @materialcode, @vendmtlid, @mtldesc,
                 @um, @recvyn, @pmco, @location, @project, @phasegroup, @phase, @costtype, @glco, @glacct, @reqdate,
                 @taxgroup, @taxcode, @taxtype, @units, @unitcost,
                 OrigECM = case when @um='LS' then null else @ecm end, @amount, @taxamount, @requisitionnum,
				 @jccmtdtax, Notes, @supplier, @vendorgroup,
				 isnull(@taxrate,0), isnull(@gstrate,0)  --DC #122288 
		from bPMMF with (nolock) where PMCo=@pmco and Project=@project and PO=@po and POItem=@poitem and Seq=@pmmfseq
     if @@rowcount <> 1
         BEGIN
         ----#141349
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
 			BEGIN
 			----#141349
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
         delete bPOIB where Co=@poco and Mth=@mth and BatchId=@pobatchid
         delete bPOHB where Co=@poco and Mth=@mth and BatchId=@pobatchid
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
     
   
   bspexit:
         if @opencursor <> 0
             begin
             close bcPMMF
             deallocate bcPMMF
             select @opencursor = 0
             end
     
          select @status=Status from bHQBC with (nolock) where Co=@poco and Mth=@mth and BatchId=@pobatchid
          return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPOInterface] TO [public]
GO
