SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.[vspJBDescJBILLine]    Script Date:  ******/
CREATE PROC [dbo].[vspJBDescJBILLine]
/***********************************************************
* CREATED BY:  TJL 05/02/06 - Issue #28227: 6x Rewrite JBTMBillLines form
* MODIFIED By : 
*
* USAGE:
* 	Returns JBIL Line Description
*
* INPUT PARAMETERS
*   JB Company
*   JB BillMonth
*	JB BillNumber
*	Line
*
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@jbco bCompany = null, @billmonth bMonth = null, @billnumber int = null, @line int = null,
	@msg varchar(255) output)
as
set nocount on

if @jbco is null
	begin
	goto vspexit
	end
if @billmonth is null
	begin
	goto vspexit
	end
if @billnumber is null
	begin
	goto vspexit
	end
if @line is null
	begin
	goto vspexit
	end

select @msg = l.Description
from bJBIL l with (nolock) 
where l.JBCo = @jbco and l.BillMonth = @billmonth and l.BillNumber = @billnumber
	and l.Line = @line

vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspJBDescJBILLine] TO [public]
GO
