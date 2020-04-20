SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspARCompanyValForCreditNotes]
/*************************************
* Created:	TJL  11/26/07 - Issue #29904, Add ARCo column to Credit Note
*
* Usage:
*	Validates AR Company number applied to Credit Note
*	Validates AR Company, CustGroup
*
* Inputs:
*	Form Company
*	Form Company's CustGroup
*	AR Company input value for Credit Note
*
* Success returns:
*	0 and AR Company name for Credit Note
*	AR Company for Credit Note CustGroup from bHQCO
*
* Error returns:
*	1 and error message
**************************************/
(@arco bCompany = null, @custgroup bGroup = null, @arcoforcreditnote bCompany = null, 
	@custgroupforcreditnote bGroup output, @msg varchar(150) output)
as
set nocount on
declare @rcode int
select @rcode = 0

if @arco is null
	begin
	select @msg = 'Missing module AR Company value.', @rcode = 1
	goto vspexit
	end

if @custgroup is null
	begin
	select @msg = 'Missing module AR Company CustGroup value.', @rcode = 1
	goto vspexit
	end

if @arcoforcreditnote is null
	begin
	select @msg = 'Missing credit note AR Company value.', @rcode = 1
	goto vspexit
	end

/* Validation: AR Company to be used on Credit Note */
if not exists(select 1 from ARCO with (nolock) where ARCo = @arcoforcreditnote)
	begin
	select @msg = 'Not a valid AR Company.', @rcode = 1
	goto vspexit
	end

/* CustGroup comparison */
select @msg = Name, @custgroupforcreditnote = CustGroup 
from bHQCO with (nolock) 
where HQCo = @arcoforcreditnote

if @custgroupforcreditnote is null or @custgroupforcreditnote <> @custgroup
	begin
	select @msg = 'The AR Company is not using the same Customer Group as is the '
	select @msg = @msg + 'current company from which you are working.  Record will not be saved.', @rcode = 1
	goto vspexit
	end

vspexit:
if @rcode <> 0 select @msg = @msg
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARCompanyValForCreditNotes] TO [public]
GO
