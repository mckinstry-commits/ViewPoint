SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMInfoGetForAUTempCopy    Script Date: ******/
CREATE proc [dbo].[vspEMInfoGetForAUTempCopy]
/********************************************************
* CREATED BY:  TJL 11/16/06 - Issue #28146, 6x Recode
* MODIFIED BY:  TJL 07/24/07 - Add check for Menu Company (HQCo) in EM Module Company Master
*
* USAGE:
* 	Retrieves EMUH.AUTemplate for Default on EMAutoUseTemplateCopy form.
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
*	AUTemplate
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1		Message Failure
*
**********************************************************/

(@emco bCompany, @autousetemplate varchar(10) output, @msg varchar(60) output) as 
set nocount on
declare @rcode int
select @rcode = 0

if @emco is null
	begin
	select @msg = 'Missing EM Company.', @rcode = 1
	goto vspexit
	end
else
	begin
	select top 1 1 
	from dbo.EMCO with (nolock)
	where EMCo = @emco
	if @@rowcount = 0
		begin
		select @msg = 'Company# ' + convert(varchar,@emco) + ' not setup in EM.', @rcode = 1
		goto vspexit
		end
	end


select @autousetemplate = (select top 1 AUTemplate from bEMUH with (nolock) where EMCo = @emco)

vspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMInfoGetForAUTempCopy] TO [public]
GO
