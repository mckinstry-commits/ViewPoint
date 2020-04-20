SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBDescJBITItem    Script Date:  ******/
CREATE PROC [dbo].[vspJBDescJBITItem]
/***********************************************************
* CREATED BY:  TJL 02/15/06 - Issue #28051: 6x Rewrite JBProgressBillItems form
* MODIFIED By : 
*
* USAGE:
* 	Returns JBIT Bill Item Description
*
* INPUT PARAMETERS
*   JB Company
*   JB BillMonth
*	JB BillNumber
*	JB BillItem
*
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@jbco bCompany = null, @billmonth bMonth = null, @billnumber int = null, @contract bContract, @item bContractItem = null, 
	@jcciretainpct bPct output, @msg varchar(255) output)
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
if @item is null
	begin
	goto vspexit
	end
Else
   	begin
 	select @msg = t.Description, @jcciretainpct = c.RetainPCT 
	from bJBIT t with (nolock) 
	join bJCCI c with (nolock) on c.JCCo = t.JBCo and c.Contract = t.Contract
	where t.JBCo = @jbco and t.BillMonth = @billmonth and t.BillNumber = @billnumber 
		and t.Contract = @contract and t.Item = @item
   	end

vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspJBDescJBITItem] TO [public]
GO
