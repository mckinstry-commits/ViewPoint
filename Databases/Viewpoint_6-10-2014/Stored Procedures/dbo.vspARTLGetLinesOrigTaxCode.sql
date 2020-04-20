SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspARTLGetLinesOrigTaxCode]
/****************************************************************************************************
* CREATED BY  : TJL 02/18/05 - Issue #26556
* MODIFIED By : 
*
*
* USAGE:
*	Called from ARInvoiceEntry form and used only when a change has been made to 
*	an Adjustment, Credit, or WriteOff Line.  Helps assure that applied transaction contains 
*	the same TaxCode as the Original Line to avoid validation errors.
*
* 
* INPUT PARAMETERS
*   @arco		ARCo 
*   @mth		Mth - Month of Original transaction
*   @artrans	ARTrans - Original transaction to apply against  
*	@arline		ARLine - Original transaction line to apply against             
*
*
* OUTPUT PARAMETERS
*	@taxcode	Line TaxCode.  Used in Form Validation to Assure that ApplyLine TaxCode remains same as OrigLine TaxCode
*   @errmsg     
*
* RETURN VALUE
*   0   Success - Line Found
*	1	Failure - Complete failure.  
*
******************************************************************************************************/ 
  
(@arco bCompany, @mth bMonth, @artrans bTrans, @arline smallint, @taxcode bTaxCode output, @errmsg varchar(255) output)
as
set nocount on
declare @rcode int

select @rcode=0

if @arco is null
	begin
	select @errmsg = 'Missing ARCo.', @rcode = 1
	goto vspexit
	end
if @mth is null
	begin
	select @errmsg = 'Missing Transaction Month to apply to.', @rcode = 1
	goto vspexit
	end
if @artrans is null
	begin
	select @errmsg = 'Missing AR Transaction to apply to.', @rcode = 1
	goto vspexit
	end	
if @arline is null
	begin
	select @errmsg = 'Missing AR Transaction Line to apply to.', @rcode = 1
	goto vspexit
	end	

/* Check for the existence of this ARLine input by the user. */
if exists(select 1 from bARTL with (nolock)
		where ARCo = @arco and Mth = @mth and ARTrans = @artrans and ARLine = @arline)
	begin
	select @taxcode = isnull(TaxCode, '')
	from bARTL with (nolock)
	where ARCo = @arco and Mth = @mth and ARTrans = @artrans and ARLine = @arline
	if @@rowcount = 0
		begin
		select @errmsg = 'A failure has occurred while reading this Lines TaxCode value. UNDO and try again.', @rcode = 1
		goto vspexit
		end
	end
else
	begin
	select @errmsg = 'This Line no longer exists on the Original Invoice transaction.', @rcode = 1
	goto vspexit
	end

vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + ' [vspARTLGetLinesOrigTaxCode]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARTLGetLinesOrigTaxCode] TO [public]
GO
