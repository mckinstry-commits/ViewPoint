SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspEMEquipValForAsset]
   /***********************************************************
    * CREATED By:	DANF 04/17/2007
    * MODIFIED By:	TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
    *
    * USAGE:
    *	Validates EMEM.Equipment
    *
    * INPUT PARAMETERS
    *	@emco			EM Company
    *	@equip			Equipment to be validated
    *
    * OUTPUT PARAMETERS
    *	@status			EM Equipment Status
    *	@purchaseprice	EM Pruchase Price
    *	@msg 		error or Description
    *
    * RETURN VALUE
    *	0 success
    *	1 error
    ***********************************************************/
   (@emco bCompany = null, @equip bEquip = null, @status char(1) output, 
	@purchaseprice bUnitCost output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @numrows int
   
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

   select  @msg=Description, 
	@status = Status, 
	@purchaseprice = PurchasePrice
	from bEMEM with (nolock)
	where EMCo = @emco and Equipment = @equip
   select @numrows = @@rowcount
   if @numrows = 0
   	begin
   	select @msg = 'Equipment invalid!', @rcode = 1
   	end
   
   if @status = 'I'
   	begin
   	select @msg = isnull(@msg,'') + ' : Status = Inactive'
   	end
   

   /*
   -- Reject if Status inactive.
   if @status = 'I'
      begin
      select @msg = 'Equipment Status = Inactive!', @rcode = 1
      goto bspexit
      end
   */
   
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipValForAsset] TO [public]
GO
