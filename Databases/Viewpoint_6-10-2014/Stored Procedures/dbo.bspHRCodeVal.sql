SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRCodeVal    Script Date: 4/29/2002 10:50:32 AM ******/
   /****** Object:  Stored Procedure dbo.bspHRCodeVal    Script Date: 8/28/99 9:32:50 AM ******/
   CREATE    procedure [dbo].[bspHRCodeVal]
   /*************************************
   * validates HR Codes
   *
   *	Modified: allenn 03062002 - Issue 16381
   *
   *		Issue 15898 - A code may be assigned to mulitple types.  Original query to
   *		check code could return more then one result.  The last result would get 
   *		assigned to @CodeType which may cause validation to fail if Type passed in
   *		was not the last row returned by query.  In reviewing the current useage of
   *		this procedure we are passing in the type in each instance.  Changing validation
   *		to look at both Code and Type together as opposed to independently.  mh 4/29/02
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
    (@HRCo bCompany = null, @Code varchar(10), @Type char(1), @msg varchar(60) output)
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
   
   
   --Issue 15898
   --select @msg = Description, @Codetype = Type  from HRCM where HRCo = @HRCo and Code = @Code
   select @msg = Description from HRCM where HRCo = @HRCo and Code = @Code and Type = @Type
   if @@rowcount = 0
       begin
   	select @msg = 'Not a valid HR Code or Type.', @rcode = 1
       goto bspexit
       end
   
   /*
   if @Type <> @Codetype
       begin
       select @msg = 'Invalid HR Code Type. Must be Type ' + @Type + '.', @rcode = 1
       goto bspexit
       end
   */
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCodeVal] TO [public]
GO
