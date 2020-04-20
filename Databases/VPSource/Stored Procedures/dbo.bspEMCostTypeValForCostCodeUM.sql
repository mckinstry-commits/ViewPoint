SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCostTypeValForCostCodeUM    Script Date: 8/28/99 9:34:26 AM ******/
   CREATE   proc [dbo].[bspEMCostTypeValForCostCodeUM]
   
   /***********************************************************
    * CREATED BY: kb 10/1/99
    * MODIFIED By :RM 02/28/01 - Changed Cost type to varchar(10)
    *		 TJL 08/14/01 - Added mod to check for UM, first in bEMCH, then in bEMCX:  Issue# 11672
    *		TV 02/11/04 - 23061 added isnulls	
    * USAGE:
    *	This routine calls bspEMCostTypeValForCostCode but then also returns UM
    *
    * 	An error is returned if any of the following occurs:
    * 		EMCo, EMGroup, CostType, CostCode, or Equipment not passed.
    *		Cost Type not found in EMCT or not linked to passed CostCode in EMCX.
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
   @costtype varchar(10) = null,
   @costcode bCostCode = null,
   @equipment bEquip=null,
   @costtypeout bEMCType output,
   @gltransacct bGLAcct output,
   @um bUM output,
   @msg varchar(255) output)
   
   as
   set nocount on
   
   declare @department bDept, @numrows int, @rcode int
   
   select @rcode = 0, @numrows = 0
   
   exec @rcode = bspEMCostTypeValForCostCode @emco, @emgroup, @costtype, @costcode, @equipment, 'N',
   				@costtypeout output, @gltransacct output, @msg output
   if @rcode = 1 goto bspexit
   
   -- Get UM based on EMCH and EMCX 
   select @um = UM from bEMCH with (nolock)
   where EMCo = @emco and Equipment = @equipment and EMGroup = @emgroup
   and CostCode = @costcode and CostType = @costtypeout
   if @@rowcount = 0
   	begin
   	select @um = UM from EMCX with (nolock)
   	where EMGroup = @emgroup  and CostCode = @costcode and CostType = @costtypeout
   	end
   
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMCostTypeValForCostCodeUM]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCostTypeValForCostCodeUM] TO [public]
GO
