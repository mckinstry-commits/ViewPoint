SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRResourceBenefitsLoadProc]
/************************************************************************
* CREATED:	mh 5/27/2005    
* MODIFIED: EN 11/05/2009 #136038  pull AP Company from PRCO based on PR Company, not HR Company
*
* Purpose of Stored Procedure
*
*    Get initial info for HR Resource Benefits
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany, @vendorgroup bGroup output, @glco bCompany output, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int, @apco bCompany

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

	select @apco = p.APCo from PRCO p (nolock)
	join HRCO h on p.PRCo = h.PRCo --#136038 (was h.HRCo)
	where h.HRCo = @hrco

	exec @rcode = dbo.bspAPVendorGrpGet @apco, @vendorgroup output, @msg output

	if @rcode = 0
	begin
		exec @rcode = dbo.bspGLCOfromHRCO @hrco, @glco output, @msg output
	end

bspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRResourceBenefitsLoadProc] TO [public]
GO
