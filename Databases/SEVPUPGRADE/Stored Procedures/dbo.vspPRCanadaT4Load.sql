SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspPRCanadaT4Load]
	/******************************************************
	* CREATED BY:	MarkH 
	* MODIFIED By: 
	*
	* Usage:	Provide Company specific default information from HQCO.  
	*			Info will be the same regardless of TaxYear.
	*	
	*
	* Input params:
	*
	*		@PRCo - Payroll Company
	*
	* Output params:
	*
	*	@bn - Business Number from FedTaxID field.
	*	@name - Company Name
	*	@address - Company Address
	*	@city
	*	@state - 
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@prco bCompany, @bn varchar(15) output, @name varchar(30) output, @address varchar(30) output,
	@city varchar(28) output, @province varchar(4) output, @postalcode varchar(50) output, 
	@country varchar(2) output, @phone varchar(22) output, @msg varchar(100) output

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0
	 
	if @prco is null
	begin	
		select @msg = 'Missing PR Company!', @rcode = 1
		goto vspexit
	end

	select @bn = substring(FedTaxId,1, 15), @name = substring([Name], 1, 30), @address = substring([Address],1,30),
	@city = substring(City, 1, 28),	@province = [State], @postalcode = Zip, @country = Country, @phone = Phone 
	from HQCO (nolock) where HQCo = @prco




	vspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPRCanadaT4Load] TO [public]
GO
