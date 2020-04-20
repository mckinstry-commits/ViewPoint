SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspEMCostCodeValForPartsPosting]
    /***********************************************************
     * CREATED BY: JM 12/10/01- Adapted from bspEMCostCodeValForFuelPosting - Ref Issue 17523 - Added WO and 
     *	WOItem input params and code to select @costtype in section before select for GLTransAcct against EMDG.
     *				GF 03/05/03 - issue #20570 - problems with cost type if passed in as alpha
     *				TV 02/11/04 - 23061 added isnulls	
     *				TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
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
     *   GLTransAcct from from
     *
     * OUTPUT PARAMETERS
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
    @GLTransAcctIn bGLAcct = null, --can be null
    @costtype varchar(10) = null,
    @workorder bWO = null,
    @woitem  smallint = null,
    @GLTransAcctOut bGLAcct output,
    @msg varchar(255) output)
    
    as
    
    set nocount on
    
    declare @rcode int, @department bDept, @GLTransAcct bGLAcct, @costtypeout bEMCType
    
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
   
   if isnull(@costtype,'') = '' select @costtypeout = null
   -- if @costtype is not null, check to see if alpha and convert to numeric. may be null
   if isnull(@costtype,'') <> '' 
   	begin
   	if isnumeric(@costtype) = 1
   		select @costtypeout = @costtype
   	else
   		select @costtypeout = CostType
   		from EMCT with (nolock)
   		where EMGroup = @emgroup and CostType=(select min(e.CostType) from bEMCT e where e.EMGroup=@emgroup 
   												and e.Abbreviation like @costtype + '%')
   		if @@rowcount = 0
   			begin
    			select @msg = 'EM Cost Type not on file!', @rcode = 1
   			goto bspexit
     			end
   	end
   
   
   /* ****************************************** */
   /* Replace GLTransAcct from Equip validation with acct from EMDO or EMDG if it exists */
   /* ****************************************** */
   -- Get Department for @equipment from bEMEM.
   -- If GLAcct exists in bEMDO, use it.
   select @GLTransAcct = null
   select @department = Department 
   from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment
   select @GLTransAcct = GLAcct 
   from bEMDO with (nolock) where EMCo=@emco and isnull(Department,'') = isnull(@department,'') and EMGroup=@emgroup and CostCode=@costcode
   if @@rowcount = 0
   	begin
   	-- Since CostType coming in can be null due to 'switcharoo' in the form, get the CT here if it is
   	if @costtypeout is null
   		begin
   		if (select InHseSubFlag from bEMWI where EMCo = @emco and WorkOrder = @workorder and WOItem = @woitem) = 'O'
   		 	select @costtypeout = OutsideRprCT from bEMCO where EMCo = @emco
   		else
   		 	select @costtypeout = (select PartsCT from bEMCO where EMCo = @emco)
   		end
    	select @GLTransAcct = GLAcct from bEMDG where EMCo = @emco and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostType = @costtypeout
   	end
   
   if @GLTransAcct is not null
    	select @GLTransAcctOut = @GLTransAcct
   else
   
    	select @GLTransAcctOut = @GLTransAcctIn
   
   -- Reject if not found in either file.
   if @GLTransAcctOut is null
     	begin
     	select @msg = 'Missing GL Trans Acct!', @rcode = 1
     	goto bspexit
     	end
   
   
   
   
   bspexit:
    	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMCostCodeValForPartsPosting]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCostCodeValForPartsPosting] TO [public]
GO
