SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRPositionVal    Script Date: 2/4/2003 7:44:55 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspHRPositionVal    Script Date: 8/28/99 9:32:52 AM ******/
   CREATE  procedure [dbo].[bspHRPositionVal]
   /*************************************
   * validates HR Position Codes
   *
   * Pass:
   *	HRCo - Human Resources Company
   *   PositionCode - Code to be Validated
   *
   * Success returns:
   *	Description
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@HRCo bCompany = null, @Code varchar(10), @msg varchar(60) output)
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
   	select @msg = 'Missing Position Code', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = JobTitle from HRPC where HRCo = @HRCo and PositionCode = @Code
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Position Code', @rcode = 1
           goto bspexit
         	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRPositionVal] TO [public]
GO
