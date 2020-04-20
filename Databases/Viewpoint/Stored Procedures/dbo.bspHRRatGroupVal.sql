SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRRatGroupVal    Script Date: 2/4/2003 7:45:45 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspHRRatGroupVal    Script Date: 8/28/99 9:32:52 AM ******/
   CREATE  procedure [dbo].[bspHRRatGroupVal]
   /*************************************
   * validates HR Rating Groups
   *
   * Pass:
   *	HRCo - Human Resources Company
   *   RatGroup - Rating Group
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@HRCo bCompany = null, @RatGroup varchar(10), @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int
      	select @rcode = 0
   
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @RatGroup is null
   	begin
   	select @msg = 'Missing Rating Code', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from HRRG where HRCo = @HRCo and RatingGroup = @RatGroup
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Rating Group', @rcode = 1
           goto bspexit
         	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRRatGroupVal] TO [public]
GO
