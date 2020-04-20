SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      procedure [dbo].[bspEMEquipValNoComponent]
   
   /***********************************************************
    * CREATED BY: JM 9/22/98
    * MODIFIED By : JM 1/15/99 - Added return of bEMEM.PostCostToComp
    *              JM 5/9/00 - Added restriction on validation to Status A or D
    * 	JM 2-12-02 Corrected reference to EMSX to include ShopGroup in key.
    *	TV 02/11/04 - 23061 added isnulls	
	*	TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
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
    *	@msg		Description or Error msg if error
    *
    * RETURN VALUE:
    * 	0 	    Success
    *	1 & message Failure
     **********************************************************/
   
   (@emco bCompany = null, @equip bEquip = null, @shop char(20) output, @warrantystatus char(1) output, @invloc bLoc output,
   @equiptype char(1) output, @postcosttocomp char(1) output, @msg varchar(255) output)
   
   as
   
   set nocount on
   declare @rcode int, @type char(1), @warcnt smallint, @status char(1)
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
   select @shop = Shop,	@equiptype = Type, @postcosttocomp = PostCostToComp, @status = Status, @msg = Description
   from bEMEM
   where EMCo = @emco
   	and Equipment = @equip
   if @@rowcount = 0
   	begin
   	select @msg = 'Equipment invalid!', @rcode = 1
   	goto bspexit
   	end
   
	-- Treat a null EMEM.PostCostToComp as a 'N'. 
   if @postcosttocomp is null
   	select @postcosttocomp = 'N'
   
   -- Reject if passed Equipments Type is C for Component. 
   if @equiptype = 'C'
   	begin
   	select @msg = 'Equipment is a Component!', @rcode = 1
   	goto bspexit
   	end
   
   -- Reject if Status inactive. 
   if @status = 'I'
      begin
      select @msg = 'Equipment Status = Inactive!', @rcode = 1
      goto bspexit
      end
   
   -- Determine if active warranties exist. 
   if exists (select top 1 1 
   from EMWF 
	where EMCo = @emco and (Equipment = @equip or Equipment in (select Equipment from bEMEM where EMCo = @emco and CompOfEquip = @equip)) and Status = 'A') 
     		select @warrantystatus='A'
   	else
   		select @warrantystatus='I'
   	

   --Read inventory location from bEMSX for @shop, if available. 
   if isnull(@shop,'') <> ''
		begin
   	select @invloc = InvLoc
   	from bEMSX
   	where Shop = @shop and ShopGroup = (select ShopGroup from bHQCO where HQCo = @emco)
   	end


   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMEquipValNoComponent]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValNoComponent] TO [public]
GO
