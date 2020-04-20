SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMWSTrans    Script Date: 8/28/99 9:35:24 AM ******/
   CREATE   procedure [dbo].[bspPMWSTrans]
     /*******************************************************************************
     * Created By:
     * Modified By:	GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
     *				GF 04/12/2005 - #28390 - only insert PMWD records if item-phase-cost type record does not already exist.
     *								Possible roll-up problem when combining cost types.
     *				GF 08/24/2005 - check PMCO.SLCT1Option - if 2 with estimates, if 3 no estimates
     *				GF 08/24/2005 - issue #29394 need to check by phase and cost type when checking if exists in PMWD.
     *				GF 06/23/2010 - issue #140323 need to check to import cost type when cost type is null (not x-ref or alpha).
     *
     *
     *
     *
     * This SP will translate import work subcontract records.
     *
     * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
     *
     * Pass In
     *   PMCo, ImportId, PhaseGroup, VendorGroup		
     * 
     * RETURN PARAMS
     *   msg           Error Message, or Success message
     *
     * Returns
     *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
     *
     ********************************************************************************/
     (@pmco bCompany, @importid varchar(10), @phasegroup bGroup, @vendorgroup bGroup,
      @msg varchar(255) output)
     as
     set nocount on
     
     declare @rcode int, @sequence int, @template varchar(10), @dsequence int, @opencursor tinyint,
     		@item bContractItem, @phase bPhase, @costtype bJCCType, @um bUM, @importitem varchar(30),
     		@importphase varchar(30),@importcosttype varchar(30), @importum varchar(30),
     		@importmisc1 varchar(30),@importmisc2 varchar(30), @importmisc3 varchar(30),
     		@billflag char(1), @itemunitflag bYN, @phaseunitflag bYN, @hours bHrs, @units bUnits,
     		@costs bDollar, @slct1option tinyint
     
     select @rcode = 0, @opencursor = 0
   
     
     If @importid is null
        begin
        select @msg='Missing Import Id', @rcode=1
        goto bspexit
        end
      
     select @template=Template from bPMWH with (nolock) where PMCo=@pmco and ImportId=@importid
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
      
     if @vendorgroup is null
        begin
        select @msg = 'Missing Vendor Group!', @rcode = 1
        goto bspexit
        end
    
    -- -- -- get sl cost type option from PMCO
    select @slct1option=SLCT1Option
    from PMCO with (nolock) where PMCo=@pmco
    if @@rowcount = 0 select @slct1option = 2
    
     
     -- declare cursor to process phase cost type bPMWS rows
     declare bcPMWS cursor LOCAL FAST_FORWARD
     for select Sequence, Item, Phase, CostType, UM, ImportItem, ImportPhase, ImportCostType, ImportUM,
     		ImportMisc1, ImportMisc2, ImportMisc3
     from bPMWS where PMCo=@pmco and ImportId=@importid
     
     -- open cursor
     open bcPMWS
     set @opencursor = 1
     
     -- process entries
     PMWS_loop:
     fetch next from bcPMWS into @dsequence, @item, @phase, @costtype, @um, @importitem, @importphase, 
     		@importcosttype, @importum, @importmisc1, @importmisc2, @importmisc3
     
     if @@fetch_status = -1 goto PMWS_end
     if @@fetch_status <> 0 goto PMWS_loop
     
     
     if @importphase is not null and @importcosttype is not null
     	begin
     	-- -- -- if not exists(select top 1 1 from bPMWD where ImportId=@importid and ImportPhase=@importphase and ImportCostType=@importcosttype)
   -- -- -- 	if not exists(select top 1 1 from bPMWD with (nolock) where ImportId=@importid and Item=@item and Phase=@phase and CostType=@costtype)
   -- -- --   		begin
     		select @units=isnull(Sum(Units),0)
     		from bPMWS where PMCo=@pmco and ImportId=@importid and ImportPhase=@importphase 
     		and ImportCostType=@importcosttype and ImportUM=@importum and Phase=@phase and CostType=@costtype
              
     		select @costs=isnull(Sum(Amount),0)
     		from bPMWS where PMCo=@pmco and ImportId=@importid and ImportPhase=@importphase 
     		and ImportCostType=@importcosttype and Phase=@phase and CostType=@costtype
    
    		if @slct1option = 3
    			begin
    			select @units = 0, @costs = 0
    			end
     
     		select @sequence=1, @hours=0, @billflag='C', @itemunitflag='N', @phaseunitflag='N'
     
     		select @sequence=isnull(Max(Sequence),0)+1 from bPMWD where PMCo=@pmco and ImportId=@importid
    
			----if cost type null compare to import cost type #140323
    		if not exists(select top 1 1 from bPMWD where PMCo=@pmco and ImportId=@importid and isnull(Item,ImportItem)=isnull(@item,@importitem)
    					and Phase=@phase and (CostType=@costtype or ImportCostType=@importcosttype))
    			begin
    	 		insert into bPMWD (ImportId,Sequence,Item,PhaseGroup,Phase,CostType,UM,BillFlag,ItemUnitFlag,
    						PhaseUnitFlag,Hours,Units,Costs,ImportItem,ImportPhase,ImportCostType,ImportUM,
    						ImportMisc1,ImportMisc2,ImportMisc3,Errors,PMCo)
    	 		select @importid,@sequence,@item,@phasegroup,@phase,@costtype,@um,@billflag,@itemunitflag,
    						@phaseunitflag,@hours,@units,@costs,@importitem,@importphase,@importcosttype,@importum,
    						@importmisc1,@importmisc2,@importmisc3,Null,@pmco
    			end
     		-- -- -- end
     	end
    
    goto PMWS_loop
    
    
    PMWS_end:
     if @opencursor = 1
     	begin
     	close bcPMWS
     	deallocate bcPMWS
     	set @opencursor = 0
     	end
     
     
     
     
    bspexit:
    	if @opencursor = 1
     		begin
     		close bcPMWS
     		deallocate bcPMWS
     		set @opencursor = 0
     		end
    
    	if @rcode <> 0 select @msg = isnull(@msg,'')
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWSTrans] TO [public]
GO
