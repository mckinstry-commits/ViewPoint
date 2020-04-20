SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCostTypeValForCostCode    Script Date: 12/13/2001 11:07:01 AM ******/
CREATE       proc [dbo].[bspEMCostTypeValForCostCodeforEMCostAdj]
/***********************************************************
* CREATED BY:	TV - adapted from bspEMCostTypeValForCostCode
*				TV 08/18/05 29375 - Set offset account to Misc from EM
*		TJL 01/29/09 - Issue #130083, EM CostType no longer clears on F3 default if CostCode missing.
*				
* USAGE:
* 	Validates EM Cost Type against bEMCT and then verifies
*	that the CT is linked to the passed CostCode in EMCX.
*
*	Returns	GLTransAcct from EMDO by EMCo/EMEM.Department
*	(by EMCo/Equipment if Equipment or EMCo/CompOfEquip if
*	Component)/CostCode/EMGroup; or from EMDG by
*	EMCo/Department/CostType/EMGroup.
*
* 	An error is returned if any of the following occurs:
* 		EMCo, EMGroup, CostType, CostCode, or Equipment not passed.
*		Cost Type not found in EMCT or not linked to passed CostCode in EMCX.
*
* INPUT PARAMETERS
*	EMCo
*  EMGroup
*  CostType
*	CostCode
*	Equipment
*  Whether to force return of a valid GLTransAcct
*
* OUTPUT PARAMETERS
*	@desc     	Description for grid
*	@gltransacct	GLAcct per comments in USAGE above.
* 	@msg      	Error message if error occurs otherwise Description returned
*
* RETURN VALUE
*   	0         	Success
*   	1         	Failure
*****************************************************/
(@emco bCompany=null, @emgroup bGroup = null, @costtype varchar(10) = null,
@costcode bCostCode = null, @equipment bEquip=null, @forcevalidglacct char(1) = null,
@costtypeout bEMCType output, @gltransacct bGLAcct output, @gloffsetacct bGLAcct output,
@msg varchar(255) output)
as
set nocount on

declare @department bDept, @numrows int, @rcode int, @deadum bUM

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
if @costtype is null
	begin
	select @msg = 'Missing Cost Type!', @rcode = 1
	goto bspexit
	end
------------- Issue #130083: Move to later in procedure
--if @costcode is null
--	begin
--	select @msg = 'Missing Cost Code!', @rcode = 1
--	goto bspexit
--	end
--if @equipment is null
--	begin
--	select @msg='Missing Equipment!', @rcode=1
--	goto bspexit
--	end
if @forcevalidglacct is null
	begin
	select @msg='Missing Force Valid GLTransAcct option!', @rcode=1
	goto bspexit
	end
    
/**************************************/
/* Do normal validation on @costtype. */
/**************************************/

-- If @costtype is numeric then try to find
if isnumeric(@costtype) = 1
   	begin
	select @costtypeout = CostType, @msg = Description
	from EMCT with (nolock)
	where EMGroup = @emgroup and CostType = convert(int, convert(float, @costtype))
   	if @@rowcount <> 0 goto Check_EMCX
	end
   
-- if not numeric or not found try to find as Sort Name
select @costtypeout = CostType, @msg = Description
from EMCT with (nolock)
where EMGroup = @emgroup and CostType=(select min(e.CostType) from bEMCT e where e.EMGroup=@emgroup
                              and e.Abbreviation like @costtype + '%')
if @@rowcount = 0
   	begin
   	select @msg = 'Cost Type not on file!', @rcode = 1
   	goto bspexit
   	end
    
/* Issue #130083: CONTINUE WITH ADDITIONAL CHECKS BASED UPON A VALID COSTCODE, EQUIP, AND COSTTYPE */
-- Inputs for @equipment and @costcode get tested here rather than at beginning of procedure to allow 
-- CostType switcheroo to do its job first.  In this way user can F3 a CostType without
-- also having to F3 Equipment and CostCode.  
if @costcode is null
	begin
	select @msg = 'Missing Cost Code!', @rcode = 1
	goto bspexit
	end
if @equipment is null
	begin
	select @msg='Missing Equipment!', @rcode=1
	goto bspexit
	end
  
/**************************************************************************/
/* If @costtype valid in bEMCT, verify it is linked to @costcode in EMCX. */
/**************************************************************************/
Check_EMCX:
select @deadum = UM
from EMCX with (nolock)
where EMGroup = @emgroup and CostType = @costtypeout and CostCode = @costcode
if @@rowcount = 0
   	begin
	select @msg = 'Cost Type not linked to CostCode!', @rcode = 1
	goto bspexit
	end

--TV 08/18/05 29375 - Set offset account to Misc from EM
select @gloffsetacct = MatlMiscGLAcct
from bEMCO 
where EMCo = @emco
   
/**************************************/
/* Get GLTransAcct from EMDO or EMDG. */
/**************************************/
-- Step 1 - Get Department for @equipment from bEMEM.
select @department = Department
from bEMEM with (nolock)
where EMCo = @emco and Equipment = @equipment

-- Step 2 - If GLAcct exists in bEMDO, use it.
select @gltransacct = GLAcct
from bEMDO with (nolock)
where EMCo = @emco and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostCode = @costcode

-- Step 3 - If GLAcct not in bEMDO, get the GLAcct in bEMDG.
if isnull(@gltransacct,'') = ''
   	begin
   	select @gltransacct = GLAcct
	from bEMDG with (nolock)
	where EMCo = @emco and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostType = @costtypeout
   	end
   
-- Step 4 - If @forcevalidglacct = 'Y' return an error if @gltransacct still not found.
if @forcevalidglacct = 'Y' and (@gltransacct is null or @gltransacct = '')
	begin
	select @msg = 'GLTransAcct not found in EMDO or EMDG!', @rcode = 1
	goto bspexit
	end

bspexit:
if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) +  '[bspEMCostTypeValForCostCode]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCostTypeValForCostCodeforEMCostAdj] TO [public]
GO
