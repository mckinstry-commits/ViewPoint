SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE  procedure [dbo].[bspHRHospVal]
   /*************************************
	*
	* Created By/On ????
	* Modified 08/19/2009 - MarkH 135049 changed @Hosp to varchar(60) from varchar(20)
	* validates HR Resources
	
   *
   * Pass:
   *   HRCo - Human Resources Company
   *   Hosp - Hospital to be Validated
   *bspHRHospVal
   *
   * Success returns:
   *   Concatinated:  LastName, FirstName, MiddleName
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@HRCo bCompany = null, @Hosp varchar(60), @msg varchar(75) output)
   as
   	set nocount on
   	declare @rcode int
      	select @rcode = 0
   
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @Hosp is null
   	begin
   	select @msg = 'Missing Hospital', @rcode = 1
   	goto bspexit
   	end
   
   
   select @msg = Hospital
   from HRHI
   where HRCo = @HRCo and Hospital = @Hosp
   if @@rowcount = 0
    begin
    select @msg = 'Invalid Hospital Name', @rcode = 1
    goto bspexit
    end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRHospVal] TO [public]
GO
