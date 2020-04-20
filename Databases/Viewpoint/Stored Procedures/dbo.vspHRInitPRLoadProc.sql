SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRInitPRLoadProc]
/************************************************************************
* CREATED:	mh 12/7/05    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Load Procedure for HRInitPR
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany, @prco bCompany output, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company', @rcode = 1
		goto bspexit
	end

	if not exists(select 1 from HRCO where HRCo = @hrco) 
	begin
		select @msg = 'Company# ' + convert(varchar(4), @hrco) + ' not setup in HR', @rcode = 1
		goto bspexit
	end

	select @prco = PRCo from HRCO where HRCo = @hrco
	
	if not exists(select 1 from PRCO where PRCo = @prco)
	begin
		select @msg = 'PRCo in HRCO is not a valid Payroll Company', @rcode = 1
		goto bspexit
	end

bspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRInitPRLoadProc] TO [public]
GO