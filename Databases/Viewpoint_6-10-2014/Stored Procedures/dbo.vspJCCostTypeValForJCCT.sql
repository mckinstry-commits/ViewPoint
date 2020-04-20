SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.[vspJCCostTypeValForJCCT]    Script Date: 3/27/2002 9:32:13 AM ******/
   
   CREATE PROC [dbo].[vspJCCostTypeValForJCCT]
   /***********************************************************
    * CREATED BY: DANF 06/03/07
    * MODIFIED By : 
	*
    * USAGE:
    * validates JC Cost Type
    * an error is returned if any of the following occurs
    * not Cost Type passed, no Cost Type found.
    *
    * INPUT PARAMETERS
    *   PhaseGroup
    *   CostType
    *
    * OUTPUT PARAMETERS
    *   @desc     Description for grid
    *   @msg      error message if error occurs otherwise Description returned
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@phasegroup tinyint = null, @costtype varchar(10) = null, @costtypeout bJCCType = null output,
      @desc varchar(60) output, @msg varchar(60) output)
   as
   set nocount on
   	declare @rcode int, @rcount int
   	select @rcode = 0
   	select @msg = ''
   if @phasegroup is null
   	begin
   	select @msg = 'Missing Phase Group!', @rcode = 1
   	goto bspexit
   
   	end
   
   if @costtype is null
   	begin
   	select @msg = 'Missing Cost Type!', @rcode = 1
   	goto bspexit
   	end
   
   /* If @costtype is numeric then try to find*/
   if dbo.bfIsInteger(@costtype) = 1 and len(@costtype) < 4
           begin
				if convert(numeric(3,0),@costtype) <0 or convert(numeric(3,0),@costtype)>255
					begin
   					select @msg = 'CostType must be between 0 and 255.', @rcode = 1
   					goto bspexit
					end

   				select @costtypeout = CostType, @desc = Abbreviation, @msg = Description
   				from JCCT
   				where PhaseGroup = @phasegroup and CostType = convert(int,convert(float, @costtype))

           end
   
   /* if not numeric or not found try to find as Sort Name */
   if isnull(@costtypeout,'') = ''
   	begin
       	select @costtypeout = CostType, @desc = Abbreviation, @msg = Description
   		from JCCT
   		where PhaseGroup = @phasegroup and CostType=(select min(j.CostType)
                 from bJCCT j where j.PhaseGroup=@phasegroup
                                and j.Abbreviation like @costtype + '%')
   		if @@rowcount = 0
   			begin
					if dbo.bfIsInteger(@costtype) = 1 and len(@costtype) < 4
						   select @costtypeout = @costtype
   	    			else
						   select @costtypeout = null
   			end
      	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCostTypeValForJCCT] TO [public]
GO
