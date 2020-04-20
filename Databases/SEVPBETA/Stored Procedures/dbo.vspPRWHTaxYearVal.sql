SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRWHTaxYearVal    Script Date: 8/28/99 9:35:43 AM ******/
   CREATE  procedure [dbo].[vspPRWHTaxYearVal]
   /************************************************************
    * CREATED BY: 	 EN 11/22/98
    * MODIFIED By : EN 11/22/98
    *					EN 10/9/02 - issue 18877 change double quotes to single
	*				mh 10/26/06 - We were passing in an empty string to tell the proc to 
	*								just validate the TaxYear.  6.x code will not allow us
	*								to pass in an empty string as a parameter.  Changed to "X"
	*				mh 11/21/06 - See issue 123178 - Split out general failure conditions, such as 
	*								missing parameters or invalid format from validation failures.
	*								Added output parameter @isTaxYearInit.  If TaxYear has been 
	*								been prev initialized will return "Y".  Leaving the return code
    *								for missing parameters or invalid format.  Also corrected the 
	*								tax year range check.
	*				EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
    *
    * USAGE:
    * If option to initialize W2 run is being used, validate that year
    * entered is not already set up in PRWH for the company, or ...
    * If option to re-create W2 run is being used or no option is selected,
    * validate that year entered is set up in PRWH for the company, or ...
    * If no option is selected, just validate the year.
    *
    * INPUT PARAMETERS
    *   @PRCo       PR Co
    *   @Opt	 'I' to Initialize W2 run, 'R' to Re-create, 'X' to just validate year  Obsolete - mh
    *   @TaxYear    Year to validate
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    ************************************************************/
   	@PRCo bCompany, @TaxYear varchar(4), @isTaxYearInit bYN output, @isFedInit bYN output, 
	@isStateInit bYN output, @isLocalInit bYN output, @coname varchar(60) output,
	@locaddress varchar(22) output, @deladdress varchar(40) output, @city varchar(22) output, @state varchar(4) output, 
	@zip varchar(5) output, @fedtaxid varchar(12) output, @errmsg varchar(255) output

   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @isTaxYearInit = 'N', @isFedInit = 'N', @isStateInit = 'N'
   
	if @PRCo is null 
	begin
		select @errmsg = 'Missing PR Company.', @rcode = 1
		goto vspexit
	end

	if isnumeric(@TaxYear) = 0
	begin
		select @errmsg = 'Invalid Tax Year.  Tax Year must be numeric', @rcode = 1
		goto vspexit
	end

	if not (convert(int, @TaxYear) >= 1000 and  convert(int, @TaxYear) <= 9999)
    begin
	   	select @errmsg = 'Invalid year.', @rcode = 1
   		goto vspexit
   	end

	--Return HQCO info to use as defaults on new PRWH record.
	select @coname = Name, @locaddress = Address2, @deladdress = Address, @city = City, 
	@state = State, @zip = Zip, @fedtaxid = replace(FedTaxId, '-', '') 
	from HQCO where HQCo = @PRCo

	--Using the existance of PRWI to determine if a TaxYear has been initialized.
	if exists(select 1 from PRWH where PRCo = @PRCo and TaxYear = @TaxYear) and exists(select 1 from PRWI where TaxYear = @TaxYear) and
	exists(select 1 from PRWT where PRCo = @PRCo and TaxYear = @TaxYear) and exists(Select 1 from PRWC where PRCo = @PRCo and TaxYear = @TaxYear)
	begin
		select @isTaxYearInit = 'Y'
	end

	if exists(select 1 from PRWA where PRCo = @PRCo and TaxYear = @TaxYear) 
	begin
		select @isFedInit = 'Y'
	end

	if exists(select 1 from PRWS where PRCo = @PRCo and TaxYear = @TaxYear) 
	begin
		select @isStateInit = 'Y'
	end

	if exists(select 1 from PRWL where PRCo = @PRCo and TaxYear = @TaxYear)
	begin
		select @isLocalInit = 'Y'
	end

   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRWHTaxYearVal] TO [public]
GO
