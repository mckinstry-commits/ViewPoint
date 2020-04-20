SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRStatCodeVal    Script Date: 2/4/2003 7:53:39 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspHRStatCodeVal    Script Date: 8/28/99 9:32:55 AM ******/
   CREATE  procedure [dbo].[bspHRStatCodeVal]
   /*************************************
   * validates HR Codes
   *
   * Pass:
   *	HRCo - Company
   *   Code - Status Code to be Validated
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   
   	(@HRCo bCompany = null, @Code varchar(20), @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int
      	select @rcode = 0
   
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @Code is null
   	begin
   	select @msg = 'Missing Status Code', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from HRST where HRCo = @HRCo and StatusCode = @Code
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Status Code.', @rcode = 1
           goto bspexit
         	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRStatCodeVal] TO [public]
GO
