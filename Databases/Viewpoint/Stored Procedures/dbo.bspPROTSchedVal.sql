SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPROTSchedVal    Script Date: 8/28/99 9:33:32 AM ******/
   CREATE  proc [dbo].[bspPROTSchedVal]
    /***********************************************************
     *
     * MODIFIED By : EN 10/8/02 - issue 18877 change double quotes to single
     *
     *****************************************************/
   	(@prco bCompany = 0, @otsched tinyint = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @otsched is null
   	begin
   	select @msg = 'Missing OT Schedule!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   	from PROT
   	where PRCo = @prco and OTSched = @otsched 
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Overtime Schedule not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPROTSchedVal] TO [public]
GO
