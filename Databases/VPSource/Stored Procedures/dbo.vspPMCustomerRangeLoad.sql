SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPMCustomerRangeLoad]
/********************************************************
 * Created By:	TRL 03/26/09  Issue 132109
 * Modified By:	
 *
 * USAGE: Retrieves ARCo and CustGroup from JC Company
 *
 * INPUT PARAMETERS:
 *	PM Company
 *
 * OUTPUT PARAMETERS:
 * ARCO, CustGroup
 * From JCCO => ARCO => CustGroup
 *	
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@pmco bCompany=0, @arco bCompany = null output, @arcodesc varchar(60) = null output,
@custgroup bGroup = null output, @custgroupdesc bDesc = null output, @errmsg varchar(255) output)

as 

set nocount on

declare @rcode int 

select @rcode = 0

---- missing MS company
if @pmco is null
begin
   	select @errmsg = 'Missing PM Company!', @rcode = 1
   	goto vspexit
end

---- get AR company from JCCo
select @arco=ARCo from JCCO with (nolock) where JCCo = @pmco

---- get AR company from JCCo
select @custgroup=c.CustGroup,@custgroupdesc=g.Description,@arcodesc=c.Name
from HQCO c with (nolock) 
Inner Join HQGP g with(nolock)on g.Grp=c.CustGroup
where c.HQCo = @arco

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCustomerRangeLoad] TO [public]
GO
