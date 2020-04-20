SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************/
CREATE procedure [dbo].[bspPMWDTrans]
/*******************************************************************************
 * Created By:  GF 02/01/1999
 * Modified By: GF 07/18/2001 - Changed for multiple SL cost types from PMCo
 *		        GF 09/01/2001 - Changed to ignore Bill Flags if imported.
 *				GF 05/20/2002 - Added pseudo cursor for creating multiple cost types. #17391
 *				GF 08/24/2005 - issue #29400 remmed out create and subcontract cost type create moved to
 *								bspPMLastPartPhase to be done as the last piece before import complete.
 *				GF 11/28/2008 - issue #131100 expanded phase description
 *				GF 09/29/2009 - issue #135402 added code to check PMUD setup for BillFlag, ItemUnitFlag, PhaseUnitFlag
 *				GF 01/08/2011 - TK-11535 trim trailing spaces
 *
 *
 * This SP will translate import work detail records.
 *
 * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
 *
 * Pass In
 *   PMCo, ImportId, PhaseGroup
 *
 * RETURN PARAMS
 *   msg           Error Message, or Success message
 *
 * Returns
 *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
 *
 ********************************************************************************/
(@pmco bCompany, @importid varchar(10), @phasegroup bGroup, @wcretgpct bPct,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @sequence int, @template varchar(10), @override bYN, @stdtemplate varchar(10),
		@dsequence int, @importphase varchar(30), @phase bPhase, @importitem varchar(30),
		@item bContractItem, @description bItemDesc, @costtype bJCCType, @billflag char(1),
		@itemunitflag bYN, @phaseunitflag bYN, @validphasechars int, @vphase bPhase,
		@inputmask varchar(30), @useitemqtyum bYN, @validcnt INT, @viewpointdefault CHAR(1),
		@pmud_override CHAR(1)

select @rcode=0

If @importid is null
	begin
	select @msg = 'Missing Import Id', @rcode=1
	goto bspexit
	end

select @template=Template from bPMWH with (nolock) where PMCo=@pmco and ImportId=@importid

if @@rowcount = 0
	begin
	select @msg = 'Invalid Import Id', @rcode = 1
	goto bspexit
	end

if @phasegroup is null
	begin
	select @msg = 'Missing Phase Group!', @rcode = 1
	goto bspexit
	end

------      -- get vendor group
------      select @vendorgroup=VendorGroup from bHQCO with (nolock) where HQCo=@pmco
------      if @@rowcount = 0
------         begin
------         select @msg='Missing Vendor Group!', @rcode=1
------         goto bspexit
------         end


------get template information
select @override=Override, @stdtemplate=StdTemplate, @useitemqtyum=UseItemQtyUM
from bPMUT with (nolock) where Template=@template

------ get valid portion of phase
select @validphasechars = ValidPhaseChars from bJCCO with (nolock) where JCCo = @pmco
if @@rowcount = 0 select @validphasechars = 0

------    -- get Subcontract Cost Type from PM Company
------    select @slcosttype=SLCostType, @slcosttype2=SLCostType2
------    from bPMCO with (nolock) where PMCo=@pmco
------    if @@rowcount = 0 select @createsubrecs = 'N'
    
------ if phase missing in bPMWP then insert from bPMWD
select @dsequence = min(Sequence) from bPMWD with (nolock) where PMCo=@pmco and ImportId=@importid
while @dsequence is not null
begin
	select @item=Item, @phase=Phase, @costtype=CostType, @importitem=ImportItem, @importphase=ImportPhase
	from bPMWD where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence ------and PhaseGroup=@phasegroup
	if @@rowcount = 0 goto pmwd_next_1
    
	if @importphase is not null
           ------ begin
           ------ if not exists(select top 1 1 from bPMWP with (nolock) where ImportId=@importid and ImportPhase=@importphase)
		begin
		select @description=Null
		if @phase is null
			begin
			exec @rcode = dbo.bspPMImportPHGet @template, @phasegroup, @importphase, @pmco, @override, @stdtemplate, @phase output, @description output
			end

		if @phase is not null
			begin
			select @description=Description from bJCPM with (nolock) where PhaseGroup=@phasegroup and Phase=@phase
			if @@rowcount = 0 select @description=Description from bJCPM with (nolock) where Phase=@phase
			end
		else
			begin
			select @description=Null
			end
    
		if @phase is null
			begin
   			select @sequence=1
   			select @sequence=isnull(Max(Sequence),0)+1 from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid
   			insert into bPMWP (ImportId,Sequence,Item,PhaseGroup,Phase,Description,ImportItem,
    					ImportPhase,ImportMisc1,ImportMisc2,ImportMisc3,Errors, PMCo)
    					----TK-11535
   			select @importid,@sequence,@item,@phasegroup,RTRIM(@phase),@description,@importitem,
   						@importphase,Null,Null,Null,Null,@pmco
   			end
   		else
   			begin
   			if not exists(select top 1 1 from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and Phase=@phase)
   				begin
   				select @sequence=1
   				select @sequence=isnull(Max(Sequence),0)+1 from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid
   				insert into bPMWP (ImportId,Sequence,Item,PhaseGroup,Phase,Description,ImportItem,
   	 					ImportPhase,ImportMisc1,ImportMisc2,ImportMisc3,Errors,PMCo)
   	 					----TK-11535
   				select @importid,@sequence,@item,@phasegroup,RTRIM(@phase),@description,@importitem,
   						@importphase,Null,Null,Null,Null,@pmco
   				end
   			end
		end

	------ set cost type units and UM to item units and UM if UseItemQtyUM flag is 'Y'
	if @useitemqtyum = 'Y'
		begin
		Update bPMWD set Units=i.Units, UM=i.UM
		from bPMWD d join bPMWI i with (nolock) on i.ImportId=d.ImportId and i.ImportItem=d.ImportItem
		where d.PMCo=@pmco and d.ImportId=@importid and d.Sequence=@dsequence
		end



	---- skip if using flags from import file
	if exists(select ImportMisc3 from bPMWD with (nolock) where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence and ImportMisc3='KeepFlags')
			goto pmwd_next_1
	
	---- get BillFlag, ItemUnitFlag, PhaseUnitFlag
	select @billflag=BillFlag, @itemunitflag=ItemUnitFlag, @phaseunitflag=PhaseUnitFlag
	from bJCPC with (nolock) where PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
	if @@rowcount = 0
		begin
		------ Check valid portion
		if @validphasechars > 0
			begin
			------ get the mask for bPhase
			select @inputmask = InputMask from DDDTShared with (nolock) where Datatype = 'bPhase'
			-- format valid portion of phase
			select @vphase = substring(@phase,1,@validphasechars) + '%'
			/*exec @rcode = bspHQFormatMultiPart @vphase,@inputmask,@vphase output
			if @rcode <> 0 goto pmwd_next_1*/
			------ Check partial phase in JCPC
			select Top 1 @billflag=BillFlag, @itemunitflag=ItemUnitFlag, @phaseunitflag=PhaseUnitFlag
			from bJCPC with (nolock) where PhaseGroup = @phasegroup and Phase like @vphase and CostType = @costtype
			Group By PhaseGroup, Phase, CostType, BillFlag, ItemUnitFlag, PhaseUnitFlag
			if @@rowcount = 0 goto pmwd_next_1
			end
		end
	
	--update bPMWD set BillFlag=@billflag, ItemUnitFlag=@itemunitflag, PhaseUnitFlag=@phaseunitflag
	--where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
	
	
	---- new code below 
	---- check if we need to get default bill flag
	SELECT @viewpointdefault=ViewpointDefault, @pmud_override=OverrideYN
	FROM dbo.bPMUD WITH (NOLOCK) WHERE Template=@template AND RecordType='CostType' AND ColumnName='BillFlag'
	IF @@rowcount = 0 SET @viewpointdefault = 'Y'
	IF @viewpointdefault = 'Y' AND @pmud_override = 'N'
		BEGIN
		update bPMWD set BillFlag=@billflag
		where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
		END
	---- check if we need to get default item unit flag
	SELECT @viewpointdefault=ViewpointDefault, @pmud_override=OverrideYN
	FROM dbo.bPMUD WITH (NOLOCK) WHERE Template=@template AND RecordType='CostType' AND ColumnName='ItemUnitFlag'
	IF @@rowcount = 0 SET @viewpointdefault = 'Y'
	IF @viewpointdefault = 'Y' AND @pmud_override = 'N'
		BEGIN
		update bPMWD set ItemUnitFlag=@itemunitflag
		where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
		END
	---- check if we need to get default phase unit flag
	SELECT @viewpointdefault=ViewpointDefault, @pmud_override=OverrideYN
	FROM dbo.bPMUD WITH (NOLOCK) WHERE Template=@template AND RecordType='CostType' AND ColumnName='PhaseUnitFlag'
	IF @@rowcount = 0 SET @viewpointdefault = 'Y'
	IF @viewpointdefault = 'Y' AND @pmud_override = 'N'
		BEGIN
		update bPMWD set PhaseUnitFlag=@phaseunitflag
		where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
		END





pmwd_next_1:
select @dsequence = min(Sequence) from bPMWD with (nolock) where PMCo=@pmco and ImportId=@importid and Sequence>@dsequence
end








bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWDTrans] TO [public]
GO
