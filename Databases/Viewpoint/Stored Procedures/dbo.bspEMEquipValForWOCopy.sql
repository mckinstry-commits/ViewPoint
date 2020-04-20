SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      procedure [dbo].[bspEMEquipValForWOCopy]
   
   /***********************************************************
    * CREATED BY: JM 2/27/02
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls	
    *				TV 10/20/04 - modified this to be usefull. As of today, this proc is not used.
    *				TV 10/20/04 25713 - Invalid use of null error when equipment # is a component
	*				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
    *
    * USAGE:
    *	Validates EMEM.Equipment
    *	Returns Equip Desc
    *		EMEM.Shop
    *		EMSX.Description if avali or msg
    *		Next WO from EMSX if @shopopt = 'E' for Copy To Equip Shop
    *
    * INPUT PARAMETERS
    *	@emco		EM Company
    *	@equip		Equipment to be validated
    *	@shopopt	'W' for Copy From WO Shop, 'E' for Copy To Equip Shop or 'S' for specified Shop
    *
    * OUTPUT PARAMETERS
    *	@shop		Shop from EMEM
    *	@shopdesc	Description from EMSX or 'No shop assigned for this Equip'
    *	@nextwo	Next avail WO
    *	@msg 		error or Description
    *
    * RETURN VALUE
    *	0 success
    *	1 error
    ***********************************************************/
   
   (@emco bCompany = null,
   @equip bEquip = null,
   /*@shopopt char(1) = null,
   @nextwoin bWO = null,
   @shop varchar(20) output,
   @shopdesc varchar(30) output,
   @nextwo bWO output,*/
   @msg varchar(255) output)
   
   as
   
   set nocount on
   declare @rcode int, @status char(1), @numrows int, @type char(1)
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

   select  @msg=Description, @status = Status, /*@shop = Shop,*/ @type = Type
   from bEMEM
   where EMCo = @emco and Equipment = @equip
   select @numrows = @@rowcount
   if @numrows = 0
   	begin
   	select @msg = 'Equipment invalid!', @rcode = 1
   	end
   
   /* Reject if Component */
   if @type = 'C'
      begin
      select @msg = 'Equipment Type cannot be a component!', @rcode = 1
      goto bspexit
      end
   
   /* Reject if Status inactive. */
   if @status = 'I'
      begin
      select @msg = 'Equipment Status cannot be Inactive!', @rcode = 1
      goto bspexit
      end
  


   /*if @shop is null
   	select @shopdesc = 'No Shop assigned to this Equip'
   else
   	select @shopdesc = Description, @nextwo = case @shopopt when 'E' then LastWorkOrder + 1 else @nextwoin end from bEMSX 
   	where ShopGroup = (select ShopGroup from bHQCO where HQCo = @emco) and Shop = @shop*/
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMEquipVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValForWOCopy] TO [public]
GO
