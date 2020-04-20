SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMStdMaintGroupVal    Script Date: 8/28/99 9:34:33 AM ******/
   CREATE   proc [dbo].[bspEMStdMaintGroupVal]
   
   (@emco bCompany = null, @equip bEquip = null, @stdmaintgroup varchar(10) = null, 
   @msg varchar(255) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: JM 9/12/98
   
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    * USAGE:
    * Validates EM Std Maint Group vs bEMSH by EMCo, Equipment and StdMaintGroup.
    * Error returned if any of the following occurs
    *
    * 	No EMCo passed
    *	No Equipment passed
    *	No StdMaintGroup passed
    *	StdMaintGroup not found in EMSH
    *
    * INPUT PARAMETERS
    *	EMCo		EMCo to validate against 
    *	Equipment	Equipment to validate against
    *	StdMaintGroup  	StdMaintGroup to validate 
    *
    * OUTPUT PARAMETERS
    *   	@msg	Error message if error occurs, otherwise 
    *		Description of StdMaintGroup from EMSH
    *
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/ 
   
   declare @rcode int
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
   
   if @stdmaintgroup is null
   	begin
   	select @msg = 'Missing Std Maint Group!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description 
   from dbo.EMSH with (nolock)
   where EMCo = @emco and Equipment = @equip and StdMaintGroup = @stdmaintgroup
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Std Maint Group not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	--if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMStdMaintGroupVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMStdMaintGroupVal] TO [public]
GO
