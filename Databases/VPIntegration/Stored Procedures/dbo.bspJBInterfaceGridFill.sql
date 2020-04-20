SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBInterfaceGridFill]
/****************************************************************************
* CREATED BY: 	bc  10/19/99
* MODIFIED BY:	TJL 10/17/03:  Issue #20863, Provide Option to include bills without Inv#s
*		TJL 07/01/04:  Issue #25005, Show All ProcessGroup Invoice when checked/input null
*		TJL 12/29/04 - Issue #26472, Add SortOrder by BillMonth, BillNumber
*		TJL 01/05/06 - Issue #28055, 6x ReCode JBInterface form.
*		TJL 01/09/09 - Issue #120173, Combine Auto Init forms, add CreatedBy, filter by CreatedBy
*		MV	12/20/11 - TK-10767 - return InvTotal and Contract Desc
*
* USAGE:
* 	Fills grid in JB
*
* INPUT PARAMETERS:
*
* OUTPUT PARAMETERS:
*	See Select statement below
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@jbco bCompany = null, @billmth bMonth = null, @restrictflag bYN = 'N', @processgroup varchar(20) = null, @initflag bYN = 'N',
	@woinvoiceflag bYN = 'N', @createdby bVPUserName = null)

as
set nocount on
declare @rcode integer
select @rcode = 0

if @woinvoiceflag = 'N'		--unchecked show NULL Invoice
	begin
	/* Fill the grid  */
	select n.BillMonth,	n.ProcessGroup, p.Description, n.Invoice, n.BillNumber,n.InvTotal,n.Customer,
   		a.Name,n.Contract, c.Description AS [ContractDesc], n.InvStatus, InitFlag = @initflag, n.CreatedBy
	from bJBIN n with (nolock)
	left join bJBPG p with (nolock) on p.JBCo = n.JBCo and p.ProcessGroup = n.ProcessGroup
	LEFT JOIN bARCM a WITH (NOLOCK) ON a.CustGroup = n.CustGroup and a.Customer = n.Customer  -- to get Customer Name
    LEFT JOIN bJCCM c WITH (NOLOCK) ON c.JCCo = n.JBCo AND c.[Contract] = n.[Contract]  -- to get Contract Description
	where n.JBCo = @jbco and n.BillMonth = isnull(@billmth, n.BillMonth)
		and isnull(n.CreatedBy, '') = isnull(@createdby, isnull(n.CreatedBy, ''))
		and ((@restrictflag = 'Y' and ((n.ProcessGroup = isnull(@processgroup,'')) or (@processgroup is null and n.ProcessGroup is not Null))) or
  			(@restrictflag = 'N' and isnull(n.ProcessGroup,'') = isnull(n.ProcessGroup,'')))
  		and n.InvStatus in ('A','C','D') and n.Invoice is not null and n.InUseMth is null and n.InUseBatchId is null
	order by n.BillMonth, n.BillNumber
	end

if @woinvoiceflag = 'Y'		--checked show NULL Invoice
	begin
	/* Fill the grid  */
	select n.BillMonth,	n.ProcessGroup, p.Description, n.Invoice, n.BillNumber,n.InvTotal,n.Customer,
   		a.Name,n.Contract, c.Description AS [ContractDesc], n.InvStatus,InitFlag = 'N', n.CreatedBy
	from bJBIN n with (nolock)
	left join bJBPG p with (nolock) on p.JBCo = n.JBCo and p.ProcessGroup = n.ProcessGroup
	LEFT JOIN bARCM a WITH (NOLOCK) ON a.CustGroup = n.CustGroup and a.Customer = n.Customer  -- to get Customer Name
    LEFT JOIN bJCCM c WITH (NOLOCK) ON c.JCCo = n.JBCo AND c.[Contract] = n.[Contract]  -- to get Contract Description
	where n.JBCo = @jbco and n.BillMonth = isnull(@billmth, n.BillMonth)
		and isnull(n.CreatedBy, '') = isnull(@createdby, isnull(n.CreatedBy, ''))
		and ((@restrictflag = 'Y' and ((n.ProcessGroup = isnull(@processgroup,'')) or (@processgroup is null and n.ProcessGroup is not Null))) or
  			(@restrictflag = 'N' and isnull(n.ProcessGroup,'') = isnull(n.ProcessGroup,'')))
  		and n.InvStatus in ('A','C','D') and n.InUseMth is null and n.InUseBatchId is null
	order by n.BillMonth, n.BillNumber
	end
	
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBInterfaceGridFill] TO [public]
GO
