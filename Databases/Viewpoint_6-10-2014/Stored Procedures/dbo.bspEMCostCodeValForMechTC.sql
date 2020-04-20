SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCostCodeValForMechTC    Script Date: 8/28/99 9:34:26 AM ******/
   CREATE     proc [dbo].[bspEMCostCodeValForMechTC]
   /***********************************************************
    * CREATED BY: 	 EN 2/6/04 23652 based on bspEMCostTypeCostCodeVal except returns costcode description
    * MODIFIED By : RM 02/28/01 - Changed Cost Type to varchar(10)
    *				TV 02/11/04 - 23061 added isnulls
    * USAGE:
    * 	Validates EM Cost Type against bEMCT and then verifies
    *	that the CT is linked to the passed CostCode in EMCX.
    *
    * INPUT PARAMETERS
    *	EMCo
    *  EMGroup
    * 	CostType
    *	CostCode
    *
    * OUTPUT PARAMETERS
    *	@costtypeout		numeric cost type
    *   	@msg      		Error message if error occurs otherwise Cost Code Description returned
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
   if @costcode is null
   	begin
   	select @msg = 'Missing Cost Code!', @rcode = 1
   	goto bspexit
   	end
   
   -- get cost code description
   select @msg = Description
   from EMCC
   where EMGroup = @emgroup and CostCode = @costcode
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid Cost Code!', @rcode = 1
   	goto bspexit
   	end
   
   -- If @costtype is numeric then try to find
   if isnumeric(@costtype) = 1
   	begin
   	select @costtypeout = CostType
   	from EMCT with (nolock)
   	where EMGroup = @emgroup and CostType = convert(int,@costtype)
   	end
   
   -- if not numeric or not found try to find as Sort Name
   if @@rowcount = 0
   	begin
       select @costtypeout = CostType
   	from EMCT with (nolock)
   	where EMGroup = @emgroup and CostType=(select min(e.CostType)from bEMCT e where e.EMGroup=@emgroup
                                				and e.Abbreviation like @costtype + '%')
   	if @@rowcount = 0
   		begin
   		select @msg = 'EM Cost Type not on file!', @rcode = 1
   		goto bspexit
   		end
    	end
   
   -- make sure cost type is valid in Cost Code grid
   if (select count(*) from EMCX with (nolock) where EMGroup=@emgroup and CostType=@costtypeout and CostCode=@costcode)=0
   	begin
   	select @msg = 'Cost Type not linked to CostCode!', @rcode = 1
   	goto bspexit
   	end
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMCostCodeValForMechTC]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCostCodeValForMechTC] TO [public]
GO
