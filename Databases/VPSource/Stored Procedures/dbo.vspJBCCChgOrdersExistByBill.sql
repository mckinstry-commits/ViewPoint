SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBCCChgOrdersExistByBill  Script Date: ******/
CREATE procedure [dbo].[vspJBCCChgOrdersExistByBill]
/*************************************************************************************************
* CREATED BY: 		TJL 01/31/06 - Issue #28048, 6x rewrite JBProgressBillHeader.  Check for presence of JBCC records by BillNumber
* MODIFIED By :
*
* USAGE:
* 	Currently used by 'JBProgressBillHeader'.  It determines if Changes Orders exist in
*	the JBCC table relative to an single BillMonth, BillNumber.  If so, user will be warned and record delete
*	will be aborted until Change Orders have been removed.
*	
*
* INPUT PARAMETERS
*   @jbco			JBCo
*   @billmonth		BillMonth
*   @billnumber		BillNumber
*
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************************************************/
  
(@jbco bCompany, @billmonth bMonth, @billnumber int, @errmsg varchar(255) output)
as

set nocount on

declare @rcode int

select @rcode = 0

-- if @source not in ('JB')
-- 	begin
-- 	select @errmsg = 'Not a valid Source.', @rcode = 1
-- 	goto vspexit
-- 	end
  
/* Check for the existence of Change Orders for this BillMOnth, BillNumber. */
if exists (select 1 
	from bJBCC with (nolock) 
	where JBCo = @jbco and BillMonth = @billmonth and BillNumber = @billnumber)
	begin
	/* Change Order records exist. */
	select @rcode = 1
	end
  
vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[vspJBCCChgOrdersExistByBill]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBCCChgOrdersExistByBill] TO [public]
GO
