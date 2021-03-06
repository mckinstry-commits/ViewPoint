SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRBenCodeDescVal]
/************************************************************************
* CREATED:	mh 1/6/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*	Get BenefitCode Description
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany, @benefitcode varchar(10), @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company.', @rcode = 1
		goto vspexit
	end

	if @benefitcode is null
	begin
		select @msg = 'Missing Benefit Code.', @rcode = 1
		goto vspexit
	end

	select @msg = h.Description from dbo.HRBC h where h.HRCo = @hrco and h.BenefitCode = @benefitcode


vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRBenCodeDescVal] TO [public]
GO
