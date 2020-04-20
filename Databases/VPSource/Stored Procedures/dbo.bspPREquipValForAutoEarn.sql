SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspPREquipValForAutoEarn]
   
     /***********************************************************
      * CREATED BY: MV 12/31/02
      * MODIFIED By :  
	  *				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
      *
      * USAGE:
      *	Validates EMEM.Equipment for Equipment Usage and Mechanic's Timecard
      *		in PRAutoEarn.  If equiment usage then there msut be a usage cost type.   
      *    
      *
      * INPUT PARAMETERS
      *	@emco		 EM Company
      *	@equip		 Equipment to be validated
      * @OptEM 		 Equip usage or mechanic's timecard option
      *
      * OUTPUT PARAMETERS
      *	ret val		 EMEM column
      *	-------		-----------
      * @equipdesc     Equipment description
      *	@errmsg		Description or Error msg if error
       **********************************************************/
   
     (@emco bCompany, @equip bEquip,@optem char(1),@revcode bRevCode = null output, @msg varchar(255) output)
   
     as
     set nocount on
     declare @rcode int, @type char(1), @usgcosttype bJCCType
     select @rcode = 0
   
       if @emco is null
     	begin
   
     	select @msg = 'Missing EM Company!', @rcode = 1
     	goto bspexit
     	end
   
     if @equip is null or @equip = ''
     	begin
     	select @msg = 'Missing Equipment!', @rcode = 1
     	goto bspexit
     	end
   	
   	if @optem is null
     	begin
     	select @msg = 'Missing Option - Equip Usage or Mechanics Timecard!', @rcode = 1
     	goto bspexit
     	end
    
	--Return if Equipment Change in progress for New Equipment Code - 126196
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
	If @rcode = 1
	begin
		  goto bspexit
	end

     select @type = Type, @msg = Description, @usgcosttype = UsageCostType,@revcode = RevenueCode
     from dbo.EMEM (nolock)
     where EMCo = @emco and Equipment = @equip
   

     if @optem = 'E' and @usgcosttype is null
         begin
         select @msg = 'Missing usage cost type', @rcode = 1
         goto bspexit
         end
   
   
    if @type = 'C'
     begin
     select @msg = 'Invalid entry.  Cannot be a component!', @rcode = 1
     goto bspexit
     end
   
     
   
   bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREquipValForAutoEarn] TO [public]
GO
