SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspEMCostCodeValForWOTimeCards]
    /***********************************************************
     * Created By:		JM 7/12/02 - Adapted from bspEMCostCodeVal
     * Modified By:	GF 01/17/2002 - issue #19127 not pulling correct GL Trans Acct
     *					TV 02/11/04 - 23061 added isnulls	
     *					TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
     * USAGE:
     * Validates EM Cost Code and returns following values for insertion into bEMBF:
     *
     *	GLTransAcct = either bEMDO.GLAcct for EMCo and Dept and EMGroup and CostCode
     *			or bEMDG.GLAcct for EMCo and Dept and EMGroup and EMCO.LaborCT
     *	GLOffsetAcct = bEMDM.LaborFixedRateAcct for EMCo and bEMEM.Department for EMCo and Equipment
     *
     * Error returned if any of the following occurs
     *
     * 	No EMGroup passed
     *	No CostCode passed
     *	CostCode not found in EMCC
     *
     * INPUT PARAMETERS
     *   EMGroup   EMGroup to validate against 
     *   CostCode  Cost Code to validate 
     *
     * OUTPUT PARAMETERS
     *   @msg      Error message if error occurs, otherwise 
     *		Description of CostCode from EMCC
     *
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/ 
   (@emco bCompany = null, @equipment bEquip = null, @emgroup bGroup = null, 
    @costcode bCostCode = null,  @gltransacct bGLAcct = null output, @gloffsetacct bGLAcct = null output,
    @msg varchar(255) output)
    
   as
   set nocount on
    
   declare @rcode int, @department bDept
   
   select @rcode = 0
    
   if @emco is null
    	begin
    	select @msg = 'Missing EM Comany!', @rcode = 1
    	goto bspexit
    	end
   if @equipment is null
    	begin
    	select @msg = 'Missing Equipment!', @rcode = 1
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
    
   -- Validate CostCode
   select @msg = Description from bEMCC with (nolock) where EMGroup = @emgroup and CostCode = @costcode 
   if @@rowcount = 0
    	begin
    	select @msg = 'Cost Code not on file!', @rcode = 1
    	goto bspexit
    	end
   
   
   set @gltransacct = null
   set @gloffsetacct = null
   
   -- Get GLTransAcct from EMDO or EMDG.
   -- If GLAcct exists in bEMDO, use it.
   select @department = Department from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment
   select @gltransacct = GLAcct from bEMDO with (nolock) where EMCo = @emco 
   and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostCode = @costcode
   if @@rowcount = 0
   	begin
   	-- If GLAcct not in bEMDO, get the GLAcct in bEMDG.
    	select @gltransacct = GLAcct from bEMDG
    	where EMCo = @emco and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup 
    	and CostType = (select LaborCT from bEMCO where EMCo = @emco)
   	end
   
   -- Reject if not found in either file.
   if @gltransacct is null
    	begin
    	select @msg = 'Missing GL Trans Acct!', @rcode = 1
    	goto bspexit
    	end
    
   -- Get GLOffsetAcct from EMDM for Dept for Equip
   select @gloffsetacct = LaborFixedRateAcct from bEMDM where EMCo = @emco
    	and isnull(Department,'') = (select isnull(Department,'') from bEMEM where EMCo = @emco and Equipment = @equipment)
   if @gloffsetacct is null
    	begin
    	select @msg = 'Missing LaborFixedRateAcct in EMDM!', @rcode = 1
    	goto bspexit
    	end
   
   
   
   
   bspexit:
    	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMCostCodeValForWOTimeCards]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCostCodeValForWOTimeCards] TO [public]
GO
