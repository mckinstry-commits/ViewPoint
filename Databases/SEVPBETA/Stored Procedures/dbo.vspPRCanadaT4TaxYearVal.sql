SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspPRCanadaT4TaxYearVal]
	/******************************************************
	* CREATED BY:	MarkH 
	* MODIFIED By:	CHS 11/27/2012 B-11847 TK-19654 add contact email address
	*
	* Usage:
	*	
	*
	* Input params:
	*
	*	@prco	-	Payroll Company
	*	@taxyear	TaxYear
	*	
	*
	* Output params:
	*	@tn		-	Transmitter Number
	*	@rppnumber - RPP Number
	*	@contact	Contact Name
	*	@phone	-	Contact Phone Number
	*	@ext	-	Contact Phone Extension
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany, @taxyear char(4), @tn varchar(6) output, @rppnumber varchar(7) output, @contact varchar(22) output, 
	@phone varchar(15) output, @ext varchar(5) output, @ownersin varchar(9) output, @coownersin varchar(9) output, 
	@email varchar(60) output, @msg varchar(100) output)

	as 
	set nocount on
	declare @rcode int, @prevtaxyear smallint
   	
	select @rcode = 0

	if @prco is null
	begin
		select @msg = 'Missing Payroll Company.', @rcode = 1
		goto vspexit
	end

	if @taxyear is null
	begin
		select @taxyear = 'Missing Tax Year.', @rcode = 1
		goto vspexit
	end

	if isnumeric(@taxyear) <> 1
	begin
		select @msg = 'Tax Year must be numeric', @rcode = 1
		goto vspexit
	end

	select @prevtaxyear = (convert(smallint, @taxyear) - 1)

	select @tn = TransmitterNumber, @rppnumber = RPPNumber, @contact = ContactName, @phone = ContactPhone, 
	@ext = ContactPhoneExt, @ownersin = OwnerSIN, @coownersin = CoOwnerSIN, @email = ContactEmail
	from PRCAEmployer where PRCo = @prco and TaxYear = convert(varchar(4), @prevtaxyear)
	 
	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRCanadaT4TaxYearVal] TO [public]
GO
