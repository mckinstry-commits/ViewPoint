SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRResInGridVal    Script Date: 2/4/2003 7:48:24 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspHRResInGridVal    Script Date: 8/28/99 9:32:53 AM ******/
   CREATE  procedure [dbo].[bspHRResInGridVal]
   /*************************************
   * validates HR Resources
   *
   * Pass:
   *   HRCo - Human Resources Company
   *   HRRef - Resource ID to be Validated
   *bspHRResInGridVal   
   *
   * Success returns:
   *   Concatinated:  LastName, FirstName, MiddleName
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@HRCo bCompany = null, @HRRef varchar(15), @msg varchar(75) output)
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
   
   if isnumeric(@HRRef) = 1 
   	
   	begin
   	select @msg = LastName+', '+FirstName+', '+MiddleName
   	from HRRM 
   	where HRCo = @HRCo and HRRef = convert(int,@HRRef)
   	end
   	
   /* If not found, try to find as Sort Name */
   	if @@rowcount = 0
   		begin
   		select @msg = LastName+', '+FirstName+', '+MiddleName
   	  	from HRRM 
   		where HRCo = @HRCo and SortName = @HRRef
   
   /* If not found, try to find closest */
   	if @@rowcount = 0
   		begin
   		select @msg = LastName+', '+FirstName+', '+MiddleName
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
GRANT EXECUTE ON  [dbo].[bspHRResInGridVal] TO [public]
GO
