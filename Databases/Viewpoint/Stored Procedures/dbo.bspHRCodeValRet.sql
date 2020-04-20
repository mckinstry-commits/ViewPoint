SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRCodeValRet    Script Date: 2/4/2003 6:52:06 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspHRCodeValRet    Script Date: 8/28/99 9:32:50 AM ******/
   CREATE   procedure [dbo].[bspHRCodeValRet]
   /*************************************
   * validates HR Codes
   *
   * Pass:
   *	HRCo - Human Resources Company
   *   Code - Code to be Validated
   *   Type - Type to be Validated
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@HRCo bCompany = null, @Code varchar(10), @Type char(1), @Desc varchar(60) output, @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int, @Codetype char(1)
      	select @rcode = 0
   
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @Code is null
   	begin
   	select @msg = 'Missing Code', @rcode = 1
   	goto bspexit
   	end
   
   if @Type is null
   	begin
   	select @msg = 'Missing Type', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @Desc = Description, @Codetype = Type  from HRCM where HRCo = @HRCo and Code = @Code
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid HR Code.', @rcode = 1
           goto bspexit
         	end
       if @Type <> @Codetype
           begin
           select @msg = 'Invalid HR Code Type. Must be Type ' + @Type + '.', @rcode = 1
           goto bspexit
           end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCodeValRet] TO [public]
GO
