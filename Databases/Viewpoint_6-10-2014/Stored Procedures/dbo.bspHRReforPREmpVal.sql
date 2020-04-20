SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRReforPREmpVal    Script Date: 2/4/2003 7:47:07 AM ******/
   /****** Object:  Stored Procedure dbo.bspHRReforPREmpVal    Script Date: 8/28/99 9:32:53 AM ******/
   CREATE   proc [dbo].[bspHRReforPREmpVal]
   /***************************************************
   * CREATED BY    : kb 8/7/99
   * LAST MODIFIED : mh 6/4/03 FirstName and MiddleName in PREH and HRRM can be null 
   *							in PREH and HRRM.  Need to encapsulate those fields in 
   *							isnull() functions and return an empty string.
   *
   * Usage:
   *  Used by HR Update PR program to validate the employee# based on if it is a
   *   PR or HR # entered
   *
   * Input:
   *	@hrco         HR Company
   *	@prco	      PR Company
   *	@hrORprflag
   *	@employee#
   *
   * Output:
   *   @msg          Employees name
   *
   * Returns:
   *	0             success
   *   1             error
   *************************************************/
   (@hrco bCompany, @prco bCompany, @restrictEmployee bYN,
   @hrORprflag char(1),@empl varchar(15), @emplout bHRRef output,
   @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @restrictEmployee ='N' goto bspexit
   
   if @hrco is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   if @prco is null and @hrORprflag ='P'
   	begin
   	select @msg = 'Missing PR Company', @rcode = 1
   	goto bspexit
   	end
   if @empl is null
   	begin
   	select @msg = 'Employee #', @rcode = 1
   	goto bspexit
   	end
   
   if @hrORprflag='H'
   	begin
   	/* If @empl is numeric then try to find Employee number */
   	if isnumeric(@empl) = 1
   	  select @emplout = HRRef, @msg = isnull(FirstName, '') + ' ' + isnull(MiddleName, '') + ' ' + LastName
   	  from HRRM
   	  where HRCo=@hrco and HRRef = convert(int,convert(float, @empl))
   
   	/* if not numeric or not found try to find as Sort Name */
   	if @@rowcount = 0
   		begin
   	    	select @emplout = HRRef, @msg = isnull(FirstName, '') + ' ' + isnull(MiddleName, '') + ' ' + LastName
   		  from HRRM
   		  where HRCo=@hrco and SortName = @empl
   
   	 	/* if not found,  try to find closest */
   	   	if @@rowcount = 0
          			begin
           		set rowcount 1
   	        	select @emplout = HRRef, @msg = isnull(FirstName, '') + ' ' + isnull(MiddleName, '') + ' ' + LastName
   			  from HRRM
   			  where HRCo= @hrco and SortName like @empl + '%'
   			if @@rowcount = 0
    		  		begin
   	    			select @msg = 'Not a valid HR Ref#', @rcode = 1
   				goto bspexit
   	   			end
   			end
   		end
   	end
   
   if @hrORprflag='P'
   	begin
   	/* If @empl is numeric then try to find Employee number */
   	if isnumeric(@empl) = 1
   	  select @emplout = Employee, @msg = isnull(FirstName, '') + ' ' + isnull(MidName, '') + ' ' + LastName
   	  from PREH
   	  where PRCo=@prco and Employee= convert(int,convert(float, @empl))
   
   	/* if not numeric or not found try to find as Sort Name */
   	if @@rowcount = 0
   		begin
   	    	select @emplout = Employee, @msg = isnull(FirstName, '') + ' ' + isnull(MidName, '') + ' ' + LastName
   		  from PREH
   		  where PRCo=@prco and SortName = @empl
   
   	 	/* if not found,  try to find closest */
   	   	if @@rowcount = 0
          			begin
           		set rowcount 1
   	        	select @emplout = Employee, @msg = isnull(FirstName, '') + ' ' + isnull(MidName, '') + ' ' + LastName
   			  from PREH
   			  where PRCo= @prco and SortName like @empl + '%'
   			if @@rowcount = 0
    		  		begin
   	    			select @msg = 'Not a valid Employee', @rcode = 1
   				goto bspexit
   	   			end
   			end
   		end
   	if not exists(select * from HRRM where HRCo = @hrco and PRCo= @prco and PREmp = @emplout)
   		begin
   		select @msg = 'Employee not setup in HR.', @rcode = 1
   		goto bspexit
   		end
   	end
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRReforPREmpVal] TO [public]
GO
