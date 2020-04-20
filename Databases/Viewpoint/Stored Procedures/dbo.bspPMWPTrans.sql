SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMWPTrans    Script Date: 8/28/99 9:35:23 AM ******/
   CREATE procedure [dbo].[bspPMWPTrans]
    /*******************************************************************************
    * Created:  06/01/99  GF
    * Modified: 09/17/99  GF
    *			 GF 01/08/2003 - changed item format to use the bContractItem input mask. Per Hazel conversion
    *
    * This SP will translate import work phase records.
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
   
     (@pmco bCompany, @importid varchar(10), @phasegroup bGroup, @defaultretpct bPct, @msg varchar(255) output)
   
as
set nocount on

declare @rcode int, @sequence int, @template varchar(10), @dsequence int, @isequence int,
		@importphase varchar(30), @phase bPhase, @importitem varchar(30), @item bContractItem,
		@description bDesc, @importum varchar(30), @validphasechars int, @itemoption char(1),
		@begposition tinyint, @endposition tinyint, @itemformat varchar(10), @itemmask varchar(10),
		@itemlength varchar(10), @phaselength int, @vitem bContractItem,
		@override bYN, @importsicode bYN, @usesicodedesc bYN, @sidesc bDesc,
		@inputmask varchar(30), @lastpartphase varchar(1)
   
     select @rcode=0
   
     if @defaultretpct is null
        begin
        select @defaultretpct=0
        end
   
     If @importid is null
       begin
       select @msg='Missing Import Id', @rcode=1
       goto bspexit
       end
   
     select @template=Template from bPMWH where  PMCo=@pmco and ImportId=@importid
   
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
   
   -- get input mask for bContractItem
   select @inputmask = InputMask, @itemlength = convert(varchar(10), InputLength)
   from DDDTShared with (nolock) where Datatype = 'bContractItem'
   if isnull(@inputmask,'') = '' select @inputmask = 'R'
   if isnull(@itemlength,'') = '' select @itemlength = '16'
   if @inputmask in ('R','L')
   	begin
   	select @inputmask = @itemlength + @inputmask + 'N'
   	end
   
   
     select @phaselength = Convert(int,InputLength) from DDDTShared where Datatype='bPhase'
     if @phaselength is null or @phaselength=0
        select @phaselength=20
   
     -- get valid portion of phase
     select @validphasechars = ValidPhaseChars from bJCCO where JCCo = @pmco
     if @@rowcount = 0
        begin
        select @validphasechars = 0
        end
   
select @override=Override, @itemoption=ItemOption, @importsicode=ImportSICode,
		@begposition=BegPosition, @endposition=EndPosition, @usesicodedesc=UseSICodeDesc,
		@lastpartphase=LastPartPhase
from bPMUT where Template=@template
   
     if @begposition=0
        begin
        select @begposition=1
        end
   
     if @itemoption='P'
        begin
        if @endposition<1 or @endposition>@phaselength
           begin
           select @endposition=@phaselength
           end
        end
   
     if @itemoption='C'
        begin
        if @endposition<1 or @endposition>convert(int,@itemlength)
           begin
           select @endposition=convert(int,@itemlength)
           end
        end
   
     CreateItems: -- create items for phases in bPMWP
     select @dsequence = min(Sequence) from bPMWP where PMCo=@pmco and ImportId=@importid
     while @dsequence is not null
     begin
   
       select @item=Item, @phase=Phase, @description=Description,
              @importitem=ImportItem, @importphase=ImportPhase
       from bPMWP where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence and PhaseGroup=@phasegroup
       if @@rowcount = 0 or isnull(@item,'') <> '' goto pmwp_next_2
   
       if @importitem is null or @importitem=''
          begin
          select @importitem=@importphase
          end
   
   
       if @importitem is null or @importitem=''
          begin
   
          goto pmwp_next_2
          end

		if @lastpartphase = 'S' and isnull(@item,'') = '' and isnull(@importitem,'') <> ''
			begin
			select @vitem = rtrim(ltrim(@importitem))
			exec @rcode = dbo.bspHQFormatMultiPart @vitem, @inputmask, @item output
			update bPMWP set Item=@item
            where ImportId=@importid and Sequence=@dsequence
			end

       if @itemoption='C'
          begin
          select @vitem=''
          select @vitem=substring(@importitem,@begposition,@endposition)
     if @vitem<=''
             begin
             goto pmwp_next_2
             end
   
             select @vitem=rtrim(ltrim(@vitem))
             select @importitem=@vitem
   		  exec @rcode = dbo.bspHQFormatMultiPart @vitem, @inputmask, @item output
             --exec bspHQFormatMultiPart @vitem,@itemformat,@item output
             update bPMWP set Item=@item, ImportItem=@importitem
             where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
   
             update bPMWD set Item=@item, ImportItem=@importitem
             where PMCo=@pmco and ImportId=@importid and ImportPhase=@importphase
   
             update bPMWS set Item=@item, ImportItem=@importitem
             where PMCo=@pmco and ImportId=@importid and ImportPhase=@importphase
   
             update bPMWM set Item=@item, ImportItem=@importitem
             where PMCo=@pmco and ImportId=@importid and ImportPhase=@importphase
   
             if @usesicodedesc = 'Y'
                   begin
                   -- look for match using @item only
                   select @sidesc = isnull(Description,@description)
                   from bJCSI where ltrim(rtrim(SICode)) = ltrim(rtrim(@item))
                   if @@rowcount <> 0 select @description=@sidesc
                   end
   
             select @isequence from bPMWI where PMCo=@pmco and ImportId=@importid and Item=@item
             if @@rowcount <> 0 goto pmwp_next_2
   
             select @sequence=1
             select @sequence=isnull(Max(Sequence),0)+1 from bPMWI where PMCo=@pmco and ImportId=@importid
   			 insert into bPMWI (ImportId,Sequence,Item,SIRegion,SICode,Description,UM,RetainPCT,
   					Amount,Units,UnitCost,ImportItem,ImportUM,ImportMisc1,ImportMisc2,ImportMisc3,Errors,PMCo)
   
             select @importid,@sequence,@item,Null,Null,@description,'LS',@defaultretpct,0,0,0,
             		     @importitem,'LS',Null,Null,Null,Null,@pmco
   
             goto pmwp_next_2
          end
   
       if @itemoption = 'P'
          begin
            if @phase>''
               begin
               select @vitem=''
               select @vitem=substring(@phase,@begposition,@endposition)
               if @vitem<=''
                  begin
   
                  goto pmwp_next_2
                  end
   
               select @vitem=rtrim(ltrim(@vitem))
               select @importitem=@vitem
   			exec @rcode = dbo.bspHQFormatMultiPart @vitem, @inputmask, @item output
               --exec bspHQFormatMultiPart @vitem, @itemformat, @item output
   
               update bPMWP set Item=@item, ImportItem=@importitem
               where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
   
               update bPMWD set Item=@item, ImportItem=@importitem
               where PMCo=@pmco and ImportId=@importid and ImportPhase=@importphase
   
               update bPMWS set Item=@item, ImportItem=@importitem
               where PMCo=@pmco and ImportId=@importid and ImportPhase=@importphase
   
               update bPMWM set Item=@item, ImportItem=@importitem
               where PMCo=@pmco and ImportId=@importid and ImportPhase=@importphase
   
               if @usesicodedesc = 'Y'
                   begin
                   -- look for match using @item only
                   select @sidesc = isnull(Description,@description)
                   from bJCSI where ltrim(rtrim(SICode)) = ltrim(rtrim(@item))
                   if @@rowcount <> 0 select @description=@sidesc
                   end
   
               select @isequence from bPMWI where PMCo=@pmco and ImportId=@importid and Item=@item
               if @@rowcount <> 0 goto pmwp_next_2
   
               select @sequence=1
               select @sequence=isnull(Max(Sequence),0)+1 from bPMWI where PMCo=@pmco and ImportId=@importid
   		  	   insert into bPMWI (ImportId,Sequence,Item,SIRegion,SICode,Description,UM,RetainPCT,
   					Amount,Units,UnitCost,ImportItem,ImportUM,ImportMisc1,ImportMisc2,ImportMisc3,Errors,PMCo)
   
   
               select @importid,@sequence,@item,Null,Null,@description,'LS',@defaultretpct,0,0,0, @importitem,'LS',Null,Null,Null,Null, @pmco
   
               goto pmwp_next_2
   
               end
          end
   
   
     pmwp_next_2:
   
     select @dsequence = min(Sequence) from bPMWP where PMCo=@pmco and ImportId=@importid and Sequence>@dsequence
     end
   
   
   
   
   bspexit:
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWPTrans] TO [public]
GO
