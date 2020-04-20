SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCostTypeValForFuelPosting    Script Date: 4/26/2002 10:32:41 AM ******/
CREATE proc [dbo].[bspEMCostTypeValForFuelPosting]
/***********************************************************
* CREATED BY: JM 3/27/02 - Copied from bspEMCostTypeVal and modified for Fuel Posting
* MODIFIED By: JM 12-23-02 - Ref Issue 19730 - Add same validation of CT to CC as in EMCostAdj
*		GF 03/05/03 - issue #20570 - problems with cost type if passed in as alpha
*		TV 02/11/04 - 23061 added isnulls	
*		TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
*		TJL 05/01/07 - Issue #27990, minor cleanup and re-org for readability.  NO functional change.
*		TJL 01/29/09 - Issue #130083, EM CostType no longer clears on F3 default if CostCode missing.
*
* USAGE:
* 	Validates EM Cost Type and returns GLTransAcct per Equip Dept/CostCode/CostType
* 	An error is returned if any of the following occurs
* 	If no Cost Type passed, no Cost Type found.
*
* INPUT PARAMETERS
*   	EMGroup
*   	CostType
*
* OUTPUT PARAMETERS
*   	@desc     Description for grid
*   	@msg      error message if error occurs otherwise Description returned
* RETURN VALUE
*   	0         success
*   	1         Failure
*****************************************************/
(@emco bCompany = null, @emgroup bGroup = null, @equipment bEquip = null, 
	@costcode bCostCode = null, @costtype varchar(10) = null, @GLTransAcctFromForm bGLAcct = null,
	@costtypeout bEMCType = null output, @GLTransAcctOut bGLAcct = null output, @msg varchar(255) output)
    
as
set nocount on

declare @rcode int, @numrows int, @department varchar(10), @um bUM

select @rcode = 0

if @emco is null
	begin
	select @msg = 'Missing EM Company.', @rcode = 1
	goto bspexit
	end

if @emgroup is null
	begin
	select @msg = 'Missing EM Group.', @rcode = 1
	goto bspexit
	end

------------- Issue #130083: Move to later in procedure
--if @equipment is null
--	begin
--	select @msg = 'Missing Equipment.', @rcode = 1
--	goto bspexit
--	end
--
--if @costcode is null
--	begin
--	select @msg = 'Missing Cost Code.', @rcode = 1
--	goto bspexit
--	end

if @costtype is null
	begin
	select @msg = 'Missing Cost Type.', @rcode = 1
	goto bspexit
	end
    
/* Begin Switcheroo code:  If @costtype is numeric then try to find */
if isnumeric(@costtype) = 1
	begin
	select @costtypeout = CostType, @msg = Description
	from dbo.EMCT with (nolock)
	where EMGroup = @emgroup and CostType = convert(int,convert(float, @costtype))
	if @@rowcount <> 0 goto Check_EMCX
	end
   
/* If not numeric or not found try to find as Sort Name */
select @costtypeout = CostType, @msg = Description
from dbo.EMCT with (nolock)
where EMGroup = @emgroup and CostType=(select min(e.CostType) from dbo.EMCT e with(nolock) where e.EMGroup=@emgroup 
											and e.Abbreviation like @costtype + '%')
if @@rowcount = 0
	begin
	select @msg = 'EM Cost Type not on file.', @rcode = 1
	goto bspexit
 	end

/* Issue #130083: CONTINUE WITH ADDITIONAL CHECKS BASED UPON A VALID COSTCODE, EQUIP, AND COSTTYPE */
-- Inputs for @equipment and @costcode get tested here rather than at beginning of procedure to allow 
-- CostType switcheroo to do its job first.  In this way user can F3 a CostType without
-- also having to F3 Equipment and CostCode.  
if @equipment is null
	begin
	select @msg = 'Missing Equipment.', @rcode = 1
	goto bspexit
	end

if @costcode is null
	begin
	select @msg = 'Missing Cost Code.', @rcode = 1
	goto bspexit
	end
    
-- JM 12-23-02 - Ref Issue 19730 - Add same validation of CT to CC as in EMCostAdj
/* If @costtype valid in bEMCT, verify it is linked to @costcode in EMCX. */
Check_EMCX:
select @um = UM
from dbo.EMCX with (nolock) 
where EMGroup = @emgroup and CostType = @costtypeout and CostCode = @costcode
if @@rowcount = 0
	begin
 	select @msg = 'Cost Type not linked to Cost Code.', @rcode = 1
 	goto bspexit
 	end
   
/* If GLAcct exists in bEMDO use it, else get it from EMDG */
select @department = Department 
from dbo.EMEM with (nolock) where EMCo = @emco and Equipment = @equipment 
select @GLTransAcctOut = GLAcct 
from dbo.EMDO with (nolock) where EMCo=@emco and isnull(Department,'') = isnull(@department,'') and EMGroup=@emgroup and CostCode=@costcode
if isnull(@GLTransAcctOut,'') = ''
	begin
	select @GLTransAcctOut = GLAcct 
	from dbo.EMDG with (nolock) where EMCo=@emco and isnull(Department,'') = isnull(@department,'') and EMGroup=@emgroup and CostType=@costtypeout
	end
   
/* Original GLTransAcct may have been provided by Equipment validation.  If however user has modified
   either the CostCode or CostType since defaulting from Equipment then GLTransAcct may be different.
   If we have found an override acct use it otherwise send back the acct from the original Equip val. */
if isnull(@GLTransAcctOut,'') = '' select @GLTransAcctOut = @GLTransAcctFromForm
   
bspexit:
--if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMCostTypeValForFuelPosting]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCostTypeValForFuelPosting] TO [public]
GO
