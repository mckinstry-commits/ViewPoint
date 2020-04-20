SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspARDiscTemplateVal]
/*************************************
* Created By:   TJL 07/20/2005
* Modified By:
*
* Validates Discount Template.
* Checks to see if this DiscTemplate is valid for any
* MSCo that uses this ARCo
*
* Pass In:
* ARCo Company
* MS Disc Template to be validated
*
* Success returns:
*	0 and Description
*
* Error returns:
*	1 and error message
**************************************/

(@arco bCompany = null, @disctemplate smallint = null, @msg varchar(255) output)
as
set nocount on
  
declare @rcode int
select @rcode = 0
  
if @arco is null
	begin
	select @msg = 'Missing AR Company', @rcode = 1
	goto vspexit
	end
  
if @disctemplate is null
	begin
	select @msg = 'Missing MS Discount Template', @rcode = 1
	goto vspexit
	end

/* Validate DiscTemplate */
select @msg = bMSDH.Description
from bMSDH with (nolock)
join bMSCO with (nolock) on bMSCO.MSCo = bMSDH.MSCo
where bMSCO.ARCo = @arco and bMSDH.DiscTemplate = @disctemplate
if @@rowcount = 0
	begin
	select @msg = 'Not a valid Discount Template for any MS Company that uses ARCo #' + Convert(varchar(3), @arco), @rcode = 1
	goto vspexit
	end

vspexit:
if @rcode <> 0 select @msg = @msg	--+ char(10) + char(13) + char(10) + char(13) + '[vspARDiscTemplateVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARDiscTemplateVal] TO [public]
GO
