SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[vspEMEquipValNoCompWOEdit]
   
   /***********************************************************
    * CREATED BY: TRL 05/01/07
    * MODIFIED BY:	TRL 08/13/2008 - 126196 check to see Equipment code is being Changed 
    *            
    * 	
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
   
   (@emco bCompany = null, @equip bEquip = null, @shop char(20) output, @warrantystatus char(2) output, @woexists char(1) output,
   @equiptype char(1) output, @postcosttocomp char(1) output, @msg varchar(255) output)
   
   as
   
   set nocount on
   declare @rcode int, @type char(1), @warcnt smallint, @status char(1)
   select @rcode = 0, @woexists = 'N', @warrantystatus='N'
   
   if @emco is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto vspexit
   	end
   
   if @equip is null
   	begin
   	select @msg = 'Missing Equipment!', @rcode = 1
   	goto vspexit
   	end
   
	-- Return if Equipment Change in progress for New Equipment Code, 126196.
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
	If @rcode = 1
	begin
		  goto vspexit
	end

   /* Validate Equipment and read @shop and @type from bEMEM. */
   select @shop = Shop,	@equiptype = Type, @postcosttocomp = PostCostToComp, @status = Status, @msg = Description
   from dbo.EMEM with (nolock)
   where EMCo = @emco
   	and Equipment = @equip
   if @@rowcount = 0
   	begin
   	select @msg = 'Equipment invalid!', @rcode = 1
   	goto vspexit
   	end
	   
-- Treat a null EMEM.PostCostToComp as a 'N'. 
   if @postcosttocomp is null
   	select @postcosttocomp = 'N'
   
-- Reject if passed Equipments Type is C for Component. 
   if @equiptype = 'C'
   	begin
   	select @msg = 'Equipment is a Component!', @rcode = 1
   	goto vspexit
   	end
   
-- Reject if Status inactive. 
   if @status = 'I'
      begin
      select @msg = 'Equipment Status = Inactive!', @rcode = 1
      goto vspexit
      end
   
--determine if open WO exist
	if exists (select top 1 1 from dbo.EMWH with (nolock) where EMCo = @emco and Equipment = @equip and Complete = 'N')
		begin
		select @woexists = 'Y'
		end
		
--Check for Warranties first
	select Equipment from dbo.EMWF with(nolock) 
	where EMCo = @emco and (Equipment = @equip or Equipment in (select Equipment from dbo.EMEM with (nolock) where EMCo = @emco and CompOfEquip = @equip))
	If @@rowcount >=1 
	begin
		select @warrantystatus = 'YN'
	end	

--Check for Active Warranties second
	select Equipment from dbo.EMWF with (nolock) 
	where EMCo = @emco and (Equipment = @equip or Equipment in (select Equipment from dbo.EMEM with (nolock) where EMCo = @emco and CompOfEquip = @equip)) and Status = 'A' 
	If @@rowcount >=1 
	begin
		select @warrantystatus = 'YA'
	end	
   	


   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipValNoCompWOEdit] TO [public]
GO
