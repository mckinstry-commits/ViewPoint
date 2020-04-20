SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPRGetHQCoDefaultCountry] 
/************************************************************************
* Created: EN 9/12/08
* Modified: 
*
* Usage:
* Returns DefaultCountry from HQCO for the specified Company #.  
*
* Inputs:
*	@prco			PR Company #
*
* Outputs:
*	@country		HQCO DefaultCountry
*	@msg			Error message
*
* Return code:
*	0 = success, 1 = error w/messsge
*
**************************************************************************/
(@prco bCompany = null, @country char(2) output,  @msg varchar(512) output)

as

set nocount on 

declare @rcode integer

select @rcode = 0

if exists(select * from bHQCO where HQCo = @prco)
	begin
	select @country = DefaultCountry from bHQCO where HQCo = @prco
	goto vspexit
	end
else
	begin
	select @msg = 'Company# ' + convert(varchar,@prco) + ' not setup in HQ', @rcode = 1
	end


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRGetHQCoDefaultCountry] TO [public]
GO
