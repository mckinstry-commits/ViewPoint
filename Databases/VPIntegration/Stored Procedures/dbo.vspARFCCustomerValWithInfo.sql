SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspARFCCustomerValWithInfo]
/***********************************************************
* CREATED BY:	TJL 05/10/05 - Issue #27704, Rewrite for 6x
* MODIFIED By:  TJL 04/23/08 - Issue #127760, Error message correction
*
* USAGE:
*	Currently used by forms ARFinChg
* 	Validates Customer
*
* INPUT PARAMETERS
*   @Company	Company
*   @CustGroup	Customer Group
*   @Customer	Customer to validate
*
* OUTPUT PARAMETERS
*   @custoutput			An output of bspARCustomerVal
*   @rectype			ARCM.RecType
*   @payterms			ARCM.PAYTERMS
*   @finchgpct			ARCM.FCPct
*   @finchgtype  		ARMC.FCType
*   @msg      			error message if error occurs, or ARCM.Name
*
* RETURN VALUE
*   0	Success
*   1	Failure
*****************************************************/
(@Company bCompany, @CustGroup bGroup = null, @Customer bSortName = null, @custoutput bCustomer = null output,
	@rectype int = null output, @payterms bPayTerms = null output, @finchgpct bPct = null output,
	@finchgtype varchar(1) = null output, @exclcontfromFC bYN output, @msg varchar(100) = null output)
  
as
set nocount on
  
/* Working declares */
declare @rcode int, @AutoNumYN char(1), @Num int, @rectypedesc varchar(30),
	@option char(1), @msg2 varchar(100)
  
select @rcode = 0, @option = null

if @Company is null
	begin
 	select @msg = 'Missing Company!', @rcode = 1
 	goto vspexit
 	end
if @CustGroup is null
	begin
 	select @msg = 'Missing Customer Group!', @rcode = 1
 	goto vspexit
 	end
if @Customer is null
 	begin
 	select @msg = 'Missing Customer!', @rcode = 1
 	goto vspexit
 	end
  
exec @rcode =  bspARCustomerVal @CustGroup, @Customer, @option, @custoutput output, @msg output
if @rcode = 1 goto vspexit
  
/* Need to get other customer info */
select @msg = a.Name, @rectype = a.RecType, @payterms = a.PayTerms,
 	@finchgpct = a.FCPct, @finchgtype = a.FCType, @exclcontfromFC = a.ExclContFromFC
from ARCM a with (nolock)
where CustGroup = @CustGroup and Customer = @custoutput
  
  /* Check Finance Charge type and exit and alert user if type is N - No Finance Charges */
if @finchgtype = 'N'
	begin
	select @msg = 'This customer is not set in AR Customers to allow Finance Charges!', @rcode = 1
	goto vspexit
	end
  
vspexit:
if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[vspARFCCustomerValWithInfo]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARFCCustomerValWithInfo] TO [public]
GO
