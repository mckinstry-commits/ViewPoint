SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspJCRateTemplateVal]
/*************************************
 * Created By:		DANF 02/15/07
 * Modified By:		CHS 06/11/2009 - issue #132119
 *
 * USAGE:
 * Called from JCJM to validate the rate template.
 *
 *
 * INPUT PARAMETERS
 * @JCCo
 * @ratetemplate
 * @msg
 *
 * Success returns:
 * 0, cost type and description
 *
 * Error returns:
 * 1 and error message
 **************************************/
(@jcco bCompany, @ratetemplate smallint, @desc varchar(60) output, @msg varchar(255) output)
as
set nocount on

declare @rc int, @rcode int, @errortext varchar(255)

select @rc = 0, @rcode = 0, @msg = ''

if isnull(@jcco,'') = ''
	begin
   	select @msg = 'Company is missing.', @rc = 1
   	goto bspexit
	end

-- Template can be null
if isnull(@ratetemplate,'') = '' 
	begin
   	goto bspexit
	end


select @msg = Description, @desc = Description
from dbo.JCRT with (nolock)
where JCCo = @jcco and RateTemplate = @ratetemplate
if @@rowcount <> 1
	begin
   	select @msg = 'Invalid rate template.',  @desc = 'New rate template.', @rc = 1
   	goto bspexit
	end


bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rc

GO
GRANT EXECUTE ON  [dbo].[vspJCRateTemplateVal] TO [public]
GO
