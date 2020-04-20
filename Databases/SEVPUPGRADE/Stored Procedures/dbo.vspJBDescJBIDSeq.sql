SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.[vspJBDescJBILLine]    Script Date:  ******/
CREATE PROC [dbo].[vspJBDescJBIDSeq]
/***********************************************************
* CREATED BY:  TJL 05/02/06 - Issue #28227: 6x Rewrite JBTMBillLines form
* MODIFIED By : 
*
* USAGE:
* 	Returns JBID Line/Seq Description
*
* INPUT PARAMETERS
*   JB Company
*   JB BillMonth
*	JB BillNumber
*	Line
*	LineSeq
*
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@jbco bCompany = null, @billmonth bMonth = null, @billnumber int = null, @line int = null,
	@lineseq int = null, @msg varchar(255) output)
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
if @lineseq is null
	begin
	goto vspexit
	end

select @msg = d.Description
from bJBID d with (nolock) 
where d.JBCo = @jbco and d.BillMonth = @billmonth and d.BillNumber = @billnumber
	and d.Line = @line and d.Seq = @lineseq

vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspJBDescJBIDSeq] TO [public]
GO
