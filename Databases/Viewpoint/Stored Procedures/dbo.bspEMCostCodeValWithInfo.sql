SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCostCodeValWithInfo    Script Date: 8/28/99 9:34:26 AM ******/
   CREATE    proc [dbo].[bspEMCostCodeValWithInfo]
   /***********************************************************
    * CREATED BY: JM 8/21/98
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls	
    *					TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
    *
    * USAGE:
    * Validates EM Cost Code and returns GLTransAcct from EMDO if it exists.
    * Error returned if any of the following occurs:
    *
    *	No EMCo, EMGroup, or CostCode passed
    *	CostCode not found in EMCC
    *
    * INPUT PARAMETERS
    *   EMCo
    *   EMGroup   EMGroup to validate against
    *   CostCode  Cost Code to validate
    *   Equipment
    *
    * OUTPUT PARAMETERS
    *    GLTransAcct from EMDO if it exists
    *   @msg      Error message if error occurs, otherwise
    *		Description of CostCode from EMCC
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
   (@emco bCompany = null,
   @emgroup bGroup = null,
   @costcode bCostCode = null,
   @equipment bEquip = null,
   @gltransacct bGLAcct output,
   @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @department bDept
   select @rcode = 0
   
   if @emco is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @emgroup is null
   	begin
   	select @msg = 'Missing EM Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @costcode is null
   	begin
   	select @msg = 'Missing Cost Code!', @rcode = 1
   	goto bspexit
   	end
   
   if @equipment is null
   	begin
   	select @msg = 'Missing Equipment!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   from bEMCC
   where EMGroup = @emgroup and CostCode = @costcode
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Cost Code not on file!', @rcode = 1
   	goto bspexit
   	end
   
   /* ****************************************** */
   /* Get GLTransAcct from EMDO if it exists */
   /* ****************************************** */
   /* Step 1 - Get Department for @equipment from bEMEM. */
   select @department = Department
   from bEMEM
   where EMCo = @emco
   	and Equipment = @equipment
   /* Step 2 - If GLAcct exists in bEMDO, use it. */
   select @gltransacct = GLAcct
   from bEMDO
   where EMCo = @emco
   	and isnull(Department,'') = isnull(@department,'')
   	and EMGroup = @emgroup
   	and CostCode = @costcode
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMCostCodeValWithInfo]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCostCodeValWithInfo] TO [public]
GO
