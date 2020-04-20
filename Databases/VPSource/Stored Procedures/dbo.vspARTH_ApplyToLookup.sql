SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARTH_ApplyToLookup  Script Date: 02/15/05 9:34:10 AM ******/
CREATE proc [dbo].[vspARTH_ApplyToLookup]
/***************************************************************************************************
* CREATED BY:  TJL 02/15/05
* MODIFIED BY:  TJL 10/09/07 - Issue #125715:  Use Views (not tables) in selects statements to fill lookup.  Allows DataType security to work.
*		TJL 09/23/08 - Issue #128311, Add ARTransType to Lookup
*
* USAGE:
*	Returns required values relative to ApplyTo transactions. (Adjustments, Credits, & WriteOffs)
*	Currently only used in Forms ARInvoiceEntry and ARFinChg
*	
* INPUT PARAMETERS
*
*   	
* OUTPUT PARAMETERS
*   @msg      Description or error message
*
* RETURN VALUE
*   0         success
*   1         msg & failure
*****************************************************************************************************/
(@arco bCompany, @custgroup bGroup, @customer bCustomer, @option tinyint)

as
set nocount on
declare @rcode integer
select @rcode = 0

if @option = 2	
	begin
	/* Open Invoices */
	select distinct(h.Invoice), h.TransDate, h.Mth, h.ARTrans, h.Description, h.RecType, h.PayTerms, h.JCCo, h.Contract, 
		h.CustRef, (h.AmountDue + h.Retainage) OpenAmount, h.ARTransType
	from ARTH h with (nolock)
	join ARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans
	where h.ARTransType in ('I','R','F') and  h.Mth = h.AppliedMth and h.ARTrans = h.AppliedTrans 
		and h.ARCo = @arco and h.CustGroup = @custgroup and h.Customer = @customer
		and (h.AmountDue + h.Retainage) <> 0
	order by h.Invoice
	end
else
	begin
	/* All Invoices */
	select distinct(h.Invoice), h.TransDate, h.Mth, h.ARTrans, h.Description, h.RecType, h.PayTerms, h.JCCo, h.Contract, 
		h.CustRef, (h.AmountDue + h.Retainage) OpenAmount, h.ARTransType
	from ARTH h with (nolock)
	join ARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans
	where h.ARTransType in ('I','R','F') and  h.Mth = h.AppliedMth and h.ARTrans = h.AppliedTrans 
		and h.ARCo = @arco and h.CustGroup = @custgroup and h.Customer = @customer
	order by h.Invoice
	end

vspexit:
-- 	if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[vspARTH_ApplyToLookup]'
-- 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARTH_ApplyToLookup] TO [public]
GO
