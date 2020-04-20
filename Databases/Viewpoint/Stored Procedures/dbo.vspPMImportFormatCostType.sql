SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE  procedure [dbo].[vspPMImportFormatCostType]
/*******************************************************************************
* Created By:   GF 03/01/2000
* Modified By:  GF 02/14/2001
*				GF 01/08/2003 - changed item format to use the bContractItem input mask. Per Hazel conversion
*				GF 05/30/2006 - issue #19002 added code for 'timberline' to check for phase units and um.
*				GF 10/30/2008 - issue #130136 notes changed from varchar(8000) to varchar(max)
*				GP 03/25/2009 - issue 126939, modified procedure to format values, removed insert.
*				GP 06/30/2009 - issue 134186 made @costonly an output param.
*				GP 03/25/2009 - issue 133428, added insert for timberline, also new params @ImportRoutine & @CurrentKeyID.
*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
*				GF 01/20/2011 - issue #142984 added code to check for um DEFAULT.
*
*
* This SP will create import work detail records.
*
* It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
*
* Pass In
*   PMCo, ImportId, PhaseGroup, ImportItem, ImportPhase, ImportCostType,
*   ImportUM, BillFlag, ItemUnitFlag, PhaseUnitFlag, Hours, Units, Costs,
*   ImportMisc1, ImportMisc2, ImportMisc3
*
* RETURN PARAMS
*   msg           Error Message, or Success message
*
* Returns
*      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
*
********************************************************************************/
(@pmco bCompany, @importid varchar(10), @ImportRoutine varchar(20), @phasegroup bGroup, @importitem varchar(30),
 @importphase varchar(30), @importcosttype varchar(30), @importum varchar(30),
 @billflag char(1), @itemunitflag bYN, @phaseunitflag bYN, @importhours varchar(30),
 @importunits varchar(30), @importcosts varchar(30), @importmisc1 varchar(30) = null,
 @importmisc2 varchar(30) = null, @importmisc3 varchar(30) = null, @notes varchar(max),
 @item bContractItem = null output, @phase bPhase = null output, @costtype bJCCType = null output,
 @um bUM = null output, @units bUnits = null output, @costs bDollar = null output, @hours bHrs = null output,
 @billflag_out char(1) = null output, @itemunitflag_out bYN = null output, @phaseunitflag_out bYN = null output,
 @costonly bYN = null output, @CurrentKeyID bigint = null output, @msg varchar(255) output)
as
set nocount on
--#142350 - @importroutine
DECLARE @rcode int,
		@sequence int,
		@template varchar(10),
		@override bYN,
		@stdtemplate varchar(10), --@costonly bYN,
		@vimportum varchar(30),
		@vhours bHrs,
		@vunits bUnits,
		@vcosts bDollar,
		@vsequence int,
		@itemoption char(1),
		@contractitem bContractItem,
		@iamount bDollar,
		@pdesc bDesc,
		@itemlength varchar(10),
		@itemformat varchar(10),
		@itemmask varchar(10),
		@ditem varchar(16),
		@inputmask varchar(30),
		@ImpRoutine varchar(20),
		@phasemisc2 varchar(30),
		@phasemisc3 varchar(30),
		@usephaseum bYN

select @rcode=0

if @importid is null
	begin
	select @msg='Missing Import Id', @rcode=1
	goto bspexit
	end

------ get template from PMWH
select @template=Template from bPMWH with (nolock) where PMCo=@pmco and ImportId=@importid
if @@rowcount = 0
	begin
	select @msg='Invalid Import Id', @rcode = 1
	goto bspexit
	end

------ valid phase group
if @phasegroup is null
	begin
	select @msg = 'Missing Phase Group!', @rcode = 1
	goto bspexit
	end

------ get template data
select @ImpRoutine=ImportRoutine, @override=Override, @stdtemplate=StdTemplate,
	   @itemoption=ItemOption, @contractitem=ContractItem, @usephaseum=UsePhaseUM
from bPMUT with (nolock) where Template=@template

------ get input mask for bContractItem
select @inputmask = InputMask, @itemlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bContractItem'
if isnull(@inputmask,'') = '' select @inputmask = 'R'
if isnull(@itemlength,'') = '' select @itemlength = '16'
if @inputmask in ('R','L')
	begin
	select @inputmask = @itemlength + @inputmask + 'N'
	end

------ if timberline import routine look for import phase in PMWP
if @ImpRoutine = 'Timberline'
	begin
	if @usephaseum = 'Y'
		begin
		select @phasemisc2=ImportMisc2, @phasemisc3=ImportMisc3
		from bPMWP where PMCo=@pmco and ImportId=@importid and ImportPhase=@importphase
		if @@rowcount <> 0
			begin
			------ if cost type um is empty and phase um has value set to phase um
			if isnull(@importum,'') = '' and isnull(@phasemisc3,'') <> ''
				select @importum = @phasemisc3
			------ if cost type units is empty and phase units has value set to phase units
			if isnull(@importunits,'') = '' and isnull(@phasemisc2,'') <> ''
				select @importunits = @phasemisc2
			end
		end
	if isnull(@importum,'') = '' select @importum='LS'
	if isnull(@importunits,'') = '' select @importunits='0.0'
	end

