SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************/
CREATE proc [dbo].[bspPMTemplateCopy]
/***********************************************************
 * CREATED BY: GR 7/16/99
 * MODIFIED By : GR 1/12/00
 *             : GR 2/19/00 -added to default taxcode, retainage pct and billing description from JCCM
 *             : GR 3/27/00 -changed the billing description default to pull from PMTP as per issue 6226
 *             : GF 03/01/2001 - create PMSL record if cost type is a subcontract as specified in PMCo
 *             : GF 10/12/2001 - use SICode from PMTP when creating contract items. issue #14853
 *				: GF 11/26/2001 - use UM for SICode depending on JCCM.SIMetric flag. issue #14853
 *				: GF 08/05/2002 - #18077 need to add cost types even if phase already exists. Also
 *								  need to use valid part job if entire phase not in JCPM.
 *				: GF 09/03/2002 - #18373 - use SICode if no contract item.
 *				: GF 10/30/2002 - #19151 - need to check ItemUnitFlag and PhaseUnitFlag for nulls. Set to 'N'.
 *				: GF 02/17/2003 - #19209 - look for first cost type with bill flag 'Y' for item to get desc and um.
 *				: GF 12/11/2003 - #23212 - check error messages, wrap concatenated values with isnull
 *				: GF 01/20/2005 - #26895 - if cost type missing, set UM='LS', Bill Flag='C' and add cost type to JCCH.
 *				: GF 12/05/2007 - #126400 - need to set contract item to '1' if none available.
 *				: GF 11/28/2008 - issue #131100 expanded phase description
 *				: GF 04/20/2009 - issue #132323 jcci start month cannot be null
 *
 *
 *
 * USAGE: This SP is used to copy all the phases into JCJP
 * for the template passed and all the costtypes for each
 * phase into JCCH for the given template
 *
 * an error is returned if any of the following occurs
 * no template passed, no project passed
 *
 * INPUT PARAMETERS
 *   PMCo   		PM Company
 *   Project    	Project for the template to be copied
 *   Template		Template to copy
 *
 * OUTPUT PARAMETERS
 *   @msg      error message if error occurs
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@pmco bCompany = 0, @template varchar(10) = null, @project bJob = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @contract bContract, @phasegroup tinyint, @phase bPhase, @phasedesc bItemDesc,
		@item bContractItem, @projminpct bPct, @validcnt int, @costtype bJCCType, @costtypedesc bDesc,
		@um bUM, @billflag varchar(1), @itemunitflag bYN, @phaseunitflag bYN, @buyoutyn bYN,
		@contractitem bContractItem, @opencontractitem int, @taxgroup bGroup, @department bDept,
		@billtype bBillType, @description bDesc, @tempphase bPhase, @retainagepct bPct, @taxcode bTaxCode,
   		@billdesc bDesc, @slcosttype bJCCType, @units bUnits, @unitcost bUnitCost, @amount bDollar,
   		@siregion varchar(6), @sicode varchar(16), @simetric bYN, @sium bUM, @simum bUM, @itemum bUM,
   		@errmsg varchar(255), @minitem bContractItem, @pphase varchar(20), @validphasechars int,
   		@inputmask varchar(30), @usevalidpartphase tinyint, @vitem varchar(16), @phasemask varchar(30),
   		@ctum bUM, @itemlength varchar(10), @pdesc bItemDesc, @addjcsicode bYN, @itemsicode varchar(16),
   		@openPMTP int, @openPMTD int, @jcjp_count int, @jcch_count int, @jccm_startmonth bMonth

select @rcode = 0, @opencontractitem = 0, @openPMTP = 0, @openPMTD = 0, @usevalidpartphase = 0,
   		@jcjp_count = 0, @jcch_count = 0

if @pmco is null
    	begin
    	select @msg = 'Missing PM Company!', @rcode = 1
    	goto bspexit
    	end

if @project is null
    	begin
    	select @msg = 'Missing project!', @rcode = 1
    	goto bspexit
    	end

if @template is null
   	begin
   	select @msg = 'Missing template!', @rcode = 1
   	goto bspexit
   	end
   
   -- check JCCO - get valid phase characters and bill type
   select @validphasechars = ValidPhaseChars, @billtype = isnull(DefaultBillType,'P'),
   	   @addjcsicode=isnull(AddJCSICode,'N')
   from JCCO with (nolock) where JCCo=@pmco
   if @@rowcount=0
   	begin
   	select @msg = 'JC Company ' + convert(varchar(3), @pmco) + ' not found', @rcode = 1
   	goto bspexit
   	end

if @validphasechars = 0
	begin
   	select @msg = 'Missing Valid Part Phase in JCCo.', @rcode = 1
   	goto bspexit
   	end
   
   -- get input mask for bContractItem
   select @inputmask = InputMask, @itemlength = convert(varchar(10), InputLength)
   from DDDTShared with (nolock) where Datatype = 'bContractItem'
   if isnull(@inputmask,'') = '' select @inputmask = 'R'
   if isnull(@itemlength,'') = '' select @itemlength = '16'
   if @inputmask in ('R','L')
   	begin
   	select @inputmask = @itemlength + @inputmask + 'N'
   	end
   
   -- get subcontract cost type from PMCO
   select @slcosttype=SLCostType from PMCO with (nolock) where PMCo=@pmco
   
   -- get contract for the job
   select @contract=Contract
   from JCJM with (nolock) where JCCo=@pmco and Job=@project
   if @@rowcount = 0
       begin
       select @msg = 'Job ' + @project + ' not found!', @rcode = 1
       goto bspexit
       end
   
   -- get department for this contract
   select @department=Department, @retainagepct=RetainagePCT, @taxcode=TaxCode,
          @siregion=SIRegion, @simetric=SIMetric, @jccm_startmonth=StartMonth
   from JCCM with (nolock) where JCCo=@pmco and Contract=@contract
   if @@rowcount = 0
   	begin
   	select @msg = 'Contract: ' + isnull(@contract,'') + ' not found!', @rcode = 1
   	goto bspexit
   	end
   
   if isnull(@department,'') = ''
       begin
       select @msg = 'Missing Department for contract: ' + isnull(@contract,'') + '!', @rcode=1
       goto bspexit
       end
   
   --get phasegroup and taxgroup for this company
   select @phasegroup=PhaseGroup, @taxgroup=TaxGroup from HQCO with (nolock) where HQCo=@pmco
   if @@rowcount = 0
       begin
       select @msg = 'Phase Group for HQ Company ' + convert(varchar(3),@pmco) + ' not found!', @rcode = 1
       goto bspexit
       end
   
   --Before inserting check whether contract items are set up for this item
   declare contractitem_cursor cursor LOCAL FAST_FORWARD
   for select Item, Phase, SICode
   from PMTP with (nolock) 
   where PMCo=@pmco and Template=@template and PhaseGroup=@phasegroup
   group by Phase, Item, SICode
   
   open contractitem_cursor
   select @opencontractitem = 1
   
   contractitem_cursor_loop:       -- loop through all the records
   
   fetch next from contractitem_cursor into @item, @tempphase, @sicode
   
   if @@fetch_status <> 0 goto PMTP_end
   
   	set @ctum = null
   	set @sium = null
   	set @simum = null
   	set @itemum = null
   	set @pdesc = null
   	set @description = null
   	set @itemsicode = @sicode
   	set @contractitem = @item
   
   	-- if missing contract item, but SICode assigned use SICode as item
   	if isnull(@contractitem, '') = '' and isnull(@itemsicode, '') <> ''
   		begin
   		select @vitem = rtrim(ltrim(@itemsicode))
   		exec dbo.bspHQFormatMultiPart @vitem, @inputmask, @contractitem output
   		end
   
   	-- when no SI region assigned to contract - then no SICode
   	if isnull(@siregion,'') = '' select @itemsicode = null
   
   	-- get SI Code info
   	if isnull(@itemsicode,'') <> ''
   		begin
   		select @description=Description, @sium=UM, @simum=MUM
   		from JCSI with (nolock) where SIRegion=@siregion and SICode=@itemsicode
   		if @@rowcount = 0 and @addjcsicode = 'N' select @itemsicode = null
   		end
   
---- if not contract item use first from JCCI
if isnull(@contractitem, '') = ''
	begin
	select @contractitem=min(Item) from JCCI with (nolock)
	where JCCo=@pmco and Contract=@contract
	---- if still missing set to '1'
	if @@rowcount = 0 or isnull(@contractitem,'') = ''
		begin
   		select @vitem = '1'
   		exec dbo.bspHQFormatMultiPart @vitem, @inputmask, @contractitem output
		end
	end

---- get phase description and cost type UM where Bill Flag = 'Y'
select top 1 @pdesc=a.Description, @ctum=c.UM
from PMTP a with (nolock) 
left join PMTD b with (nolock) on b.PMCo=a.PMCo and b.Template=a.Template and b.Phase=a.Phase
left join JCPC c with (nolock) on c.PhaseGroup=b.PhaseGroup and c.Phase=b.Phase and c.CostType=b.CostType
where a.PMCo=@pmco and a.Template=@template and a.Item=@item and a.SICode=@sicode and c.BillFlag = 'Y'
and @item is not null and @sicode is not null
if @@rowcount = 0 
   		begin
   		select top 1 @pdesc=a.Description, @ctum=c.UM
   		from PMTP a with (nolock) 
   		left join PMTD b with (nolock) on b.PMCo=a.PMCo and b.Template=a.Template and b.Phase=a.Phase
   		left join JCPC c with (nolock) on c.PhaseGroup=b.PhaseGroup and c.Phase=b.Phase and c.CostType=b.CostType
   		where a.PMCo=@pmco and a.Template=@template and a.Item=@item and c.BillFlag = 'Y'
   		and @item is not null and @sicode is null
   		if @@rowcount = 0
   			begin
   			select top 1 @pdesc=a.Description, @ctum=c.UM
   			from PMTP a with (nolock) 
   			left join PMTD b with (nolock) on b.PMCo=a.PMCo and b.Template=a.Template and b.Phase=a.Phase
   			left join JCPC c with (nolock) on c.PhaseGroup=b.PhaseGroup and c.Phase=b.Phase and c.CostType=b.CostType
   			where a.PMCo=@pmco and a.Template=@template and a.SICode=@sicode and c.BillFlag = 'Y'
   
   			and @item is null and @sicode is not null
   			if @@rowcount = 0
   				begin
   				select top 1 @pdesc=Description 
   				from PMTP with (nolock) where PMCo=@pmco and Template=@template and Item=@contractitem
   				Group by PMCo, Template, Phase, Description
   				if @@rowcount = 0
   					begin
   					select top 1 @pdesc=Description 
   					from PMTP with (nolock) where PMCo=@pmco and Template=@template and SICode=@sicode
   					Group by PMCo, Template, Phase, Description
   					end
   				end
   			end
   		end
   
   		if isnull(@description,'') = '' select @description = @pdesc
   
   		if @simetric = 'Y' select @itemum = isnull(@simum,@sium)
   
   		if isnull(@itemum,'') = '' select @itemum = @sium
   
   		if isnull(@itemum,'') = '' select @itemum = @ctum
   
   		if isnull(@itemum,'') = '' select @itemum='LS'
   
   		if isnull(@siregion,'') = '' select @sicode = null
   
   		---- insert into JCCI
   		if not exists(select top 1 1 from JCCI with (nolock) where JCCo=@pmco and Contract=@contract and Item=@contractitem)
   			begin
   			insert JCCI (JCCo, Contract, Item, Description, Department, TaxGroup, TaxCode, SIRegion, SICode,
   					UM, RetainPCT, OrigContractAmt, OrigContractUnits, OrigUnitPrice, ContractAmt,
   					ContractUnits, UnitPrice, BilledAmt, BilledUnits, ReceivedAmt,
   					CurrentRetainAmt, BillType, BillDescription, BillOriginalUnits, BillOriginalAmt,
   					BillCurrentUnits, BillCurrentAmt, BillUnitPrice, StartMonth)
   			values (@pmco, @contract, @contractitem, @description, @department, @taxgroup, @taxcode, @siregion, @itemsicode,
   					@itemum, @retainagepct, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @billtype, @description, 0, 0, 0, 0, 0, @jccm_startmonth)
   			end
   
   -- get next contract item
   goto contractitem_cursor_loop
   
   
   
   
   PMTP_end:
   -- close and deallocate the contractitem cursor
   if @opencontractitem = 1
   	begin
   	close contractitem_cursor
   	deallocate contractitem_cursor
   	select @opencontractitem = 0
   	end
   
   
   /*******************************************************
   * Create pseudo cursor for PMTP Template phases. There
   * will be a pseudo cursor inside PMTP for PMTD Template
   * phase cost types.
   ********************************************************/
   
   select @minitem=min(Item) from JCCI with (nolock) where JCCo=@pmco and Contract=@contract
   
   -- create cursor on PMTP for template phases
   declare PMTP_cursor cursor LOCAL FAST_FORWARD
   for select Phase, Description, Item, SICode
   from PMTP with (nolock) 
   where PMCo=@pmco and Template=@template
   
   open PMTP_cursor
   select @openPMTP = 1
   
   openPMTP_loop:       -- loop through all the records
   
   fetch next from PMTP_cursor into @phase, @phasedesc, @item, @sicode
   
   if @@fetch_status <> 0 goto openPMTP_end
   
   -- if missing contract item, but SICode assigned use SICode as item
   if isnull(@item, '') = '' and isnull(@sicode, '') <> ''
   	begin
   	select @vitem = rtrim(ltrim(@sicode))
   	exec bspHQFormatMultiPart @vitem, @inputmask, @item output
   	end
   
   -- if missing item set to minimum item
   if isnull(@item,'') = '' select @item=@minitem
   
