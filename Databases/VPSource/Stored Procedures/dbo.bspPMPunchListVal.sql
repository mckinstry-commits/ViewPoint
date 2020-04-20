SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPunchListVal    Script Date: 8/28/99 9:35:18 AM ******/
   CREATE   proc [dbo].[bspPMPunchListVal]
   /****************************************
   *  validate Punch List
   *
   *  Pass the Punch List value
   *
   *  Success returns:
   *	0 and Description from PMPU
   *
   *  Error returns:
   *	1 and an error message
   *****************************************/
   
   (@project bProject, @punchlist bDocument, @msg varchar(60) output)
   
   as
   
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @punchlist is null
   	begin
   	select @msg = 'Missing PunchList',@rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bPMPU with (nolock) where Project = @project and PunchList = @punchlist
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Punchlist for this project', @rcode = 1
   		end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPunchListVal] TO [public]
GO
