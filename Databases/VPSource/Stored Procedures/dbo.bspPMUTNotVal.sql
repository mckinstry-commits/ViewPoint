SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMUTNotVal    Script Date: 8/28/99 9:33:07 AM ******/
   CREATE    proc [dbo].[bspPMUTNotVal]
   /*************************************
   * validates PM Import Template is not found
   *
   * Pass:
   *	PM Import Template
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@template varchar(10) = null, @msg varchar(60) output)
   as 
   set nocount on
   
   declare @rcode int, @description bDesc
   
   select @rcode = 0
   	
   if @template is null
   	begin
   	select @msg = 'Missing Import Template', @rcode = 1
   	goto bspexit
   	end
   
   select @description=Description from bPMUT with (nolock) where Template = @template
   if @@rowcount = 0 
   	begin
   	select @msg = '', @rcode=0
   	goto bspexit
   	end
   else
   	begin
   	select @msg = 'Template ' + isnull(@description,'') + ' already set-up.', @rcode = 1
   
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMUTNotVal] TO [public]
GO
