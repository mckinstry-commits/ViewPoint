SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBGetJCCOINCoMatlGrp    Script Date: ******/
CREATE proc [dbo].[vspJBGetJCCOINCoMatlGrp]
/*************************************
*  Created:		TJL 03/20/07 - Issue #123676, 6x rewrite
*  Modified:	TJL 07/24/07 - Add check for Menu Company (HQCo) in JB Module Company Master
*		TJL 04/28/08 - Issue #128063, When JCCO.INCo is NULL get MatlGrp from HQCO for this JCCo	
*
*  
*
*  Inputs:
*	 @jbco:		JB Company
*
*  Outputs:
*	 @incomatlgroup
*
* Error returns:
*	0 and success
*	1 and error message
**************************************/
(@jbco bCompany, @incomatlgrp bGroup output, @msg varchar(60) output)
as 
set nocount on

declare @rcode int, @inco bCompany
select @rcode = 0
  	
if @jbco is null
	begin
	select @msg = 'Missing JB Company.', @rcode = 1
	goto vspexit
	end
else
	begin
	select top 1 1 
	from dbo.JBCO with (nolock)
	where JBCo = @jbco
	if @@rowcount = 0
		begin
		select @msg = 'Company# ' + convert(varchar,@jbco) + ' not setup in JB.', @rcode = 1
		goto vspexit
		end
	end

/* Get JCCo values. */
select @inco = c.INCo, @incomatlgrp = isnull(hc.MatlGroup, h.MatlGroup)
from bJCCO c with (nolock)
left join bHQCO hc with (nolock) on hc.HQCo = c.INCo
join bHQCO h with (nolock) on h.HQCo = c.JCCo
where c.JCCo = @jbco
if @@rowcount = 0
	begin
	select @msg = 'Error getting JB Common JC and IN information.', @rcode = 1
	end
  
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBGetJCCOINCoMatlGrp] TO [public]
GO
