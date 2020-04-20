SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQCompliGroupVal    Script Date: 8/28/99 9:34:49 AM ******/
   CREATE  procedure [dbo].[bspHQCompliGroupVal]
   /*************************************
   * Created: SE 5/30/97
   * Revised: SE 5/30/97
   *
   *
   * validates HQ Compliance Group
   *
   * Pass:
   *	Compliance Code to be validated
   *
   * Success returns:
   *	0 and Description from bHQCG
   *
   * Error returns:
   *	1 and error message
   ************************************/
   	(@CompGroup varchar(10) = null, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @CompGroup is null
   	begin
   	select @msg = 'Missing compliance group', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bHQCG where CompGroup= @CompGroup
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid compliance group.', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQCompliGroupVal] TO [public]
GO
