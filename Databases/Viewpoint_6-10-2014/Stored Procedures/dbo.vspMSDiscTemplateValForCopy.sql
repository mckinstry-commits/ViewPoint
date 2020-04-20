SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************/
CREATE proc [dbo].[vspMSDiscTemplateValForCopy]
/*************************************
 * Created By:	GF 06/19/2006
 * Modified By:
 *
 * validates MS Destination Discount Template fro copy form.
 *
 * Pass:
 *	MS Company and MS Discount Template to be validated
 *
 * Success returns:
 *	0 and Description from bMSDH
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@msco bCompany = null, @srcdisctemplate smallint = null, @destdisctemplate smallint = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @msco is null
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end

if @srcdisctemplate is null
   	begin
   	select @msg = 'Missing MS Source Discount Template', @rcode = 1
   	goto bspexit
   	end

if @destdisctemplate is null
   	begin
   	select @msg = 'Missing MS Destination Discount Template', @rcode = 1
   	goto bspexit
   	end

------ invalid if source template = destination template
if @srcdisctemplate = @destdisctemplate
	begin
	select @msg = 'Destination template cannot equal source template.', @rcode = 1
	goto bspexit
	end

------ check if destination template already exists
select @msg = Description
from MSDH with (nolock) where MSCo=@msco and DiscTemplate=@destdisctemplate
if @@rowcount = 0
	begin
	select @msg = 'New Template', @rcode = 0
	goto bspexit
	end





bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSDiscTemplateValForCopy] TO [public]
GO
