SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBTemplateInfoGet    Script Date: ******/
CREATE proc [dbo].[vspJBTemplateInfoGet]
/*************************************
*  Created:		TJL 04/14/06 - Multiple Issues, 6x rewrite
*  Modified:	TJL 07/24/07 - Add check for Menu Company (HQCo) in JB Module Company Master
*		TJL 08/04/08 - Issue #: 128962, JB International Sales Tax	
*
*  Job Billing Information returned to JB Template Forms during Load
*
*  Inputs:
*	 @jbco:		JB Company
*
*  Outputs:
*
*
* Error returns:
*	0 and success
*	1 and error message
**************************************/
(@jbco bCompany, @custgroup bGroup output, @jccophasegroup bGroup output, @taxgroup bGroup output,
	@arcoinvoicetax bYN output, @arcotaxretg bYN output, @arcosepretgtax bYN output, @msg varchar(60) output)
as 
set nocount on
declare @rcode int
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

/* Get JCCo values */
select @custgroup = h.CustGroup, @jccophasegroup = hc.PhaseGroup, @taxgroup = h.TaxGroup,
	@arcoinvoicetax = a.InvoiceTax, @arcotaxretg = a.TaxRetg, @arcosepretgtax = a.SeparateRetgTax
from bJCCO c with (nolock)
join bARCO a with (nolock) on a.ARCo = c.ARCo
join bHQCO h with (nolock) on h.HQCo = a.ARCo
join bHQCO hc with (nolock) on hc.HQCo = c.JCCo
where c.JCCo = @jbco
if @@rowcount = 0
	begin
	select @msg = 'Error getting JB Common JC and AR information.', @rcode = 1
	end
  
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBTemplateInfoGet] TO [public]
GO
