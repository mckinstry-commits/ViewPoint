SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************/
CREATE  procedure [dbo].[bspPMWMTrans]
/*******************************************************************************
 * This SP will translate import work material records.
 * Modified By:	GF 05/05/2003 - issue #21054 - need to check for bidtek phase and cost type
 *						when checking to see if PMWD record needs to be created
 *				GF 07/14/2005 - issue #29290 - need to check for existance of PMWD record 
 *						for @phase and @costtype before adding.
 *				GF 10/22/2007 - issue #125900 when inserting PMWD row add costs also.
 *
 *
 *
 * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
 *
 * Pass In
 *    
 *   PMCo, ImportId, PhaseGroup, MatlGroup, VendorGroup		
 * 
 * RETURN PARAMS
 *   msg           Error Message, or Success message
 *
 * Returns
 *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
 *
 ********************************************************************************/
(@pmco bCompany, @importid varchar(10), @phasegroup bGroup, @matlgroup bGroup,
 @vendorgroup bGroup, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @sequence int, @template varchar(10), @dsequence int,
		@item bContractItem, @phase bPhase, @costtype bJCCType, @um bUM, @importitem varchar(30),
		@importphase varchar(30),@importcosttype varchar(30), @importum varchar(30),
		@importmisc1 varchar(30),@importmisc2 varchar(30), @importmisc3 varchar(30),
		@billflag char(1), @itemunitflag bYN, @phaseunitflag bYN, @hours bHrs, @units bUnits,
		@costs bDollar, @openPMWM tinyint

select @rcode = 0, @openPMWM = 0

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

if @matlgroup is null
	begin
	select @msg = 'Missing Material Group!', @rcode = 1
	goto bspexit
	end

if @vendorgroup is null
	begin
	select @msg = 'Missing Vendor Group!', @rcode = 1
	goto bspexit
	end


------ create cursor on PMWM to create PMWD records if not exist
declare bcPMWM cursor LOCAL FAST_FORWARD for select Sequence
from PMWM where PMCo=@pmco and ImportId=@importid

------ open cursor
open bcPMWM
select @openPMWM = 1

PMWM_loop:
fetch next from bcPMWM into @dsequence

if @@fetch_status = -1 goto PMWM_end
if @@fetch_status <> 0 goto PMWM_loop

---- get data
select @item=Item, @phase=Phase, @costtype=CostType, @um=UM, @importitem=ImportItem,
		@importphase=ImportPhase, @importcosttype=ImportCostType, @importum=ImportUM,
		@importmisc1=ImportMisc1, @importmisc2=ImportMisc2, @importmisc3=ImportMisc3
from PMWM with (nolock) where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
if @@rowcount = 0 goto PMWM_loop

---- see if import phase and cost type exists in PMWD
if @importphase is not null and @importcosttype is not null
	begin
	select @units=isnull(Sum(Units),0), @costs=isnull(Sum(Amount),0) ---- the costs piece was remmed out, why?
	from PMWM with (nolock) where PMCo=@pmco and ImportId=@importid
	and ImportPhase=@importphase and ImportCostType=@importcosttype and ImportUM=@importum
	and Phase=@phase and CostType=@costtype
    
	---- set values, insert into PMWD if not exists
	select @sequence=1, @hours=0, @billflag='C', @itemunitflag='N', @phaseunitflag='N'
	if not exists(select top 1 1 from PMWD with (nolock) where PMCo=@pmco and ImportId=@importid
						and Phase=@phase and CostType=@costtype)
		begin
		select @sequence=isnull(Max(Sequence),0)+1
		from PMWD with (nolock) where PMCo=@pmco and ImportId=@importid
		---- insert record
		insert into PMWD (ImportId,Sequence,Item,PhaseGroup,Phase,CostType,UM,BillFlag,ItemUnitFlag,
    					PhaseUnitFlag,Hours,Units,Costs,ImportItem,ImportPhase,ImportCostType,ImportUM,
    					ImportMisc1,ImportMisc2,ImportMisc3,Errors,PMCo)
		select @importid,@sequence,@item,@phasegroup,@phase,@costtype,@um,@billflag,
    					@itemunitflag,@phaseunitflag,@hours,@units,@costs,@importitem,@importphase, /*COSTS set to zero, why?*/
    					@importcosttype,@importum,@importmisc1,@importmisc2,@importmisc3,Null,@pmco
		end
	end


goto PMWM_loop




PMWM_end:
	if @openPMWM = 1
		begin
  		close bcPMWM
  		deallocate bcPMWM
  		set @openPMWM = 0
  		end


---- check if phase cost type record is missing in bPMWD
----select @dsequence = min(Sequence) from bPMWM with (nolock) where PMCo=@pmco and ImportId=@importid
----while @dsequence is not null
----begin
----    	select @item=Item, @phase=Phase, @costtype=CostType, @um=UM, @importitem=ImportItem,
----       	  	@importphase=ImportPhase, @importcosttype=ImportCostType, @importum=ImportUM,
----       	  	@importmisc1=ImportMisc1, @importmisc2=ImportMisc2, @importmisc3=ImportMisc3
----    	from bPMWM with (nolock) where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
----    	if @@rowcount = 0 goto pmwm_next_1
----    
----    	-- see if import phase and cost type exists in bPMWD
----        if @importphase is not null and @importcosttype is not null
----    		begin
----    		select @units=isnull(Sum(Units),0) -- -- -- , @costs=isnull(Sum(Amount),0)
----    		from bPMWM with (nolock) where PMCo=@pmco and ImportId=@importid and ImportPhase=@importphase
----    		and ImportCostType=@importcosttype and ImportUM=@importum and Phase=@phase and CostType=@costtype
----    
----    		select @sequence=1, @hours=0, @billflag='C', @itemunitflag='N', @phaseunitflag='N'
----    
----    		if not exists(select top 1 1 from bPMWD with (nolock) where PMCo=@pmco and ImportId=@importid and Phase=@phase and CostType=@costtype)
----    			begin
----    			select @sequence=isnull(Max(Sequence),0)+1 from bPMWD with (nolock) where ImportId=@importid
----    			insert into bPMWD (ImportId,Sequence,Item,PhaseGroup,Phase,CostType,UM,BillFlag,ItemUnitFlag,
----    					PhaseUnitFlag,Hours,Units,Costs,ImportItem,ImportPhase,ImportCostType,ImportUM,
----    					ImportMisc1,ImportMisc2,ImportMisc3,Errors,PMCo)
----    			select @importid,@sequence,@item,@phasegroup,@phase,@costtype,@um,@billflag,
----    					@itemunitflag,@phaseunitflag,@hours,@units,0/*@costs*/,@importitem,@importphase,
----    					@importcosttype,@importum,@importmisc1,@importmisc2,@importmisc3,Null,@pmco
----    			end
----             end
----    
----    
----pmwm_next_1:        
----select @dsequence = min(Sequence) from bPMWM with (nolock) where PMCo=@pmco and ImportId=@importid and Sequence>@dsequence
----if @@rowcount = 0 select @dsequence = null
----end



bspexit:
  	if @openPMWM = 1
  		begin
  		close bcPMWM
  		deallocate bcPMWM
  		set @openPMWM = 0
  		end
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWMTrans] TO [public]
GO
