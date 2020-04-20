SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCostTypeCostCodeVal    Script Date: 8/28/99 9:34:26 AM ******/
CREATE    proc [dbo].[bspEMCostTypeCostCodeVal]
/***********************************************************
* CREATED BY: 	 bc 01/21/98
* MODIFIED By : RM 02/28/01 - Changed Cost Type to varchar(10)
*				TV 02/11/04 - 23061 added isnulls	
*		TJL 01/29/09 - Issue #130083, EM CostType no longer clears on F3 default if CostCode missing.
*
* USAGE:
* 	Validates EM Cost Type against bEMCT and then verifies
*	that the CT is linked to the passed CostCode in EMCX.
*
* INPUT PARAMETERS
*	EMCo
*   	EMGroup
*   	CostType
*	CostCode
*
* OUTPUT PARAMETERS
*	@costtypeout		numeric cost type
*   	@msg      		Error message if error occurs otherwise Description returned
*
* RETURN VALUE
*   	0         	Success
*   	1         	Failure
*****************************************************/

(@emgroup bGroup = null, @costcode bCostCode = null,
@costtype varchar(10) = null, @costtypeout bEMCType = null output, @msg varchar(255) output)

as
set nocount on
   
declare @rcode int

select @rcode = 0

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
--begin
--select @msg = 'Missing Cost Code!', @rcode = 1
--goto bspexit
--end
   
-- If @costtype is numeric then try to find
if isnumeric(@costtype) = 1
   	begin
   	select @costtypeout = CostType, @msg = Description
   	from EMCT with (nolock)
   	where EMGroup = @emgroup and CostType = convert(int,@costtype)
   	end
   
-- if not numeric or not found try to find as Sort Name
if @@rowcount = 0
   	begin
	select @costtypeout = CostType, @msg = Description
   	from EMCT with (nolock)
   	where EMGroup = @emgroup and CostType=(select min(e.CostType)from bEMCT e where e.EMGroup=@emgroup
                                				and e.Abbreviation like @costtype + '%')
   	if @@rowcount = 0
   		begin
   		select @msg = 'EM Cost Type not on file!', @rcode = 1
   		goto bspexit
   		end
	end

 /* Issue #130083: CONTINUE WITH ADDITIONAL CHECKS BASED UPON A VALID COSTCODE, AND COSTTYPE */
-- Inputs for @costcode get tested here rather than at beginning of procedure to allow 
-- CostType switcheroo to do its job first.  In this way user can F3 a CostType without
-- also having to F3 CostCode.  
if @costcode is null
	begin
	select @msg = 'Missing Cost Code!', @rcode = 1
	goto bspexit
	end
   
-- make sure cost type is valid in Cost Code grid
if (select count(*) from EMCX with (nolock) where EMGroup=@emgroup and CostType=@costtypeout and CostCode=@costcode)=0
   	begin
   	select @msg = 'Cost Type not linked to CostCode!', @rcode = 1
   	goto bspexit
   	end
   
bspexit:
if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMCostTypeCostCodeVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCostTypeCostCodeVal] TO [public]
GO
