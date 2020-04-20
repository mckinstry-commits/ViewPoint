SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBInfoGetJBBillHeader    Script Date: ******/
CREATE proc [dbo].[vspJBInfoGetJBBillHeader]
/*************************************
*  Created:		TJL 01/18/06 - Issue #28048, 6x rewrite.  Return required Bill Header information
*  Modified:	TJL 07/24/07 - Add check for Menu Company (HQCo) in JB Module Company Master	
*		GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
*		TJL 07/15/08 - Issue #127287, JB International Sales Tax
*		TJL 12/19/08 - Issue #129896, Return new output UseCertified from JBCO
*
*
*  Job Billing necessary Bill Header information returned to JB Progress and T&M Bill edit forms.
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
	@custgroup bGroup output, @taxgroup bGroup output, @jbcoeditprogonbothyn bYN output, @jbcoautoseqinvyn bYN output,
	@jbcoinvoiceopt char(1) output, @jbcochgprevprog bYN output, @jbcoprevupdateyn bYN output, @jccoglrevoverrideyn bYN output,
	@postsoftclosedjobs bYN output, @arcoinvoicetaxyn bYN output, @arcotaxretgyn bYN output, @arcosepretgtaxyn bYN output,
	@jbcousecertified bYN output, @msg varchar(60) output)
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
	@jbcoeditprogonbothyn = b.EditProgOnBothYN, @jbcoautoseqinvyn = b.AutoSeqInvYN, @jbcoinvoiceopt = b.InvoiceOpt,
	@jbcochgprevprog = b.ChgPrevProg, @jbcoprevupdateyn = b.PrevUpdateYN, @jccoglrevoverrideyn = c.GLRevOveride,
	@postsoftclosedjobs = c.PostSoftClosedJobs, @arcoinvoicetaxyn = a.InvoiceTax, @arcotaxretgyn = a.TaxRetg,
	@arcosepretgtaxyn = a.SeparateRetgTax, @jbcousecertified = b.UseCertified
from bJCCO c with (nolock)
join bARCO a with (nolock) on a.ARCo = c.ARCo
join bHQCO h with (nolock) on h.HQCo = a.ARCo
join bJBCO b with (nolock) on c.JCCo = b.JBCo
where c.JCCo = @jbco

if @@rowcount = 0
	begin
	select @msg = 'Error getting JB Common JC and AR information.', @rcode = 1
	end
  
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBInfoGetJBBillHeader] TO [public]
GO
