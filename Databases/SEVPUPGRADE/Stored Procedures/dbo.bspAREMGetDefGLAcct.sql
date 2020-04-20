SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAREMGetDefGLAcct    Script Date: 8/28/99 9:34:26 AM ******/
   CREATE proc [dbo].[bspAREMGetDefGLAcct]
   
   /***********************************************************
    * CREATED BY: 	TJL - 08/03/01
    * MODIFIED By :
    *
    * USAGE:
    *	This routine called to determine default GLAccount. 
    *	First by Valid CostCode and second by valid EM CostType
    *
    * 	An error is returned if any of the following occurs:
    * 		For Default Value only. No errors are returned.
    *		
    *
    * INPUT PARAMETERS
    *	EMCo
    *   	EMGroup
    *   	CostType
    *	CostCode
    *	Equipment
    *
    * OUTPUT PARAMETERS
    *	@desc     	Description for grid
    *	@gltransacct	GLAcct per comments in USAGE above.
    *   	@msg      	Error message if error occurs otherwise Description returned
    *
    * RETURN VALUE
    *   	0         	Success
    *   	1         	Failure
    *****************************************************/
   
   (@emco bCompany=null,
   @emgroup bGroup = null,
   @equipment bEquip=null,
   @costcode bCostCode = null,
   @costtype varchar(10) = null,
   @gltransacct bGLAcct output,
   @msg varchar(60) output)
   
   as
   
   set nocount on
   
   declare @department bDept, @numrows int, @rcode int
   
   select @rcode = 0, @numrows = 0
   
   if @emco is null
   	begin
   	select @msg='Missing EM Company!', @rcode=1
   	goto bspexit
   	end
   
   if @emgroup is null
   	begin
   	select @msg = 'Missing EM Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @equipment is null
   	begin
   	select @msg='Missing Equipment!', @rcode=1
   	goto bspexit
   	end
   
   /* First Priority - Use CostCode for GLAccount if valid */
   select @msg = Description
   from bEMCC
   where EMGroup = @emgroup and CostCode = @costcode
   
   if @@rowcount = 1
   	begin
   	/* ****************************************** */
   	/* Get GLTransAcct from EMDO if it exists */
   	/* ****************************************** */
   	/* Step 1 - Get Department for @equipment from bEMEM. */
   	select @department = Department
   	from bEMEM
   	where EMCo = @emco and Equipment = @equipment
   
   	/* Step 2 - If GLAcct exists in bEMDO, use it. */
   	select @gltransacct = GLAcct
   	from bEMDO
   	where EMCo = @emco
   		and Department = @department
   		and EMGroup = @emgroup
   		and CostCode = @costcode
   
   	if @@rowcount = 1 goto bspexit
   	end
   
   /* Second Priority - Use CostType for GLAccount if CostCode not valid */
   /* We can only get here if NO GLAcct was found for CostCode. */
   
   select @department = Department
   from bEMEM
   where EMCo = @emco and Equipment = @equipment
   
   --if @gltransacct is null or @gltransacct = ''
   select @gltransacct = GLAcct
   from bEMDG
   where EMCo = @emco
   	and Department = @department
   	and EMGroup = @emgroup
   	and CostType = convert(tinyint,@costtype)
   
   /* If neither operation was successful, NO GLAccount default will be returned */
   
   bspexit:
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAREMGetDefGLAcct] TO [public]
GO
