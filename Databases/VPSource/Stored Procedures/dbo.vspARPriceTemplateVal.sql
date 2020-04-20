SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspARPriceTemplateVal]
/*************************************
* Created By:   TJL 07/20/2005
* Modified By:
*
* Validates Price Template.
* Checks to see if this PriceTemplate is valid for any
* MSCo that uses this ARCo
*
* Pass In:
* ARCo Company
* MS Price Template to be validated
*
* Success returns:
*	0 and Description
*
* Error returns:
*	1 and error message
**************************************/

(@arco bCompany = null, @pricetemplate smallint = null, @msg varchar(255) output)
as
set nocount on
  
declare @rcode int
select @rcode = 0
  
if @arco is null
	begin
	select @msg = 'Missing AR Company', @rcode = 1
	goto vspexit
	end
  
if @pricetemplate is null
	begin
	select @msg = 'Missing MS Price Template', @rcode = 1
	goto vspexit
	end

/* Validate PriceTemplate */
select @msg = bMSTH.Description
from bMSTH with (nolock)
join bMSCO with (nolock) on bMSCO.MSCo = bMSTH.MSCo
where bMSCO.ARCo = @arco and bMSTH.PriceTemplate = @pricetemplate
if @@rowcount = 0
	begin
	select @msg = 'Not a valid Price Template for any MS Company that uses ARCo #' + Convert(varchar(3), @arco), @rcode = 1
	goto vspexit
	end

vspexit:
if @rcode <> 0 select @msg = @msg	--+ char(10) + char(13) + char(10) + char(13) + '[vspARPriceTemplateVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARPriceTemplateVal] TO [public]
GO
