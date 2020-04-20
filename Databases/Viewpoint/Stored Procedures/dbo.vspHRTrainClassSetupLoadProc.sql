SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRTrainClassSetupLoadProc]
/************************************************************************
* CREATED:	MH 4/11/2005    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*	Load Procedure for HR Training Class Setup    
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany, @vendorgrp bGroup = null output, @codetype char(1) = null output, @defaultcountry char(2) = null output, 
	@msg varchar(80) = '' output)

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

	select @codetype = 'T'

	select @defaultcountry = DefaultCountry from HQCO (nolock) where HQCo = @hrco

	exec @rcode = bspAPVendorGrpGet @hrco, @vendorgrp output, @msg output

	

bspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRTrainClassSetupLoadProc] TO [public]
GO
