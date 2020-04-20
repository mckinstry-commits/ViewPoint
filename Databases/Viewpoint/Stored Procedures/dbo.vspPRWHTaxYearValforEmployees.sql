SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRWHTaxYearValforEmployees]
/************************************************************************
* CREATED:	mh 11/30/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Validate TaxYear setup in PRWH and return PensionPlan code.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@prco bCompany, @taxyear varchar(4), @pensionplan char(1) output, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @prco is null
	begin
		select @msg = 'Missing PR Company', @rcode = 1 
		goto vspexit
	end

	if @taxyear is null
	begin
		select @msg = 'Missing Tax Year', @rcode = 1
		goto vspexit
	end

	select @pensionplan = PensionPlan from PRWH where PRCo = @prco and TaxYear = @taxyear
	if @@rowcount = 0
	begin
   	 	select @msg = 'Year must first be initialized.', @rcode = 1
   	 	goto vspexit
   	end	

   	

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRWHTaxYearValforEmployees] TO [public]
GO
