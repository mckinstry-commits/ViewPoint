SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[vspHRBenefitCodesLoadProc]
/************************************************************************
* CREATED:	mh 4/6/2005    
* MODIFIED: mh 8/8/2007 - Added HRCo validation.   
*
* Purpose of Stored Procedure
*
*	Load Proc for HR Benefit Codes    
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/


    (@hrco bCompany = null, @prco bCompany = null output, @vendorgrp bGroup = null output, 
	@defaultcountry char(2) = null output, @msg varchar(80) = '' output)

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

	Select @vendorgrp = HQCO.VendorGroup
	from HRCO join PRCO on HRCO.PRCo = PRCO.PRCo
	Join HQCO on PRCO.APCo = HQCO.HQCo
	where HRCO.HRCo = @hrco

	if @vendorgrp is null
	begin
		select @msg = 'Unable to get Vendor Group from HQCO', @rcode = 1
		goto bspexit
	end

	select @defaultcountry = DefaultCountry from HQCO (nolock) where HQCo = @hrco


bspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRBenefitCodesLoadProc] TO [public]
GO
