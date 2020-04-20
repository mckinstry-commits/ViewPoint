SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRCodeTypeVal    Script Date: 2/4/2003 6:50:55 AM ******/
   /****** Object:  Stored Procedure dbo.bspHRCodeTypeVal    Script Date: 8/28/99 9:32:50 AM ******/
   CREATE   procedure [dbo].[bspHRCodeTypeVal]
   /*************************************
   * validates HR Codes
   *
   * created by: kb 3/18/2
   *
   * Pass:
   *	HRCo - Human Resources Company
   *   Code - Code to be Validated
   *   Type - Type to be Validated
   *
   * Success returns:
   *	0 and Description
   *
   * Error returns:
   *	1 and error message
   **************************************/
    (@Type char(1), @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int, @Codetype char(1)
      	select @rcode = 0
   
   
   if @Type is null
   	begin
   	select @msg = 'Missing Type', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from HRCT where Type = @Type
   if @@rowcount = 0
       begin
   	select @msg = 'Not a valid HR Code Type.', @rcode = 1
       goto bspexit
       end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCodeTypeVal] TO [public]
GO
