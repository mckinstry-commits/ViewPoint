SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE            procedure [dbo].[vspEMCompXferMaxSeq]
/***********************************************************
* CREATED BY: DANF 03/20/07
* MODIFIED By : 
*
* USAGE:
*	returns the Max Seq for the component
*
* INPUT PARAMETERS
*	@EMCo			EM Company to be validated against
*	@Component		Component to be validated
*
* RETURN VALUE
*	0 success
*	1 error
*	
***********************************************************/
(@EMCo bCompany = null, @Component bEquip = null, @Seq int = null output, @errmsg varchar(255) output)

as

set nocount on

declare @rcode int

select @rcode = 0

if @EMCo is null
	begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto bspexit
	end

if @Component is null
	begin
	select @errmsg = 'Missing Component!', @rcode = 1
	goto bspexit
	end

Select @Seq = isnull(Max(Seq),0) 
from EMHC with (nolock)
where EMCo = @EMCo and Component = @Component
 

bspexit:
if @rcode<>0 select @errmsg=isnull(@errmsg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCompXferMaxSeq] TO [public]
GO
