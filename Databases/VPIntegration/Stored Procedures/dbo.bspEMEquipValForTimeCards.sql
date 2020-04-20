SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspEMEquipValForTimeCards]
   
   /***********************************************************
    * CREATED BY: JM 7/24/02 - Adapted from bspEMEquipValNoComponent tp return FuelCostCode
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls
	*				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)	
    *
    * USAGE:
    *	Validates EMEM.Equipment.
    *	Returns following:
    *		Shop
    *		Warranty Status ('A' if active warranties exist
    *			or 'I' if not)
    *		Inventory Location for parts
    *		Equipment Type ('E' or 'C')
    *		Whether costs are posted to components
   *		FuelCostCode	
    *
    * INPUT PARAMETERS
    *	@emco		EM Company
    *	@equip		Equipment to be validated
    *
    * OUTPUT PARAMETERS
    *	@shop 		bEMEM.Shop
    *	@warrantystatus Active (A) or Inactive (I)
    *	@invloc		bEMSX.InvLoc by bEMEM.Shop
    *	@equiptype	bEMEM.Type ('E' for Equipment or 'C' for Component)
    *	@postcosttocomp bEMEM.PostCostToComp
    *	@fuelcostcode	bEMEM.FuelCostCode	
    *	@msg		Description or Error msg if error
    *
    * RETURN VALUE:
    * 	0 	    Success
    *	1 & message Failure
     **********************************************************/
   
   (@emco bCompany = null,
   @equip bEquip = null,
   @shop char(20) output,
   @warrantystatus char(1) output,
   @invloc bLoc output,
   @equiptype char(1) output,
   @postcosttocomp char(1) output,
   @fuelcostcode bCostCode output,
   @component bEquip output,
   @comptypecode varchar(10) output,
   @msg varchar(255) output)
   
   as
   
   set nocount on
   declare @rcode int, @type char(1), @warcnt smallint, @status char(1), @shopgroup bGroup
   select @rcode = 0
   
   if @emco is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @equip is null
   	begin
   	select @msg = 'Missing Equipment!', @rcode = 1
   	goto bspexit
   	end
   
	--Return if Equipment Change in progress for New Equipment Code - 126196
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
	If @rcode = 1
	begin
		  goto bspexit
	end

   /* Validate Equipment and read @shop and @type from bEMEM. */
   select @shop = Shop,
   	@equiptype = Type,
   	@postcosttocomp = PostCostToComp,
      	@status = Status,
   	@fuelcostcode = FuelCostCode,
   	@msg = Description
   from bEMEM
   where EMCo = @emco
   	and Equipment = @equip
   if @@rowcount = 0
   	begin
   	select @msg = 'Equipment invalid!', @rcode = 1
   	goto bspexit
   	end


   /* Treat a null EMEM.PostCostToComp as a 'N'. */
   if @postcosttocomp is null
   	select @postcosttocomp = 'N'
   
   /* Reject if passed Equipments Type is C for Component. */
   if @equiptype = 'C'
   	begin
   	select @msg = 'Equipment is a Component!', @rcode = 1
   	goto bspexit
   	end
   
   /* Reject if Status inactive. */
   if @status = 'I'
      begin
      select @msg = 'Equipment Status = Inactive!', @rcode = 1
      goto bspexit
      end
   
   /* Get any Component (and ComponentTypeCode) for the Equipment */
   select @component = Equipment, @comptypecode = ComponentTypeCode from bEMEM where EMCo = @emco and CompOfEquip = @equip
   
   /* Determine if active warranties exist. */
   select @warcnt=Count(*)
   from EMWF where EMCo = @emco 
   	and (Equipment = @equip or Equipment in (select Equipment from bEMEM where EMCo = @emco and CompOfEquip = @equip))
   	and Status = 'A' 
   if @warcnt>0
   	select @warrantystatus='A'
   else
   	select @warrantystatus='I'
   
   /* Read inventory location from bEMSX for @shop, if available. */
   if @shop is not null
   	/* Get ShopGroup from bHQCO for @emco */
   	select @shopgroup = ShopGroup from bHQCO where HQCo = @emco
   	select @invloc = InvLoc
   	from bEMSX
   	where Shop = @shop and ShopGroup = @shopgroup
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValForTimeCards] TO [public]
GO
