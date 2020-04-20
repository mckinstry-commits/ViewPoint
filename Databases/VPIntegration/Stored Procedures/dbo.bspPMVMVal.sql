SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMVMVal    Script Date:  ******/
   CREATE  proc [dbo].[bspPMVMVal]
   /*************************************
    * Created By:	GF 03/31/2004
    * Modified By:
    *
    *
    *
    * validates PM Document Tracking View
    *
    * Pass:
    * PM View Name
    *
    *
    * Success returns:
    *	0 and View Description
    *
    * Error returns:
    *	1 and error message
    **************************************/
   (@viewname varchar(10) = null, @msg varchar(255) output)
   as 
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- validate View Name
   select @msg=Description from PMVM with (nolock) where ViewName=@viewname
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid Document Tracking View: ' + isnull(@viewname,'') + ' !', @rcode = 1
   	goto bspexit
   	end
   
   
   
   
   bspexit:
   	if @rcode<>0 select @msg = isnull(@msg,'')
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMVMVal] TO [public]
GO
