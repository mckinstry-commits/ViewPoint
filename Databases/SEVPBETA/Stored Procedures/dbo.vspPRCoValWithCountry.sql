SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPRCoValWithCountry] 
/************************************************************************
* Created: EN 9/12/08
* Modified: 
*
* Usage:
* Checks for the existence of a specific Co# within PR and returns DefaultCountry from HQCO.  
*
* Inputs:
*	@prco			PR Company # to validate
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

if exists(select * from bPRCO where PRCo = @prco)
	begin
	select @msg = Name, @country = DefaultCountry from bHQCO where HQCo = @prco
	goto vspexit
	end
else
	begin
	select @msg = 'Company# ' + convert(varchar,@prco) + ' not setup in PR', @rcode = 1
	end


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRCoValWithCountry] TO [public]
GO
