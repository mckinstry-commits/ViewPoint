SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBMoveGridFill]
/****************************************************************************
* CREATED BY: 	MV  12/19/11 - TK10767
* MODIFIED BY:	MV	12/21/11 - TK10767 restrict by BillType 'P'- progress
*
* USAGE:
* 	Fills  move grid in JB
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
(@JBCo bCompany = null, @BillMth bMonth = null)

AS
SET NOCOUNT ON
DECLARE @rcode integer
SELECT @rcode = 0

/* Fill the grid  */
SELECT n.BillMonth,	n.ProcessGroup, p.Description, n.Invoice, n.BillNumber,n.InvTotal,n.Customer,
   		a.Name,n.Contract, c.Description AS [ContractDesc], n.InvStatus,InitFlag = 'N', n.CreatedBy
FROM dbo.bJBIN n (NOLOCK)
LEFT JOIN dbo.bJBPG p (NOLOCK) on p.JBCo = n.JBCo and p.ProcessGroup = n.ProcessGroup
LEFT JOIN dbo.bARCM a WITH (NOLOCK) ON a.CustGroup = n.CustGroup and a.Customer = n.Customer  -- to get Customer Name
LEFT JOIN dbo.bJCCM c WITH (NOLOCK) ON c.JCCo = n.JBCo AND c.[Contract] = n.[Contract]  -- to get Contract Description
WHERE n.JBCo = @JBCo and n.BillMonth = isnull(@BillMth, n.BillMonth) AND n.BillType = 'P' 
	AND n.InvStatus = 'A' AND n.InUseMth IS NULL AND n.InUseBatchId IS NULL
ORDER BY n.BillMonth, n.Contract, n.Customer,n.BillNumber
	
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBMoveGridFill] TO [public]
GO
