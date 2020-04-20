SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[vspHRResourceMasterLoadProc]
/************************************************************************
* CREATED:		mh     
* MODIFIED:		
*
* Purpose of Stored Procedure
*
*    'Get Load info for HR Resource Master.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

       
    (@hrco bCompany = null, @defaultPRCo bCompany = null output, @updatename bYN = null output,
	@updateaddress bYN = null output, @updatehireterm bYN = null output, @updateactive bYN = null output, 
	@updatetimecard bYN = null output, @updateW4 bYN = null output, @updateoccup bYN = null output,
	@updatessnyn bYN = null output, @defaultcountry char(2) = null output, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int 
    select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company', @rcode = 1
		goto vspexit
	end

	if not exists(select 1 from HRCO where HRCo = @hrco) 
	begin
		select @msg = 'Company# ' + convert(varchar(4), @hrco) + ' not setup in HR', @rcode = 1
		goto vspexit
	end

	select @defaultPRCo = HRCO.PRCo, @updatename = HRCO.UpdateNameYN, 
	@updateaddress = HRCO.UpdateAddressYN, @updatehireterm = HRCO.UpdateHireDateYN, 
	@updateactive = HRCO.UpdateActiveYN, @updatetimecard = HRCO.UpdateTimecardYN,
	@updateW4 = HRCO.UpdateW4YN, @updateoccup = HRCO.UpdateOccupCatYN, 
	@updatessnyn = HRCO.UpdateSSNYN, @defaultcountry = HQCO.DefaultCountry
	from dbo.HRCO (nolock) Join HQCO on HRCO.HRCo = HQCO.HQCo where HRCO.HRCo = @hrco

	
vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRResourceMasterLoadProc] TO [public]
GO
