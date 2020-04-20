SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRResourceAddress    Script Date: 2/4/2003 7:50:03 AM ******/
   
   
   /****** Object:  Stored Procedure dbo.bspHRResourceAddress    Script Date: 8/28/99 9:32:54 AM ******/
   CREATE     procedure [dbo].[bspHRResourceAddress]
   /*************************************
   * validates HR Resources
   *
   *	Created by: 
   *	Modified by: kb 8/5/2 - issue #17868
   *				mh 6/9/04 24736
   *				mh 01/05/08	131574 - Country needs to be included as output param.
   * Pass:
   *   HRCo - Human Resources Company
   *   HRRef - Resource ID to be Validated
   *
   *
   * Success returns:
   *   Concatinated:  LastName, FirstName, MiddleName
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@HRCo bCompany = null, @HRRef varchar(15), @Address varchar(60) output, @City varchar(30) output,
   	 @State bState output, @Zip bZip output, @phone bPhone output, @country char(2) output,
   	@RefOut int output, @msg varchar(75) output)
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
   	if len(@HRRef) < 7
   	begin
   		select @Address = Address, @City = City, @State = State, @Zip = Zip, @phone = Phone,
   		@msg = LastName+', '+FirstName+', '+isnull(MiddleName, ''), @RefOut = HRRef, @country = Country
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
   
   		select @Address = Address, @City = City, @State = State, @Zip = Zip, 
   		  @phone = Phone, @msg = LastName+', '+FirstName+', '+isnull(MiddleName, ''), 
   		  @RefOut = HRRef, @country = Country
   		from HRRM
   		where HRCo = @HRCo and SortName = @HRRef
   
   /* If not found, try to find closest */
   	if @@rowcount = 0
   		begin
   		select @Address = Address, @City = City, @State = State, @Zip = Zip, 
   		  @phone = Phone, @msg = LastName+', '+FirstName+', '+isnull(MiddleName, ''), 
   		  @RefOut = HRRef, @country = Country
   		from HRRM
   		where HRCo = @HRCo and SortName like @HRRef + '%'
   		if @@rowcount = 0
   			begin
   			select @msg = 'Not a valid HR Resource Number', @rcode = 1
   			goto bspexit
   			end
   		end
   
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRResourceAddress] TO [public]
GO
