SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspEMCostCodeValForFuelPosting]
/***********************************************************
* CREATED BY: JM 12/10/01
* MODIFIED By : JM 3/19/02 - Removed return of GLTransAcct - provided by Equip val on FuelPosting form.
*		GF 03/05/03 - issue #20570 - problems with cost type if passed in as alpha
*		TV 02/11/04 - 23061 added isnulls	 
*		TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
*		TJL 04/30/07 - Issue #27990 - 6x Rewrite EMFuelPosting. Corrected returning GLTansAcct from EMDO then EMDG
*						Code was bad: (if isnull(@GLTransAcct,'') <> '' and isnull(@costtype,'') <> ''), never read EMDG 
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
*   GLTransAcct from form
*	CostType from form
*
* OUTPUT PARAMETERS
*	GLTransAcct to Form based upon Department CostCode or CostType setup.
*
*   @msg      Error message if error occurs, otherwise
*		Description of CostCode from EMCC
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@emco bCompany = null, @emgroup bGroup = null, @costcode bCostCode = null,
	@equipment bEquip = null, @GLTransAcctIn bGLAcct = null, @costtype int = 0,		--@costtype varchar(10) = null,
	@GLTransAcctOut bGLAcct output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @department bDept, @GLTransAcct bGLAcct		--, @costtypeout bEMCType

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

if @costcode is null
	begin
	select @msg = 'Missing Cost Code.', @rcode = 1
	goto bspexit
	end

if @equipment is null
	begin
	select @msg = 'Missing Equipment.', @rcode = 1
	goto bspexit
	end
   
select @msg = Description
from bEMCC with (nolock)
where EMGroup = @emgroup and CostCode = @costcode
if @@rowcount = 0
	begin
	select @msg = 'Cost Code not on file.', @rcode = 1
	goto bspexit
	end

/* TJL 05/01/07 - I do not know why CostType switcheroo code is needed here??  In 'EMFuelPosting' this
   is the CostCode validation procedure.  (CostType validation and Switcheroo code will occur from
   the CostType validation procedure itself).  In fact the @costtypeout variable is not even an output.
   Lame code as far as I can tell.  If I have missed something, come see me and we will work it out. 
   (Other users:  bspEMVal_Cost_SeqVal_Fuel/Parts, EMFuelPostingInit, EMWOPartsPosting. */ 
--if isnull(@costtype,'') = '' select @costtypeout = null
---- if @costtype is not null, check to see if alpha and convert to numeric. may be null
--if isnull(@costtype,'') <> '' 
--	begin
--	/* CostType input not null */
--	if isnumeric(@costtype) = 1
--		begin
--		select @costtypeout = @costtype
--		end
--	else
--		begin
--		/* CostType input not numeric, needs switcheroo */
--		select @costtypeout = CostType
--		from EMCT with (nolock)
--		where EMGroup = @emgroup and CostType=(select min(e.CostType) from bEMCT e where e.EMGroup=@emgroup 
--											and e.Abbreviation like @costtype + '%')
--		if @@rowcount = 0
--			begin
--			select @msg = 'EM Cost Type not on file.', @rcode = 1
--			goto bspexit
--			end
--		end
--   	end
   
/* ****************************************** */
/* Replace GLTransAcct from Equip validation with acct from EMDO or EMDG if it exists */
/* ****************************************** */
/* Get Department for @equipment from bEMEM. */
select @department = Department 
from bEMEM with (nolock) 
where EMCo = @emco and Equipment = @equipment

/* If GLAcct exists in bEMDO use it, else get it from EMDG */ 
select @GLTransAcct = GLAcct 
from bEMDO with (nolock) 
where EMCo = @emco and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostCode = @costcode
if isnull(@GLTransAcct, '') = ''
	begin
	select @GLTransAcct = GLAcct 
	from bEMDG with (nolock) 
	where EMCo = @emco and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostType = @costtype
	end

/* Original GLTransAcct may have been provided by Equipment validation.  If however user has modified
   either the CostCode or CostType since defaulting from Equipment then GLTransAcct may be different.
   If we have found an override acct use it otherwise send back the acct from the original Equip val. */   
if @GLTransAcct is not null
	select @GLTransAcctOut = @GLTransAcct
else
	select @GLTransAcctOut = @GLTransAcctIn
   
/* **Removed.  A Missing GLTransAcct should be caught when record is about to be saved.**
   Reject only if CostType has been passed in AND GLTransAcct cannot be found in either
   EMDO or EMDG.  An error is not appropriate when user has not yet entered CostType value
   on the form. (On some forms, CostType input preceeds CostCode input.) */
--if @GLTransAcctOut is null and @costtype is not null
--	begin
--	select @msg = 'GL Trans Acct is missing.', @rcode = 1
--	goto bspexit
--	end
   
bspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMCostCodeValForFuelPosting]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCostCodeValForFuelPosting] TO [public]
GO
