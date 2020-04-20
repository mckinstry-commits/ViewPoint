SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspEMUsageGlacctDflt]
    
    /***********************************************************
     * Created By: 	bc 01/05/98
     * Modified By:  bc 01/13/98
     *               bc 05/29/01 - added phase in order to derive GLAcct from the ContractItem set up in JCJP
     *				TV 02/11/04 - 23061 added isnulls
     *				RT 05/27/04 - 24647 Initialize @rcode to zero.
     * USAGE:
     * this sp takes infomation about a usage posting line and returns the default offset
     * glacct.
     *
     *
     * INPUT PARAMETERS
     *   @emco		form company
     *   @emgroup		EM Group
     *   @transtype		EMTranstype
     *   @jcco     		Job Cost Company
     *   @job		Job
     *   @jcct		Cost type to get default from
     *   @cost_emco		The equipment company being worked on
     *   @cost_equip	The equipment being worked on
     *   @costcode  	EM Cost code
     *   @emct		Equipment cost type
     *
     * OUTPUT PARAMETERS
     *    glacct        GLAcct for this costtype
     *    msg           acct description or error message
     *
     *
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
    
    (@emco bCompany = 0, 
    @emgroup bGroup, 
    @transtype char(1),
    @jcco bCompany = null, 
    @job bJob = null, 
    @phase bPhase = null, 
    @jcct bJCCType = null, 
    @cost_emco bCompany = null,
    @cost_equip bEquip = null, 
    @costcode bCostCode = null, 
    @emct bEMCType = null,
    @glacct bGLAcct output, 
    @msg varchar(100) output)
    
    as
    
    set nocount on
    
    declare @rcode int, @dept bDept, @cost_dept bDept, @glco bCompany, @defglacct bGLAcct
    select @rcode = 0
   
    /* get the cost gl acct from the JC or EM deptartments */
    
    if @transtype = 'J' and @jcco is not null and @job is not null
    	begin
    	exec @rcode = bspARMRDefaultGLAcctGet @jcco, @job, @phase, @jcct, @defglacct=@glacct output, @msg=@msg output
    	if @rcode <> 0 goto bspexit
    	end
 
    if @transtype in ('E','W')
    	begin
    	select @cost_dept = Department from bEMEM where EMCo = @cost_emco and Equipment = @cost_equip
    	if @cost_dept is null
    		begin
    		select @msg = 'Missing dept for equipment ' + isnull(@cost_equip,''), @rcode = 1
    		goto bspexit
    		end
    
    	select @glacct = GLAcct from bEMDO where EMCo = @cost_emco and EMGroup = @emgroup and Department = @cost_dept and CostCode = @costcode
    	if @glacct is null
    		begin
    		select @glacct = GLAcct from bEMDG where EMCo = @cost_emco and EMGroup = @emgroup and Department = @cost_dept and CostType = @emct
    		/* if no glacct is found then any bsp that call this one will throw an error at that end  if called from vb no error is thrown because the field is not required until validation time */
    		end
    	end
    
    bspexit:
    	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMUsageGlacctDflt]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMUsageGlacctDflt] TO [public]
GO
