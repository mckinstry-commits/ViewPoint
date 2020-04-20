SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARMTCustAmtDue]
/*************************************************************************
* Created: TJL  08/04/05: Issue #29018, 6x Rewrite ARCashReceipts
* Modified: GG 04/10/08 - added top 100 percent and order by
*		
* Provides a Total AmountDue by Customer to be displayed in the form Header 
* based upon the sum of ARMT detail records by CustGroup, Customer.
*
*
**************************************************************************/

as
select top 100 percent 'vARCo' = ARCo, 'vCustGroup' = CustGroup,
	'vCustomer' = Customer,
	'CustAmtDue' = (isnull(sum(Invoiced),0) - isnull(sum(Retainage),0) - isnull(sum(Paid),0))
from ARMT (nolock)
group by ARCo, CustGroup, Customer
order by ARCo, CustGroup, Customer

GO
GRANT SELECT ON  [dbo].[ARMTCustAmtDue] TO [public]
GRANT INSERT ON  [dbo].[ARMTCustAmtDue] TO [public]
GRANT DELETE ON  [dbo].[ARMTCustAmtDue] TO [public]
GRANT UPDATE ON  [dbo].[ARMTCustAmtDue] TO [public]
GO
