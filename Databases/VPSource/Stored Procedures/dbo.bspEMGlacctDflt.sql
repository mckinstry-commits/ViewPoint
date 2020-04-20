SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspEMGlacctDflt] 
   /***************************************************
   * created by: TV 07/02/02
   *			TV 02/11/04 - 23061 added isnulls	
   *			TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
   *			DANF 08/24/2006 - Corrected incorrect sysntax near b by wraping last if statment with a begin / end
   *			DAN SO - 04/03/2008 - 127413 - Commented out @deadum - if no UM - would return NULL and blank out TransAcct in EM Cost Adjustments
   *			DAN SO - 01/03/2012 - TK-10952 - need to get Override GL flag
   *
   * Reason: A specific procedure  for default a GL Account for EM
   *
   *    inputs: EMCo
   *            EMGroup
   *            CostType
   *            CostCode
   *            Equip
   *            Force GL Accout = y or n
   *            
   *    Output: GLAcct
   *			
   *            Error Msg
   *                        
   *****************************************************/
   
   (@emco bCompany=null,
   @emgroup bGroup = null,
   @costtype bEMCType = null,
   @costcode bCostCode = null,
   @equipment bEquip=null,
   @gltransacct bGLAcct output,
   @GLOverride bYN output,		-- TK-10952 --
   @msg varchar(60) output)
   
   as
   
   set nocount on
   
   declare @department bDept, @numrows int, @rcode int, @deadum bUM
   
   select @rcode = 0, @numrows = 0
   
   if @emco is null or @emgroup is null or @equipment is null
   	begin
   	goto bspexit
   	end
   
   
   if @costtype is null and @costcode is null
   	begin
   	goto bspexit
   	end
   
   
   
   /**************************************************************************/
   /* If @costtype valid in bEMCT, verify it is linked to @costcode in EMCX. */
   /**************************************************************************/
--   select @deadum = UM
--   from bEMCX
--   where EMGroup = @emgroup
--   	and CostType = @costtype
--   	and CostCode = @costcode
--
--   if @@rowcount = 0
--   	begin
--   	goto bspexit
--   	end
   
   /**************************************/
   /* Get GLTransAcct from EMDO or EMDG. */
   /**************************************/
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

   /* Step 3 - If GLAcct not in bEMDO, get the GLAcct in bEMDG. */
	IF @gltransacct IS NULL
	begin
   	select @gltransacct = GLAcct
   	from bEMDG
   	where EMCo = @emco
   		and isnull(Department,'') = isnull(@department,'')
   		and EMGroup = @emgroup
   		and CostType = @costtype
	end
   
    --------------
	-- TK-10952 --
    --------------
    SELECT @GLOverride = GLOverride FROM bEMCO WHERE EMCo = @emco
   
   
   bspexit:
   	
   	return

GO
GRANT EXECUTE ON  [dbo].[bspEMGlacctDflt] TO [public]
GO
