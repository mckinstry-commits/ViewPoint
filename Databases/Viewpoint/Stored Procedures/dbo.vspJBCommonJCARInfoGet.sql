SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBCommonJCARInfoGet    Script Date: ******/
CREATE proc [dbo].[vspJBCommonJCARInfoGet]
/*************************************
*  Created:		TJL 12/15/05 - Multiple Issues, 6x rewrite
*  Modified:	TJL 07/24/07 - Add check for Menu Company (HQCo) in JB Module Company Master	
*				GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
*
*
*  Job Billing Common JC and AR Information returned to JB Forms during Load
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
(@jbco bCompany, @jccopostclosedjobsyn bYN output, @jccodfltbilltype char(1) output, @jccoarco bCompany output, @jccoglco bCompany output, 
 @arcoglco bCompany output, @arlastinvoicenum varchar(10) output, @arcorectype int output, @arcorectypeopt bYN output,  
 @custgroup bGroup output, @taxgroup bGroup output, @jccoprco bCompany output,
 @postsoftclosedjobs bYN output, @msg varchar(60) output)
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
select @jccopostclosedjobsyn = c.PostClosedJobs, @jccodfltbilltype = c.DefaultBillType, @jccoarco = c.ARCo,
	@jccoglco = c.GLCo, @arcoglco = a.GLCo, @arlastinvoicenum = a.InvLastNum, @arcorectype = a.RecType,
	@arcorectypeopt = a.RecTypeOpt, @custgroup = h.CustGroup, @taxgroup = h.TaxGroup,
	@jccoprco = c.PRCo, @postsoftclosedjobs = c.PostSoftClosedJobs
from bJCCO c with (nolock)
join bARCO a with (nolock) on a.ARCo = c.ARCo
join bHQCO h with (nolock) on h.HQCo = a.ARCo
where c.JCCo = @jbco

if @@rowcount = 0
	begin
	select @msg = 'Error getting JB Common JC and AR information.', @rcode = 1
	end
  
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBCommonJCARInfoGet] TO [public]
GO
