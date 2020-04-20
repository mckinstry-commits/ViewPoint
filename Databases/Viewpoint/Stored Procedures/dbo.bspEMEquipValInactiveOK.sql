SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMEquipValInactiveOK    Script Date: 1/17/2002 10:49:42 AM ******/
   /****** Object:  Stored Procedure dbo.bspEMEquipVal    Script Date: 10/17/2001 1:45:34 PM ******/
   /****** Object:  Stored Procedure dbo.bspEMEquipVal    Script Date: 8/28/99 9:32:41 AM ******/
   CREATE    procedure [dbo].[bspEMEquipValInactiveOK]
   
   /***********************************************************
    * CREATED BY: JM 10/17/01
    * MODIFIED By :TV 02/11/04 - 23061 added isnulls	
	*				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
    *
    * USAGE:
    *	Validates EMEM.Equipment and allows inactive status. Ref Issue 14227.
    *
    * INPUT PARAMETERS
    *	@emco		EM Company
    *	@equip		Equipment to be validated
    *
    * OUTPUT PARAMETERS
    *	@msg 		error or Description
    *
    * RETURN VALUE
    *	0 success
    *	1 error
    ***********************************************************/
   
   	(@emco bCompany = null,
   	@equip bEquip = null,
   	@msg varchar(255) output)
   
   as
   
   set nocount on
   declare @rcode int, @status char(1)
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

   select  @msg=Description, @status = Status
   from bEMEM
   where EMCo = @emco and Equipment = @equip
   	if @@rowcount = 0
   		begin
   		select @msg = 'Equipment invalid!', @rcode = 1
   		end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMEquipValInactiveOK]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValInactiveOK] TO [public]
GO
