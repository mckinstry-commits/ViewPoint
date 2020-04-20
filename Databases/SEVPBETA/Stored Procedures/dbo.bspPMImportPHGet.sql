SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMImportPHGet    Script Date: 8/28/99 9:35:13 AM ******/
CREATE  proc [dbo].[bspPMImportPHGet]
/****************************************************************************
 * CREATED BY:	GF  05/29/99
 * MODIFIED BY:	DANF 03/16/00 Changed valid part of phase validation
 *				GF 11/28/2008 - issue #131100 expanded phase description
 *				
 *
 * USAGE:
 * 	Gets valid Phase for import phase.
 *
 * INPUT PARAMETERS:
 *	Template, PhaseGroup, ImportPhase, PMCo, Override, StdTemplate
 *
 * OUTPUT PARAMETERS:
 *	Phase, Description
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@template varchar(10), @phasegroup bGroup, @importphase varchar(30), @pmco bCompany,
 @override bYN = 'N', @stdtemplate varchar(10) = '', @phase bPhase = '' output,
 @description bItemDesc = '' output)
as
set nocount on

declare @rcode int, @xreftype tinyint, @iphase bPhase, @vphase bPhase,
   		@validphasechars int, @inputmask varchar(30), @pdesc bItemDesc,
   		@itemformat varchar(10), @itemmask varchar(10), @itemlength varchar(10)

select @rcode = 0, @xreftype = 0

select @validphasechars=ValidPhaseChars from bJCCO where JCCo=@pmco

-- -- -- get input mask for bPhase
select @inputmask = InputMask, @itemlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bPhase'
if isnull(@inputmask,'') = '' select @inputmask = 'R'
if isnull(@itemlength,'') = '' select @itemlength = '20'
if @inputmask in ('R','L')
   	begin
   	select @inputmask = @itemlength + @inputmask + 'N'
   	end

exec @rcode = bspHQFormatMultiPart @importphase ,@inputmask, @iphase output


if @importphase is not null
	begin
	select @phase = isnull(Phase,'')
	from bPMUX with (nolock)
	where Template=@template and XrefType=@xreftype and XrefCode=@importphase and PhaseGroup=@phasegroup
	if @@rowcount = 0
		begin
		select @phase = isnull(Phase,'')
		from bPMUX with (nolock) where Template=@template and XrefType=@xreftype and XrefCode=@importphase -- -- -- and PhaseGroup=@phasegroup
		if @@rowcount = 0 and @override = 'Y'
			begin
			select @phase = isnull(Phase,'')
			from bPMUX with (nolock)
			where Template=@stdtemplate and XrefType=@xreftype and XrefCode=@importphase and PhaseGroup=@phasegroup
			if @@rowcount = 0
				begin
                select @phase = isnull(Phase,'')
                from bPMUX with (nolock)
				where Template=@stdtemplate and XrefType=@xreftype and XrefCode=@importphase -- -- -- and PhaseGroup=@phasegroup
                end
			end
		end
	end


if @phase is null or @phase=''
	begin
	select @phase = isnull(Phase,'')
	from bJCPM with (nolock) where PhaseGroup=@phasegroup and Phase=@iphase
	if @@rowcount = 0 and @validphasechars > 0
		begin
		select @vphase=substring(@iphase,1,@validphasechars) + '%'
        /*exec @rcode = bspHQFormatMultiPart @vphase,@inputmask,@vphase output*/
		select Top 1 @vphase = isnull(Phase,'')
		from bJCPM with (nolock) where PhaseGroup=@phasegroup and Phase like @vphase
		Group By PhaseGroup, Phase
		end
	end


if @phase is null or @phase=''
	begin
	select @phase=@iphase
	end


if @phase > ''
	begin
	select @pdesc = Description
	from bJCPM with (nolock) where PhaseGroup=@phasegroup and Phase=@phase
	if @@rowcount = 0 and @validphasechars > 0
		begin
		select @vphase=substring(@phase,1,@validphasechars) + '%'
          /*exec @rcode = bspHQFormatMultiPart @vphase,@inputmask,@vphase output*/
		select Top 1 @pdesc=Description
		from bJCPM where PhaseGroup=@phasegroup and Phase like @vphase
		Group By PhaseGroup, Phase, Description
		end
	end
else
	begin
	select @phase=Null, @description=Null, @pdesc=null
	end


if isnull(@description,'') = '' select @description=@pdesc




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMImportPHGet] TO [public]
GO
