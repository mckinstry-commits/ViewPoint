SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRResVal    Script Date: 2/4/2003 7:49:20 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspHRResVal    Script Date: 8/28/99 9:32:53 AM ******/
   CREATE      procedure [dbo].[bspHRResVal]
   /*************************************
   * validates HR Resources
   *
   *  Created by: ????
   *  Modified:  mh 24736 6/9/04
   *
   *
   * Pass:
   *   HRCo - Human Resources Company
   *   HRRef - Resource ID to be Validated
   *bspHRResVal   
   *
   * Success returns:
   *   Concatinated:  LastName, FirstName, MiddleName
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@HRCo bCompany = null, @HRRef varchar(15), @RefOut int output, @position varchar(10) output, @msg varchar(75) output)
   as
   	set nocount on
   	declare @rcode int
      	select @rcode = 0
 
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @HRRef is null
   	begin
   	select @msg = 'Missing HR Resource Number', @rcode = 1
   	goto bspexit
   	end
  
   /* If @HRRef is numeric then try to find resource number*/
   
   --if isnumeric(@HRRef) = 1 
   --24736 Added call to function and check for len @HRRef
   	if dbo.bfIsInteger(@HRRef) = 1
   	begin
		print 'HRRef is numeric'
   		if len(@HRRef) < 7
   		begin
			print 'HRRef is less then 7 characters'
   			select @msg = isnull(LastName, '') + ', ' + isnull(FirstName, '') + ', ' + isnull(MiddleName, ''), 
   			@RefOut = HRRef, @position = PositionCode
   			from HRRM 
   			where HRCo = @HRCo and HRRef = convert(int,@HRRef)

   			select isnull(LastName, '') + ', ' + isnull(FirstName, '') + ', ' + isnull(MiddleName, ''), 
   			HRRef, PositionCode
   			from HRRM 
   			where HRCo = @HRCo and HRRef = convert(int,@HRRef)
   		end
   		else
   		begin
   			select @msg = 'Invalid HR Resource Number, length must be 6 digits or less.', @rcode = 1
   			goto bspexit
   		end
   	end

   /* If not found, try to find as Sort Name */
   	if @@rowcount = 0
   		begin
   		select @msg = isnull(LastName, '') + ', ' + isnull(FirstName, '') + ', ' + isnull(MiddleName, ''), 
   		@RefOut = HRRef, @position = PositionCode
   	  	from HRRM 
   		where HRCo = @HRCo and SortName = @HRRef
   
   /* If not found, try to find closest */
   	if @@rowcount = 0
   		begin
   		select @msg = isnull(LastName, '') + ', ' + isnull(FirstName, '') + ', ' + isnull(MiddleName, ''), 
   		@RefOut = HRRef, @position = PositionCode
   		from HRRM
   		where HRCo = @HRCo and SortName like @HRRef + '%'
   		if @@rowcount = 0
   			begin
   			select @msg = 'Not a valid HR Resource Number', @rcode = 1
   			goto bspexit
   			end
   		end
   		end
   
   select @RefOut = convert(int, @RefOut)			
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRResVal] TO [public]
GO