------ set bPMWD parameters and insert record
select @units = 0, @costs = 0, @hours = 0
------ units
if IsNumeric(@importunits) = 1
	select @units = convert(decimal(12,3),@importunits)
------ costs
if IsNumeric(@importcosts) = 1
	select @costs = convert(decimal(12,2),@importcosts)
------ hours
if IsNumeric(@importhours) = 1
	select @hours = convert(decimal(10,2),@importhours)
------ bill flag
if isnull(@billflag,'') = '' select @billflag = 'C'
------ item unit flag
if isnull(@itemunitflag,'') = '' select @itemunitflag='N'
------ phase unit flag
if isnull(@phaseunitflag,'') = '' select @phaseunitflag='N'

------ get um xref if any
exec @rcode = dbo.bspPMImportUMGet @template,@importum,@pmco,@override,@stdtemplate,@um OUTPUT
---- #142984 check for a default value
exec dbo.vspPMImportDefaultValues @template, 'CostType', 'UM', @um, @um output, @msg output
	
------ get cost type xref if any
exec @rcode = dbo.bspPMImportCTGet @template,@phasegroup,@importcosttype,@pmco,@override,
     				@stdtemplate,@costtype output,@costonly output

------ get PMWI data
select @item = isnull(Item,Null)
from bPMWI with (nolock) where PMCo=@pmco and ImportId=@importid and ImportItem=@importitem
------ get PMWP data
select @phase = isnull(Phase,Null)
from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and ImportPhase=@importphase
------ get phase if missing
if isnull(@phase,'') = ''
	begin
	exec @rcode = dbo.bspPMImportPHGet @template, @phasegroup, @importphase, @pmco,
     				   @override, @stdtemplate, @phase output, @pdesc output
	end

------ check item option
if @itemoption='I'
	begin
	select @item=@contractitem, @importitem=@contractitem
	end

if @itemoption='C' or @itemoption='P'
	begin
	select @importitem=@importphase
	end

------ if not using item option and item is null try to set item
if @itemoption='N' and isnull(@item,'') = ''
	begin
	select @item=Item
	from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid
	and PhaseGroup=@phasegroup and Phase=@phase
	if isnull(@item,'') is null
		begin
		select @ditem = rtrim(ltrim(convert(varchar(16),@importitem)))
		exec dbo.bspHQFormatMultiPart @ditem, @inputmask, @item output
		end
	end

------ check cost type
if @costtype = 0
	begin
	select @costtype = null
	end
    
if @ImportRoutine = 'Timberline'
begin 
	------ roll-up cost types if needed
	if @costtype is not null
		begin
		select @vsequence=Sequence, @vhours=Hours, @vunits=Units, @vcosts=Costs, @vimportum=UM
		from bPMWD with (nolock) where PMCo=@pmco and ImportId=@importid and ImportItem=@importitem
		and ImportPhase=@importphase and CostType=@costtype
		if @@rowcount <> 0
			begin
			if @costonly = 'N'
				begin
				if @vimportum = @um
					begin
					select @vunits=@vunits+@units
					end
				select @vhours=@vhours+@hours, @vcosts=@vcosts+@costs
				end
			else
				begin
				select @vcosts=@vcosts+@costs
				end

			update bPMWD set Hours=@vhours, Units=@vunits, Costs=@vcosts
			where PMCo=@pmco and ImportId=@importid and Sequence=@vsequence
			goto bspexit
			end
		else
			goto pmwd_insert
		end
	else
		begin
		select @vsequence=Sequence, @vhours=Hours, @vunits=Units, @vcosts=Costs, @vimportum=UM
		from bPMWD with (nolock) where PMCo=@pmco and ImportId=@importid and ImportItem=@importitem
		and ImportPhase=@importphase and ImportCostType=@importcosttype
		if @@rowcount <> 0
			begin
			if @costonly = 'N'
				begin
				if @vimportum=@um
					begin
					select @vunits=@vunits+@units
					end
				select @vhours=@vhours+@hours, @vcosts=@vcosts+@costs
				end
			else
				begin
				select @vcosts=@vcosts+@costs
				end

			update bPMWD set Hours=@vhours, Units=@vunits, Costs=@vcosts
			where PMCo=@pmco and ImportId=@importid and Sequence=@vsequence
			goto bspexit
			end
		end


	pmwd_insert:
	select @sequence=1
	select @sequence=isnull(Max(Sequence),0)+1 from bPMWD where ImportId=@importid
	insert into bPMWD (ImportId,Sequence,Item,PhaseGroup,Phase,CostType,UM,BillFlag,ItemUnitFlag,
			PhaseUnitFlag,Hours,Units,Costs,ImportItem,ImportPhase,ImportCostType,ImportUM,
			ImportMisc1,ImportMisc2,ImportMisc3,Errors, Notes, PMCo)
	select @importid,@sequence,@item,@phasegroup,@phase,@costtype,@um,@billflag,@itemunitflag,
			@phaseunitflag,@hours,@units,@costs,@importitem,@importphase,@importcosttype,@importum,
			@importmisc1,@importmisc2,@importmisc3,Null, @notes, @pmco
	set @CurrentKeyID = ident_current('PMWD')	
end			

select @billflag_out=@billflag, @itemunitflag_out=@itemunitflag, @phaseunitflag_out=@phaseunitflag


bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'') 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportFormatCostType] TO [public]
GO
