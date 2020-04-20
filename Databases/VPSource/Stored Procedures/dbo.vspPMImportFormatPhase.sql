SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPMWPAdd    Script Date: 8/28/99 9:36:27 AM ******/
CREATE   procedure [dbo].[vspPMImportFormatPhase]
/*******************************************************************************
 * This SP will creat import work phase records.
 * Modified By:	GF 11/30/99
 *				GF 11/12/2007 - issue #126137 use JCPM description when PMUT option is flagged.
*				GF 10/30/2008 - issue #130136 notes changed from varchar(8000) to varchar(max)
*				GF 11/28/2008 - issue #131100 expanded phase description
 *				GP 03/25/2009 - issue 126939, modified procedure to format values, removed insert.
 *				GP 03/25/2009 - issue 133428, added insert for timberline, also new params @ImportRoutine & @CurrentKeyID.
 *				GP 07/16/2009 - issue 134808, fixed phase description method.
 *				GF 01/08/2011 - TK-11535 trim trailing spaces
 *
 *
 *
 * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
 *
 * Pass In
 *   PMCo, ImportId, PhaseGroup, ImportItem, ImportPhase, Description,
 *   Misc1, Misc2, Misc3
 *
 * RETURN PARAMS
 *   msg           Error Message, or Success message
 *
 * Returns
 *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
 *
 ********************************************************************************/
(@pmco bCompany, @importid varchar(10), @ImportRoutine varchar(20), @phasegroup bGroup, @importitem varchar(30),
 @importphase varchar(30), @description bItemDesc, @importmisc1 varchar(30) = null,
 @importmisc2 varchar(30) = null, @importmisc3 varchar(30) = null, @notes varchar(max), 
 @phase bPhase = null output, @item bContractItem = null output, @desc_out bItemDesc = null output,
 @CurrentKeyID bigint = null output, @msg varchar(255) output)
as
set nocount on
					
declare @rcode int, @sequence int, @itemoption char(1), @template varchar(10), @override bYN,
   		@stdtemplate varchar(10), @vdescription bItemDesc, @vsequence int, @contractitem bContractItem,
   		@estimatecode varchar(30), @usephasedesc bYN,
   		@validphasechars int, @pdesc bItemDesc, @vphase bPhase

select @rcode = 0

select @validphasechars=ValidPhaseChars from bJCCO where JCCo=@pmco

If @importid is null
      begin
      select @msg='Missing Import Id', @rcode=1
      goto bspexit
      end

select @template=Template, @estimatecode=EstimateCode
from bPMWH where PMCo=@pmco and ImportId=@importid
if @@rowcount = 0
      begin
      select @msg='Invalid Import Id', @rcode = 1
      goto bspexit
      end

if @phasegroup is null
      begin
      select @msg = 'Missing Phase Group!', @rcode = 1
      goto bspexit
      end

----TK-11535
SET @importitem = RTRIM(@importitem)
SET @importphase = RTRIM(@importphase)
SET @description = RTRIM(@description)
SET @importmisc1 = RTRIM(@importmisc1)
SET @importmisc2 = RTRIM(@importmisc2)
SET @importmisc3 = RTRIM(@importmisc3)
SET @notes= RTRIM(@notes)


---- PM import master information
select @override=Override, @stdtemplate=StdTemplate, @itemoption=ItemOption,
		@contractitem=ContractItem, @usephasedesc=UsePhaseDesc
from bPMUT where Template=@template

select @item = isnull(Item,Null)
from bPMWI where PMCo=@pmco and ImportId=@importid and ImportItem=@importitem

exec @rcode = dbo.bspPMImportPHGet @template,@phasegroup,@importphase,@pmco,
    				@override, @stdtemplate, @phase output, @description output


if @itemoption='I' and isnull(@contractitem,'') <> ''
   	begin
	select @item=@contractitem, @importitem=@contractitem
   	end

if @itemoption='C' or @itemoption='P'
	begin
	select @importitem=@importphase
	end

if @usephasedesc = 'Y'
	begin
	select @pdesc = Description
	from bJCPM with (nolock) where PhaseGroup=@phasegroup and Phase=@phase
	if @@rowcount = 0 and @validphasechars > 0
		begin
		select @vphase=substring(@phase,1,@validphasechars) + '%'
		select Top 1 @pdesc=Description
		from bJCPM where PhaseGroup=@phasegroup and Phase like @vphase
		Group By PhaseGroup, Phase, Description
		end
	if isnull(@pdesc,'') <> ''
		begin
		update bPMWP set Description=@pdesc
		where PMCo=@pmco and ImportId=@importid and ImportPhase=@importphase
		end
	end

---- check if phase in PMWP for item
if @phase > ''
	begin
	select @vsequence=Sequence, @vdescription=Description from bPMWP
	where PMCo=@pmco and ImportId=@importid and ImportItem=@importitem and Phase=@phase
	if @@rowcount <> 0
		begin
		if @usephasedesc = 'N'
			begin
			if @vdescription is null and @description is not null
				begin
				update bPMWP set Description=@description
				where PMCo=@pmco and ImportId=@importid and Sequence=@vsequence
				end
			goto bspexit
			end
		else
			begin
			if isnull(@vdescription,'') <> ''
				begin
				update bPMWP set Description=@vdescription
				where PMCo=@pmco and ImportId=@importid and Sequence=@vsequence
				end
			goto bspexit
			end
		end
	end
else
	begin
	select @vsequence=Sequence, @vdescription=Description from bPMWP
	where PMCo=@pmco and ImportId=@importid and ImportItem=@importitem and ImportPhase=@importphase
	if @@rowcount <> 0
		begin
		if @usephasedesc = 'N'
			begin
			if @vdescription is null and @description is not null
				begin
				update bPMWP set Description=@description
				where PMCo=@pmco and ImportId=@importid and Sequence=@vsequence
				end
			goto bspexit
			end
		else
			begin
			if isnull(@description,'') <> ''
				begin
				update bPMWP set Description='Missing phase' + isnull(@description,'')
				where PMCo=@pmco and ImportId=@importid and Sequence=@vsequence
				end
			goto bspexit
			end
		end
	end

---- insert bPMWP if Timberline
if @ImportRoutine = 'Timberline'
begin
	select @sequence=1
	select @sequence=isnull(Max(Sequence),0)+1 from bPMWP where ImportId=@importid
	insert into bPMWP (ImportId,Sequence,Item,PhaseGroup,Phase,Description,ImportItem,ImportPhase,
		ImportMisc1,ImportMisc2,ImportMisc3,Errors, Notes,PMCo)
		----TK-11535
	select @importid,@sequence,@item,@phasegroup,RTRIM(@phase),@description,@importitem,@importphase,
		@importmisc1,@importmisc2,@importmisc3,Null, @notes, @pmco
	set @CurrentKeyID = ident_current('PMWP')	
	if @@rowcount <> 0 and @usephasedesc = 'Y'
	begin
		---- update phase description if needed
		select @pdesc = Description
		from bJCPM with (nolock) where PhaseGroup=@phasegroup and Phase=@phase
		if @@rowcount = 0 and @validphasechars > 0
		begin
			select @vphase=substring(@phase,1,@validphasechars) + '%'
			select Top 1 @pdesc=Description
			from bJCPM where PhaseGroup=@phasegroup and Phase like @vphase
			Group By PhaseGroup, Phase, Description
		end
		if isnull(@pdesc,'') <> ''
		begin
			update bPMWP set Description=@pdesc
			where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
		end
	end	
end


bspexit:
	set @desc_out = coalesce(@pdesc, @vdescription, @description)
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportFormatPhase] TO [public]
GO
