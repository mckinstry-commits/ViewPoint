SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************/
CREATE  proc [dbo].[bspPMMOInterface]
/*************************************
* Created By:  GF	02/27/2002
* Modified By: DANF 09/05/02 - 17738 Added Phase Group to bspJCADDCOSTTYPE
*				GF 02/19/2003 - #20456 added check for null taxtype with tax code. throw error.
*				GF 07/11/2003 - #21814 - added user memo insert for INMB and INIB
*				GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
*				GF 04/30/2004 - #24486 - added MOItem is not null to cursor where clause
*				GF 08/20/2004 - #25394 - INIB.Description is only 30-chars. Need to truncate PMMF.MtlDescription
*				GF 06/28/2005 - issue #29071 - when a tax phase/ct exists, try to add to JCJP and JCCH.
*				GF 09/01/2005 - issue #29749 - INMO batches stuck in status 3 or 4. problem was duplicate original
*								entries for a material order and item.
*				GF 09/27/2005 - ISSUE #29922 - update INMB.UniqueAttchID from INMO when adding to INMB batch.
*				DC	01/28/08 - Issue #121529 - Increase the line description to 60.
*				GF 10/30/2008 - issue #130136 inmi notes and pmmf notes changed from varchar(8000) to varchar(max)
*
*
*
* USAGE:
* used by PMInterface to interface a material order from PM to MO as specified.
* this works different from other PM interface SP's. MO does not have change orders
* so the change order piece is part of this SP's instead of a separate SP.
*
* Pass in :
*	PMCo, Project, Mth, GLCo, INCo, ACO
*
*
* Returns
*	INMB Batchid, Error message and return code
*
*******************************/
   (@pmco bCompany, @project bJob, @mth bMonth, @glco bCompany, @inco bCompany,
    @aco bACO, @mobatchid int output, @status tinyint output, @errmsg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @inmbseq tinyint, @moseq int, @pmmfseq int, @opencursor tinyint, @inmostatus tinyint,
   		@reqdate bDate, @materialgroup bGroup, @materialcode bMatl, @um bUM,
   		@location bLoc, @phasegroup bGroup, @phase bPhase, @costtype bJCCType, @taxgroup bGroup,
   		@taxcode bTaxCode, @taxtype tinyint, @units bUnits, @unitcost bUnitCost, @ecm bECM, @amount bDollar,
   		@taxrate bRate, @taxamount bDollar, @glacct bGLAcct, @errtext varchar(255), @mo varchar(10),
   		@moitem bItem, @errorcount int, @department bDept, @mtldesc bItemDesc, @contract bContract,
   		@contractitem bContractItem, @inusebatchid bBatchID, @source bSource, @inusemth bMonth,
   		@approved bYN, @activeyn bYN, @moitemerr varchar(30), @inmiorderedunits bUnits,
   		@inmiunitprice bUnitCost, @inmitotalprice bDollar, @inmiecm bECM, @inmiphase bPhase,
   		@inmimaterial bMatl, @inmium bUM, @inmiloc bLoc, @inmicosttype bJCCType, @inmijcco bCompany,
   		@inmijob bJob, @inmitaxamount bDollar, @inmiremainunits bUnits, @inminotes varchar(max),
   		@pmmfnotes varchar(max),
		@taxphase bPhase, @taxct bJCCType,
   		@taxgetdate bDate, @taxjcum bUM
   
   select @rcode = 0, @errorcount = 0, @opencursor = 0
   
   if isnull(@pmco,0) = 0 or isnull(@project,'') = '' or isnull(@mth,'') = ''
        begin
        select @errmsg = 'Missing MO information!', @rcode = 1
        goto bspexit
        end
   
   
   -- check for data to interface for originals, then create batch
   if isnull(@aco,'') = ''
   BEGIN
   	if exists (select a.INCo from bPMMF a with (nolock) where a.PMCo=@pmco and a.Project=@project and a.RecordType='O'
   		and a.SendFlag='Y' and a.MaterialOption='M' and a.INCo=@inco and a.MO is not null
   		and a.InterfaceDate is null and exists(select b.INCo from bINMO b with (nolock) where b.INCo=a.INCo
   								and b.MO=a.MO and isnull(b.Approved,'Y')='Y'))
        	begin
        	exec @mobatchid = dbo.bspHQBCInsert @inco, @mth, 'PM Intface', 'INMB', 'N', 'N', null, null, @errmsg output
        	if @mobatchid = 0
            	begin
            	select @errmsg = isnull(@errmsg,'') + ' - Cannot create MO batch', @rcode = 1
            	exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
            	select @errorcount = @errorcount + 1
            	goto bspexit
            	end
   
       	-- insert batchid into PMBC
       	select @moseq=isnull(max(SLSeq),0)+1 from bPMBC with (nolock) 
       	insert into bPMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
       	select @pmco, @project, @mth, 'INMB', @mobatchid, @inco, @moseq, null, null, null, null
       	end
   	else
        	begin
        	goto bspexit
        	end
   END
   
   -- check for data to interface for change orders, then create batch
   if isnull(@aco,'') <> ''
   BEGIN
   	if exists (select a.INCo from bPMMF a with (nolock) where a.PMCo=@pmco and a.Project=@project and a.ACO=@aco
   		and a.RecordType='C' and a.SendFlag='Y' and a.MaterialOption='M' and a.INCo=@inco
   		and a.MO is not null and a.InterfaceDate is null
   		and exists(select b.INCo from bINMO b with (nolock) where b.INCo=a.INCo and b.MO=a.MO and isnull(b.Approved,'Y')='Y'))
        	begin
        	exec @mobatchid = dbo.bspHQBCInsert @inco, @mth, 'PM Intface', 'INMB', 'N', 'N', null, null, @errmsg output
        	if @mobatchid = 0
            	begin
            	select @errmsg = isnull(@errmsg,'') + ' - Cannot create MO batch', @rcode = 1
            	exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
            	select @errorcount = @errorcount + 1
            	goto bspexit
            	end
   
       	-- insert batchid into PMBC
       	select @moseq=isnull(max(SLSeq),0)+1 from bPMBC with (nolock) 
       	insert into bPMBC (Co, Project, Mth, BatchTable, BatchId, BatchCo, SLSeq, SL, SLItem, PO, POItem)
       	select @pmco, @project, @mth, 'INMB', @mobatchid, @inco, @moseq, null, null, null, null
       	end
   	else
        	begin
        	goto bspexit
        	end
   END
   
   
   -- declare cursor on PMMF Material Detail for interface to INMB and INIB
   if isnull(@aco,'') = ''
   	begin
   	declare bcPMMF cursor LOCAL FAST_FORWARD for select Seq
   	from bPMMF WITH (NOLOCK)
   	where PMCo=@pmco and Project=@project and RecordType='O' and SendFlag='Y' and MaterialOption='M'
   	and INCo=@inco and MO is not null and InterfaceDate is null and MOItem is not null
   	Group By Seq
   	end
   else
   	begin
   	declare bcPMMF cursor LOCAL FAST_FORWARD for select Seq
   	from bPMMF WITH (NOLOCK)
   	where PMCo=@pmco and Project=@project and ACO=@aco and RecordType='C' and SendFlag='Y'
   	and MaterialOption='M' and INCo=@inco and MO is not null and InterfaceDate is null and MOItem is not null
   	Group By Seq
   	end
   
   
   -- open cursor
   open bcPMMF
   select @opencursor = 1
   
   PMMF_loop:
   fetch next from bcPMMF into @pmmfseq
   
   if @@fetch_status <> 0 goto PMMF_end
   
   -- get PMMF information
   select @mo=MO, @moitem=MOItem, @materialgroup=MaterialGroup, @materialcode=MaterialCode,
   	   @mtldesc=MtlDescription, @um=UM, @location=Location, @phasegroup=PhaseGroup, @phase=Phase,
   	   @costtype=CostType, @reqdate=ReqDate, @taxgroup=TaxGroup, @taxcode=TaxCode, @taxtype=TaxType,
   	   @units=isnull(Units,0), @unitcost=isnull(UnitCost,0), @ecm=ECM, @amount=isnull(Amount,0),
   	   @pmmfnotes=Notes
   from bPMMF where PMCo=@pmco and Project=@project and Seq=@pmmfseq
   
   -- get needed MO information
   select @approved=Approved, @inmostatus=Status
   from bINMO where INCo=@inco and MO=@mo
   if @inmostatus = 3 and isnull(@approved,'N') = 'N' goto PMMF_loop
   
   -- Validate record prior to inserting into batch table
   select @inusebatchid=InUseBatchId, @inusemth=InUseMth
   from bINMO where INCo=@inco and MO=@mo and InUseBatchId <> @mobatchid
   if @inusebatchid is not null
       begin
       select @source=Source from HQBC WITH (NOLOCK)
       where Co=@inco and BatchId=@inusebatchid and Mth=@inusemth
       if @@rowcount<>0
           begin
           select @errtext = 'Transaction already in use by ' +
           convert(varchar(2),DATEPART(month, @inusemth)) + '/' + substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) +
           ' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + isnull(@source,'') +
   		' MO: ' + isnull(@mo,''), @rcode = 1
           end
       else
           begin
           select @errtext='Transaction already in use by another batch!', @rcode=1
           end
   
   
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount = @errorcount + 1
       goto PMMF_loop
       end
   
   -- Insert INMB record
   if exists(select 1 from bINMB with (nolock) where Co=@inco and Mth=@mth and BatchId=@mobatchid and MO=@mo)
       begin
       select @inmbseq=BatchSeq from bINMB with (nolock) where Co=@inco and Mth=@mth and BatchId=@mobatchid and MO=@mo
       end
   else
       begin
       -- get next available sequence # for this batch
       select @inmbseq = isnull(max(BatchSeq),0)+1 from bINMB with (nolock) where Co=@inco and Mth=@mth and BatchId=@mobatchid
       insert into bINMB (Co, Mth, BatchId, BatchSeq, BatchTransType, MO, Description,
   			JCCo, Job, OrderDate, OrderedBy, Status, OldDesc, OldJCCo, OldJob,
   			OldOrderDate, OldOrderedBy, OldStatus, UniqueAttchID, Notes)
       select @inco, @mth, @mobatchid, @inmbseq, 'C', @mo, Description,
   			@pmco, @project, OrderDate, OrderedBy, 0, Description, JCCo, Job,
   			OrderDate, OrderedBy, 3, UniqueAttchID, Notes from bINMO where INCo=@inco and MO=@mo
       if @@rowcount <> 1
           begin
           select @errtext = 'Could not insert MO: ' + isnull(@mo,'') + ' into batch'
           exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
           select @errorcount = @errorcount + 1
           goto PMMF_loop
           end
       else
   		begin
   		-- update user memos
           exec @rcode = dbo.bspBatchUserMemoInsertExisting @inco , @mth , @mobatchid , @inmbseq, 'MO Entry', 0, @errmsg output
   		if @rcode <> 0
   	     	begin
   			select @errtext = 'Unable to update user memo to MO: ' + isnull(@mo,'') + ' batch'
   			exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
   			select @errorcount = @errorcount + 1
           	goto PMMF_loop
   			end
   		end
       end
   
   
   -- if interfacing original MO items the item cannot exist in INMI
   select @moitemerr = ' MO: ' + @mo + ' Item: ' + convert(varchar(10),@moitem)
   if isnull(@aco,'') = '' and exists (select 1 from bINMI with (nolock) where INCo=@inco and MO=@mo and MOItem=@moitem)
       begin
       select @errtext = @moitemerr + ' already exists.'
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount = @errorcount + 1
       goto PMMF_loop
       end
   
   
   -- Validate Phase
   exec @rcode = dbo.bspJCADDPHASE @pmco,@project,@phasegroup,@phase,'Y',null,@errmsg output
   if @rcode <> 0
   	begin
   	select @errtext = isnull(@errmsg,'') + isnull(@moitemerr,'')
   	exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
   	select @errorcount = @errorcount + 1
       goto PMMF_loop
       end
   
   -- validate cost type
   exec @rcode = dbo.bspJCADDCOSTTYPE @jcco=@pmco,@job=@project,@phasegroup=@phasegroup,@phase=@phase,@costtype=@costtype,@um=@um,@override= 'P', @msg=@errmsg output
   if @rcode <> 0
   	begin
       select @errtext = isnull(@errmsg,'') + isnull(@moitemerr,'')
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount = @errorcount + 1
       goto PMMF_loop
       end
   
   -- update active flag if needed
   select @activeyn=ActiveYN from bJCCH WITH (NOLOCK)
   where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
   if @activeyn <> 'Y'
   	begin
       update bJCCH set ActiveYN='Y'
       where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
       end
   
   -- Get GLAcct
   select @contract=Contract, @contractitem=Item from bJCJP WITH (NOLOCK)
   where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
   select @department=Department
   from bJCCI where JCCo=@pmco and Contract=@contract and Item=@contractitem
   
   -- -- -- -- Get GLAcct
   select @glacct = null
   exec @rcode = dbo.bspJCCAGlacctDflt @pmco, @project, @phasegroup, @phase, @costtype, 'N', @glacct output, @errmsg output
   if @glacct is null
    	begin
    	select @errtext = 'GL Acct for Cost Type: ' + convert(varchar(3),@costtype) + ' may not be null'
    	exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
    	select @errorcount = @errorcount + 1
    	goto PMMF_loop
    	end
   
   -- check UM <> 'LS'
   if @um = 'LS'
   	begin
       select @errtext = 'Unit of measure must not be (LS).' + isnull(@moitemerr,'')
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount = @errorcount + 1
       goto PMMF_loop
       end
   
   -- check if units = 0
   if @units = 0
   	begin
       select @errtext = 'Units must not be zero.' + isnull(@moitemerr,'')
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount = @errorcount + 1
       goto PMMF_loop
       end
   
   if @taxtype is null and @taxcode is not null
   	begin
   	select @errtext = 'Tax Code assigned, but missing Tax Type for material.' + isnull(@moitemerr,'')
   	exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
   	select @errorcount = @errorcount + 1
   	goto PMMF_loop
   	end
   
   -- calculate tax amount for po items
   if @taxcode is null
       begin
       select @taxamount=0
       end
   else
   	begin
   	select @taxphase = null, @taxct = null, @taxgetdate = getdate()
   	-- -- -- validate Tax Code
   	exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @taxgetdate, @taxrate output, @taxphase output, @taxct output, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errtext = isnull(@errmsg,'') + ' ' + @moitemerr
   		exec @rcode = bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
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
   			select @errtext = 'Tax: ' + isnull(@errmsg,'') + ' ' + @moitemerr
   			exec @rcode = bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
   			select @errorcount = @errorcount + 1
   			goto PMMF_loop
   			end
   
   	-- -- -- calculate tax
       exec @rcode = dbo.bspHQTaxRateGet @taxgroup, @taxcode, null, @taxrate output, null, null, @errmsg output
       if @rcode <> 0
   		begin
   		select @errtext = isnull(@errmsg,'') + 'Could not get tax rate.' + isnull(@moitemerr,'')
           exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
           select @errorcount = @errorcount + 1
           goto PMMF_loop
           end
       select @taxamount = (@amount * @taxrate)
       end
   
   



   -- -- -- -- calculate tax amount for mo items
   -- -- -- if @taxcode is null
   -- -- --     begin
   -- -- --     select @taxamount=0
   -- -- --     end
   -- -- -- else
   -- -- --     begin
   -- -- --     exec @rcode = dbo.bspHQTaxRateGet @taxgroup, @taxcode, null, @taxrate output, null, null, @errmsg output
   -- -- --     if @rcode <> 0
   -- -- -- 		begin
   -- -- -- 		select @errtext = isnull(@errmsg,'') + 'Could not get tax rate.' + isnull(@moitemerr,'')
   -- -- --         exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
   -- -- --         select @errorcount = @errorcount + 1
   -- -- --         goto PMMF_loop
   -- -- --         end
   -- -- --     select @taxamount = (@amount * @taxrate)
   -- -- --     end
   
   
   -- if original we are done. Insert INIB record and goto next PMMF sequence.
   if isnull(@aco,'') = ''
   	begin
   	-- -- -- check if MOItem already exists in INIB - issue #29749
   	if exists(select Co from bINIB where Co=@inco and Mth=@mth and BatchId=@mobatchid and BatchSeq=@inmbseq and MOItem=@moitem)
   		begin
   		select @errtext = @moitemerr + ' already exists in batch.'
   		exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
           select @errorcount = @errorcount + 1
           goto PMMF_loop
           end
   	-- -- -- insert record
   	insert into bINIB(Co, Mth, BatchId, BatchSeq, MOItem, BatchTransType, Loc, MatlGroup, Material, Description,
   			JCCo, Job, PhaseGroup, Phase, JCCType, GLCo, GLAcct, ReqDate, UM, OrderedUnits, UnitPrice,
   			ECM, TotalPrice, TaxGroup, TaxCode, TaxAmt, RemainUnits, Notes)
   	select @inco, @mth, @mobatchid, @inmbseq, @moitem, 'A', @location, @materialgroup, @materialcode, @mtldesc,
   			@pmco, @project, @phasegroup, @phase, @costtype, @glco, @glacct, @reqdate, @um, @units, @unitcost,
   			@ecm, @amount, @taxgroup, @taxcode, @taxamount, @units, Notes from bPMMF where PMCo=@pmco and Project=@project and Seq=@pmmfseq 
   	if @@rowcount = 0 
           begin
           select @errtext = 'Could not insert MO Item ' + isnull(@moitemerr,'')
           exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
           select @errorcount = @errorcount + 1
           goto PMMF_loop
           end
   	else
   		begin
   		-- update user memos
           exec @rcode = dbo.bspBatchUserMemoInsertExisting @inco, @mth, @mobatchid, @inmbseq, 'MO Entry Items PM Interface', @moitem, @errmsg output
   		if @rcode <> 0
   	     	begin
   			select @errtext = 'Unable to update user memo ' + isnull(@moitemerr,'')
   			exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
   			select @errorcount = @errorcount + 1
           	goto PMMF_loop
   			end
   		end
   
   	goto PMMF_loop
   	end
   
   -- this is tricky, since there are no change orders for MO's we need to only allow the MO item
   -- to be inserted into INIB once. Throw error if already exists in INIB
   if exists(select Co from bINIB with (nolock) where Co=@inco and Mth=@mth and BatchId=@mobatchid and MOItem=@moitem) 
   	begin
   	select @errtext = @moitemerr + ' already exists in batch.'
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount = @errorcount + 1
       goto PMMF_loop
       end
   
   -- if change order and not exists in INMI, insert like original and goto next PMMF sequence.
   select @inmiorderedunits=OrderedUnits, @inmiunitprice=UnitPrice, @inmitotalprice=TotalPrice,
          @inmiecm=ECM, @inmiphase=Phase, @inmicosttype=JCCType, @inmimaterial=Material, @inmium=UM,
   	   @inmiloc=Loc, @inminotes=Notes, @inmijcco=JCCo, @inmijob=Job, @inmiremainunits=RemainUnits,
   	   @inmitaxamount=TaxAmt
   from bINMI with (nolock) where INCo=@inco and MO=@mo and MOItem=@moitem
   if @@rowcount = 0
   	begin
   	-- insert INIB record
   	insert into bINIB(Co, Mth, BatchId, BatchSeq, MOItem, BatchTransType, Loc, MatlGroup, Material, Description,
   			JCCo, Job, PhaseGroup, Phase, JCCType, GLCo, GLAcct, ReqDate, UM, OrderedUnits, UnitPrice,
   			ECM, TotalPrice, TaxGroup, TaxCode, TaxAmt, RemainUnits, Notes)
   	select @inco, @mth, @mobatchid, @inmbseq, @moitem, 'A', @location, @materialgroup, @materialcode, @mtldesc,
   			@pmco, @project, @phasegroup, @phase, @costtype, @glco, @glacct, @reqdate, @um, @units, @unitcost,
   			@ecm, @amount, @taxgroup, @taxcode, @taxamount, @units, Notes from bPMMF with (nolock) where PMCo=@pmco and Project=@project and Seq=@pmmfseq 
   	if @@rowcount = 0
           begin
           select @errtext = 'Could not insert into batch ' + isnull(@moitemerr,'')
           exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
           select @errorcount = @errorcount + 1
           goto PMMF_loop
           end
   	else
   		begin
   		-- update user memos
           exec @rcode = dbo.bspBatchUserMemoInsertExisting @inco, @mth, @mobatchid, @inmbseq, 'MO Entry Items PM Interface', @moitem, @errmsg output
   		if @rcode <> 0
   	     	begin
   			select @errtext = 'Unable to update user memo ' + isnull(@moitemerr,'')
   			exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
   			select @errorcount = @errorcount + 1
           	goto PMMF_loop
   			end
   		end
   
   	goto PMMF_loop
   	end
   
   
   -- more validation needed for change order MO Items
   if @inmijcco <> @pmco
   	begin
       select @errtext = 'MO Item: ' + convert(varchar(10),isnull(@moitem,'')) + '  has different JC company'
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount=@errorcount+1
       goto PMMF_loop
       end
   
   if @inmijob <> @project
   	begin
       select @errtext = 'MO Item: ' + convert(varchar(10),isnull(@moitem,'')) + '  has different JC Job'
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount=@errorcount+1
       goto PMMF_loop
       end
   
   if @inmiloc <> @location
   	begin
       select @errtext = 'MO Item: ' + convert(varchar(10),isnull(@moitem,'')) + '  has different location'
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount=@errorcount+1
       goto PMMF_loop
       end
   
   if @inmiphase <> @phase
   	begin
       select @errtext = 'MO Item: ' + convert(varchar(10),isnull(@moitem,'')) + '  has different phase'
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount=@errorcount+1
       goto PMMF_loop
       end
   
   if @inmicosttype <> @costtype
   	begin
       select @errtext = 'MO Item: ' + convert(varchar(10),isnull(@moitem,'')) + '  has different cost type'
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount=@errorcount+1
       goto PMMF_loop
       end
   
   if @inmimaterial <> @materialcode
   	begin
       select @errtext='MO Item: ' + convert(varchar(10),isnull(@moitem,'')) + '  has different material code'
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount=@errorcount+1
       goto PMMF_loop
       end
   
   if @inmium <> @um
   	begin
       select @errtext='MO Item: ' + convert(varchar(10),isnull(@moitem,'')) + '  has different unit of measure'
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount = @errorcount + 1
       goto PMMF_loop
       end
   
   if @inmiecm <> @ecm
   	begin
   	select @errtext='MO Item: ' + convert(varchar(10),isnull(@moitem,'')) + '  has different ECM'
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount = @errorcount + 1
       goto PMMF_loop
       end
   
   if @inmiunitprice <> 0 and @unitcost <> 0
   	begin
   	if @inmiunitprice <> @unitcost
   		begin
           select @errtext='MO Item: ' + convert(varchar(10),isnull(@moitem,'')) + '  has different unit price'
           exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
           select @errorcount = @errorcount + 1
           goto PMMF_loop
           end
       end
   
   -- if notes are empty in INMI and PMMF set to null
   if isnull(@inminotes,'') = '' and isnull(@pmmfnotes,'') = ''
   	begin
   	select @inminotes = null
   	goto MOITEM_ACO_INSERT
   	end
   -- if INMI notes are empty and PMMF notes are not set to PMMF notes
   if isnull(@inminotes,'') = '' and isnull(@pmmfnotes,'') <> ''
   	begin
   	select @inminotes = @pmmfnotes
   	goto MOITEM_ACO_INSERT
   	end
   -- if INMI and PMMF notes are not empty concatenate
   if isnull(@inminotes,'') <> '' and isnull(@pmmfnotes,'') <> ''
   	begin
   	select @inminotes = @inminotes + CHAR(13) + CHAR(10) + @pmmfnotes
   	end
   
   MOITEM_ACO_INSERT:
   -- insert INIB record
   insert into bINIB(Co, Mth, BatchId, BatchSeq, MOItem, BatchTransType, Loc, MatlGroup, Material, Description,
   		JCCo, Job, PhaseGroup, Phase, JCCType, GLCo, GLAcct, ReqDate, UM, OrderedUnits, UnitPrice,
   		ECM, TotalPrice, TaxGroup, TaxCode, TaxAmt, RemainUnits, OldLoc, OldMatlGroup, OldMaterial,
   		OldDesc, OldJCCo, OldJob, OldPhaseGroup, OldPhase, OldJCCType, OldGLCo, OldGLAcct, OldReqDate,
   		OldUM, OldOrderedUnits, OldUnitPrice, OldECM, OldTotalPrice, OldTaxGroup, OldTaxCode,
   		OldTaxAmt, OldRemainUnits, Notes)
   select @inco, @mth, @mobatchid, @inmbseq, @moitem, 'C', @location, @materialgroup, @materialcode, @mtldesc,
   		@pmco, @project, @phasegroup, @phase, @costtype, @glco, @glacct, @reqdate, @um,
   		@inmiorderedunits + @units, @unitcost, @ecm, @inmitotalprice + @amount, @taxgroup, @taxcode,
   		@inmitaxamount + @taxamount, @inmiremainunits + @units, b.Loc, b.MatlGroup, b.Material,
   		b.Description, b.JCCo, b.Job, b.PhaseGroup, b.Phase, b.JCCType, b.GLCo, b.GLAcct, b.ReqDate,
   		b.UM, b.OrderedUnits, b.UnitPrice, b.ECM, b.TotalPrice, b.TaxGroup, b.TaxCode,
   		b.TaxAmt, b.RemainUnits, @inminotes
   from bINMI b with (nolock) where b.INCo=@inco and b.MO=@mo and b.MOItem=@moitem
   if @@rowcount = 0
   	begin
       select @errtext = 'Could not insert into batch ' + isnull(@moitemerr,'')
       exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
       select @errorcount = @errorcount + 1
       end
   else
   	begin
   	-- update user memos
       exec @rcode = dbo.bspBatchUserMemoInsertExisting @inco, @mth, @mobatchid, @inmbseq, 'MO Entry Items PM Interface', @moitem, @errmsg output
   	if @rcode <> 0
   	     begin
   		select @errtext = 'Unable to update user memo ' + isnull(@moitemerr,'')
   		exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
   		select @errorcount = @errorcount + 1
           goto PMMF_loop
   		end
   	end
   
   goto PMMF_loop
   
   
   
   
   
   
   PMMF_end:
       if @opencursor = 1
           begin
           close bcPMMF
           deallocate bcPMMF
           set @opencursor = 0
           end
   
   if @errorcount > 0
       begin
       -- undo everything
       delete bINIB where Co=@inco and Mth=@mth and BatchId=@mobatchid
       delete bINMB where Co=@inco and Mth=@mth and BatchId=@mobatchid
       if @mobatchid <> 0
           begin
           exec @rcode = dbo.bspHQBCExitCheck @inco, @mth, @mobatchid, 'PM Intface', 'INMB', @errmsg output
           if @rcode <> 0
              begin
              select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel batch '
              end
           end
           select @rcode = 1
        end
   
   
   
   
   bspexit:
       if @opencursor = 1
           begin
           close bcPMMF
           deallocate bcPMMF
           select @opencursor = 0
           end
   
        select @status=Status from bHQBC with (nolock) where Co=@inco and Mth=@mth and BatchId=@mobatchid
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMMOInterface] TO [public]
GO
