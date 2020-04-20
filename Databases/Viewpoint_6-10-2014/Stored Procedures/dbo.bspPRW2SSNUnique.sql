SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRW2SSNUnique    Script Date: 8/28/99 9:35:42 AM ******/
   
   CREATE  proc [dbo].[bspPRW2SSNUnique]
   /***********************************************************
    * CREATED BY	: EN 11/20/98
    * MODIFIED BY	: EN 11/20/98
    *					EN 10/9/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    *	Checks an Employee's SSN# for uniqueness within PRWE.
    *
    * INPUT PARAMETERS
    * 	 @prco      	PR Company
    *	 @taxyear	Tax Year
    *	 @empl      	Employee
    *	 @ssn		SSN #
    * 
    * OUTPUT PARAMETERS
    *   	@msg      	error message 
    *
    * RETURN VALUE
    *  	 0         		success
    *   	1        		failure
    *******************************************************************/ 
   
       (@prco bCompany = 0, @taxyear varchar(4), @empl bEmployee, @ssn varchar(9),
        @msg varchar(80) output )
	
	as
   
	set nocount on
   
	declare @rcode INT

	select @rcode = 0, @msg = 'PR Unique'
    
	select @rcode=1, @msg='Social Security # ' + @ssn + ' already used by employee# ' + convert(varchar(10), Employee) 
	from bPRWE where PRCo=@prco and TaxYear=@taxyear and SSN=@ssn and Employee<>@empl
   
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRW2SSNUnique] TO [public]
GO
