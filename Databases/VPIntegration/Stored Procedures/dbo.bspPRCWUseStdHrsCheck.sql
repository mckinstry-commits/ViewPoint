SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCWUseStdHrsCheck    Script Date: 2/23/04 9:33:19 AM ******/
    CREATE            proc [dbo].[bspPRCWUseStdHrsCheck]
    
    /***********************************************************
     * CREATED BY: EN 2/25/04
     * MODIFIED By :  MH 126252 - Added @usestdhrs parameter.  Removed val check of @employee
     *
     * Usage:
     *	Checks for multiple occurances of UseStdHrs = 'Y' for the 
     * same employee in PRCW.
     *
     * Input params:
     *	@prco		PR company
     *	@crew		Crew code
     *	@seq		PRCR Seq #
     * @employee	Employee
     *
     * Output params:
     *	@msg		Employee Name or error message
     *
     * Return code:
     *	0 = success, 1 = failure
     ************************************************************/
    (@prco bCompany, @crew varchar(10), @seq smallint, @employee bEmployee, @usestdhrs bYN,
     @msg varchar(90) output)
    
    as
    set nocount on
    
    declare @rcode int, @numrows int
    
    select @rcode = 0
    
    /* check required input params */
     -- validate PRCo
     if @prco is null
     	begin
     	select @msg = 'Missing PR Co#!', @rcode = 1
     	goto bspexit
     	end
     -- validate Crew
     if @crew is null
     	begin
     	select @msg = 'Missing Crew!', @rcode = 1
     	goto bspexit
     	end
     -- validate Seq
     if @seq is null
     	begin
     	select @msg = 'Missing Sequence #!', @rcode = 1
     	goto bspexit
     	end

	--126252 - only need to check for multiple occurances if employee supplied.  If not employee
	--assume this is an equipment entry and let fall through.
     -- validate Employee
--     if @employee is null
--     begin
--     	select @msg = 'Missing Employee!', @rcode = 1
--     	goto bspexit
--     end

		if @employee is not null
		begin
			if @usestdhrs = 'Y' --126252 only need to check for multiple occurances if @usestdhrs = "Y"
			begin
				-- check for multiple occurrances
				select @numrows=count(1) from dbo.bPRCW with (nolock)
				where PRCo=@prco and Crew=@crew and Employee=@employee and Seq<>@seq and UseStdHrs='Y'
				if @numrows>0 select @msg='Warning -- This employee is already set up to use standard hours.', @rcode=1
			end
		end
   
    bspexit:
    
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCWUseStdHrsCheck] TO [public]
GO