---- check if valid part phase needed
select @projminpct=isnull(ProjMinPct,0), @usevalidpartphase = 0
from JCPM with (nolock) where PhaseGroup=@phasegroup and Phase=@phase
if @@rowcount = 0
	begin
	---- get the mask for bPhase
   	select @usevalidpartphase = 1
	select @phasemask=InputMask from DDDTShared with (nolock) where Datatype = 'bPhase'
	---- format valid portion of phase
   
	select @pphase=substring(@phase,1,@validphasechars) + '%'
	select TOP 1 @projminpct=isnull(ProjMinPct,0)
	from JCPM with (nolock) where PhaseGroup = @phasegroup and Phase like @pphase
	Group By PhaseGroup, Phase, ProjMinPct
	end

---- insert phase into bJCJP if not exists
if not exists(select top 1 1 from JCJP with (nolock) where JCCo=@pmco and Job=@project and Phase=@phase)
   	begin
   	insert JCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN)
   	select @pmco, @project, @phasegroup, @phase, @phasedesc, @contract, @item, @projminpct, 'Y'
   	select @jcjp_count = @jcjp_count + 1
   	end

	---- Before inserting check whether contract items are set up for this item
	declare PMTD_cursor cursor LOCAL FAST_FORWARD
	for select CostType, Description
	from PMTD with (nolock) 
	where PMCo=@pmco and Template=@template and Phase=@phase

	open PMTD_cursor
	select @openPMTD = 1

	openPMTD_loop:       -- loop through all the records

	fetch next from PMTD_cursor into @costtype, @costtypedesc

	if @@fetch_status <> 0 goto openPMTD_end

	---- get cost type data depending on whether using valid part phase flag
	if @usevalidpartphase = 0
		begin
		---- get UM, Billflag, Itemunitflag, PhaseUnitFlag for this costtype
		select @um=UM, @billflag=BillFlag, @itemunitflag=ItemUnitFlag, @phaseunitflag=PhaseUnitFlag
		from JCPC with (nolock) where PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
		if @@rowcount = 0
			begin
			---- Check partial phase in JC Phase Cost Types
			select Top 1 @um=UM, @billflag=BillFlag, @itemunitflag=ItemUnitFlag, @phaseunitflag=PhaseUnitFlag
			from JCPC with (nolock) where PhaseGroup=@phasegroup and Phase like @pphase and CostType=@costtype
			Group By PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
			if @@rowcount = 0
				begin
				-- -- -- #26895
				select @um='LS', @billflag='C', @itemunitflag='N', @phaseunitflag='N'
				end
			end
		end
	else
		begin
    	---- Check partial phase in JC Phase Cost Types
    	select Top 1 @um=UM, @billflag=BillFlag, @itemunitflag=ItemUnitFlag, @phaseunitflag=PhaseUnitFlag
		from JCPC with (nolock) where PhaseGroup=@phasegroup and Phase like @pphase and CostType=@costtype
		Group By PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
		if @@rowcount = 0
			begin
			-- -- -- #26895
			select @um='LS', @billflag='C', @itemunitflag='N', @phaseunitflag='N'
		end
	end

	if not exists(select top 1 1 from JCCH with (nolock) where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype)
		begin
		---- now insert into JCCH
		insert JCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag,
   					BuyOutYN, Plugged, ActiveYN, OrigHours, OrigUnits, OrigCost, SourceStatus)
		select @pmco, @project, @phasegroup, @phase, @costtype, @um, @billflag, isnull(@itemunitflag,'N'), 
   					isnull(@phaseunitflag,'N'), 'N', 'N', 'Y', 0, 0, 0, 'Y'

		select @jcch_count = @jcch_count + 1
		-- execute bspPMOrigSubOrMatlAdd to insert cost types in PMSL or PMMF as needed
		select @units = 0, @unitcost = 0, @amount = 0
		exec @retcode = bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @costtype, @units, @um,
   								@unitcost, @amount, @errmsg output
		end

	goto openPMTD_loop


openPMTD_end:
   	if @openPMTD = 1
   		begin
   		close PMTD_cursor
   		deallocate PMTD_cursor
   		select @openPMTD = 0
   		end

goto openPMTP_loop


openPMTP_end:
   	if @openPMTP = 1
   		begin
   		close PMTP_cursor
   		deallocate PMTP_cursor
   		select @openPMTP = 0
   		end



bspexit:
	if @opencontractitem = 1
		begin
		close contractitem_cursor
		deallocate contractitem_cursor
		select @opencontractitem = 0
		end
   
   	if @openPMTD = 1
   		begin
   		close PMTD_cursor
   		deallocate PMTD_cursor
   		select @openPMTD = 0
   		end
   
   	if @openPMTP = 1
   		begin
   		close PMTP_cursor
   		deallocate PMTP_cursor
   		select @openPMTP = 0
   		end
   
   	if @rcode <> 0 
   		select @msg = isnull(@msg,'')
   	else
   		select @msg = 'Number of records added to project. ' + char(13) + char(10) + 'Phases: ' + convert(varchar(8), @jcjp_count) + ' Cost Types: ' + convert(varchar(8), @jcch_count) + ' .'
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMTemplateCopy] TO [public]
GO
