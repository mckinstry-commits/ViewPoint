SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vfJCIRFutureJCChgOrders](@Company int, @Mth smalldatetime, @Contract varchar(30), @Item varchar(30))
RETURNS TABLE
AS
/********************************************
* Created By:	GF 04/17/2010 - issue #139161
* Modified By:
*
* Provides a view of Future JC Change Orders for Revenue Projections.
*
********************************************/
 

RETURN (SELECT i.Item, i.ApprovedMonth,
			sum(i.ContractAmt) as 'Amt',
			sum(i.ContractUnits) as 'Units',
			h.ApprovalDate
			FROM dbo.bJCOI i with (nolock)
			join dbo.bJCOH h with (nolock) on  i.JCCo=h.JCCo and i.Job=h.Job and i.ACO=h.ACO and i.Contract=h.Contract
			where i.JCCo=@Company and i.Contract=@Contract and i.Item=@Item and i.ApprovedMonth>@Mth
			group by i.Item,i.ApprovedMonth, h.ApprovalDate)

GO
GRANT SELECT ON  [dbo].[vfJCIRFutureJCChgOrders] TO [public]
GO
