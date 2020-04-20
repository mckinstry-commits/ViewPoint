SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMWITrans    Script Date: 8/28/99 9:35:22 AM ******/
   CREATE  procedure [dbo].[bspPMWITrans]
     /*******************************************************************************
     * Created:  06/15/99  GF
     * Modified: 09/17/99  GF
     *           GF 06/02/2001 - use description from standard item code table if PMUT.UseSICodeDesc = 'Y'
     *			  GF 01/08/2003 - changed item format to use the bContractItem input mask. Per Hazel conversion
     *			  GF 12/12/2003 - #23212 - check error messages, wrap concatenated values with isnull
     *			  GF 01/22/2004 - #      - changed logic for AccumCosts flag, now updates when amount is zero only.
     *
     *
     * This SP will translate import work item records.
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
    
      (@pmco bCompany, @importid varchar(10), @phasegroup bGroup, @msg varchar(255) output)
    
      as
      set nocount on
    
      declare @rcode int, @sequence int, @template varchar(10), @dsequence int, @isequence int,
      	 @importitem varchar(30), @item bContractItem, @importum varchar(30), @amount bDollar,
      	 @units bUnits, @unitcost bUnitCost, @iamount bDollar, @iunits bUnits, @iimportum varchar(30),
      	 @itemoption char(1), @accumcosts bYN, @itemformat varchar(10), @itemmask varchar(10),
      	 @itemlength varchar(10), @begposition tinyint, @endposition tinyint,
      	 @phaselength int, @pitem bContractItem, @vcosts bDollar, @usesicodedesc bYN, @sidesc bDesc,
   	 @inputmask varchar(30), @opencursor tinyint
    
      select @rcode=0, @opencursor = 0
    
      If @importid is null
        begin
        select @msg='Missing Import Id', @rcode=1
        goto bspexit
        end
    
      select @template=Template from bPMWH where PMCo=@pmco and ImportId=@importid
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
   
   -- get the mask for bContractItem
   select @inputmask=InputMask from DDDTShared with (nolock) where Datatype = 'bContractItem'
   
    
      select @itemoption=ItemOption, @accumcosts=AccumCosts, @usesicodedesc=UseSICodeDesc
      from bPMUT where Template=@template
    
      ---- check for duplicate items in bPMWI
      select @dsequence = min(Sequence) from bPMWI where PMCo=@pmco and ImportId=@importid
      while @dsequence is not null
      begin
    
        select @item=Item,@amount=Amount,@units=Units,@unitcost=UnitCost,@importitem=ImportItem,@importum=ImportUM
        from bPMWI where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
        if @@rowcount = 0 goto pmwi_next_1
    
        select @isequence=Sequence, @iamount=Amount, @iunits=Units, @iimportum=ImportUM
        from bPMWI where PMCo=@pmco and ImportId=@importid and Item=@item and ImportItem=@importitem and Sequence<>@dsequence
        if @@rowcount = 0 goto pmwi_next_1
    
        select @amount=@amount+@iamount
        if @iimportum=@importum
           begin
           select @units=@units+@iunits
           if @units<>0
              begin
              select @unitcost=(@amount/@units)
              end
           end
    
        update bPMWI set Amount=@amount,Units=@units,UnitCost=@unitcost
              where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
    
        delete from bPMWI where PMCo=@pmco and ImportId=@importid and Sequence=@isequence
    
      pmwi_next_1:
    
      select @dsequence = min(Sequence) from bPMWI where PMCo=@pmco and ImportId=@importid and Sequence>@dsequence
      end
   
   
   if @accumcosts = 'N' goto bspexit
   
   -- accumulate costs
   declare bcPMWI cursor LOCAL FAST_FORWARD
   for select ImportItem, Sequence
   from bPMWI where PMCo=@pmco and ImportId=@importid and isnull(Amount,0) = 0
   
   open bcPMWI
   set @opencursor = 1
   
   
   PMWI_loop:
   fetch next from bcPMWI into @importitem, @dsequence
   
   if @@fetch_status <> 0 goto PMWI_end
   
   set @amount=0
   select @amount=isnull(Sum(Costs),0)
   from bPMWD where PMCo=@pmco and ImportId=@importid and ImportItem=@importitem
   if @@rowcount = 0 goto PMWI_loop
   
   -- update bPMWI with phase amounts
   update bPMWI set Amount=@amount
   where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
   
   goto PMWI_loop
   
   
   PMWI_end:
   	close bcPMWI
   	deallocate bcPMWI
   	set @opencursor = 0
   
   
    
   
   
   
   
   bspexit:
   	if @opencursor = 1
   		begin
   		close bcPMWI
   		deallocate bcPMWI
   		set @opencursor = 0
   		end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWITrans] TO [public]
GO
