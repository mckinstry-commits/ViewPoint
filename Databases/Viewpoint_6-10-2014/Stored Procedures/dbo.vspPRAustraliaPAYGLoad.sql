SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspPRAustraliaPAYGLoad]
	/******************************************************
	* CREATED BY:	EN	12/1/2010
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
	*	@abn - Australian Business Number from FedTaxID field.
	*	@name - Company Name
	*	@address - Company Address
	*	@city
	*	@state - 
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@prco bCompany, @abn varchar(15) output, @name varchar(30) output, 
	@msg varchar(100) output

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0
	 
	if @prco is null
	begin	
		select @msg = 'Missing PR Company!', @rcode = 1
		goto vspexit
	end

	select @abn = substring(FedTaxId,1, 15), @name = substring([Name], 1, 30) 
	from HQCO (nolock) where HQCo = @prco




	vspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPRAustraliaPAYGLoad] TO [public]
GO
