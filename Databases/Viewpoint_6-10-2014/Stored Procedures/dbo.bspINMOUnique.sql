SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspINMOUnique    Script Date: 8/6/2003 3:33:54 PM ******/
   CREATE   proc [dbo].[bspINMOUnique]
   /***********************************************************
    * CREATED BY	: DC 8/6/03 - #21248 - Problems: F4 @ MO, validation at Job
    * MODIFIED BY	: 
    *                                 
    *
    * USAGE:
    * validates MO to insure that it is unique.  Checks INMO
    *
    * INPUT PARAMETERS
    *   INCo      IN Co to validate against
    *   MO        MO to Validate
    *   Action    Action that this mo is in
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Location
    * RETURN VALUE
    *   0         success
    *   1         Failure  'if Fails Address, City, State and Zip are ''
    *****************************************************/
   
       (@inco bCompany = 0, @mo varchar(10), @action varchar(1), @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0, @msg = 'IN Material Order Unique'
   
   if @action = 'A'
   	Begin
   		select @rcode=1, @msg= 'IN Material Order ' + @mo + ' already Exists'  
		from dbo.INMO with (nolock)
   		where INCo=@inco and MO=@mo
   	END
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOUnique] TO [public]
GO
