SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************/
CREATE proc [dbo].[vspMSPriceTemplateValForCopy]
/*************************************
 * Created By:	GF 06/23/2006
 * Modified By:
 *
 * validates MS Destination Price Template for copy form.
 *
 * Pass:
 *	MS Company and MS Price Template to be validated
 *
 * Success returns:
 *	0 and Description from bMSTH
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@msco bCompany = null, @srcpricetemplate smallint = null, @destpricetemplate smallint = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @msco is null
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end

if @srcpricetemplate is null
   	begin
   	select @msg = 'Missing MS Source Price Template', @rcode = 1
   	goto bspexit
   	end

if @destpricetemplate is null
   	begin
   	select @msg = 'Missing MS Destination Price Template', @rcode = 1
   	goto bspexit
   	end

------ invalid if source template = destination template
if @srcpricetemplate = @destpricetemplate
	begin
	select @msg = 'Destination template cannot equal source template.', @rcode = 1
	goto bspexit
	end

------ check if destination template already exists
select @msg = Description
from MSTH with (nolock) where MSCo=@msco and PriceTemplate=@destpricetemplate
if @@rowcount = 0
	begin
	select @msg = 'New Template', @rcode = 0
	goto bspexit
	end





bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSPriceTemplateValForCopy] TO [public]
GO
