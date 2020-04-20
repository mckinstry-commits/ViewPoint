SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


Create  VIEW [dbo].[vrvSMInvoiceListOnlyInvoiced]
AS

/***********************************************************************    
Author: 
Scott Alvey
   
Create date: 
09/04/2012  
    
Usage:
Feeds a report a list of SM Invoies that have only been Invoiced.
Used in some reports in a left join because filtering a left join
from Crystal Reports can be a bit tricky. This is an easier way of
meeting the filter needs.

Parameters:  
N/A

Related reports: 
AR Customer Accounts by Customer (ID: 88)  
    
Revision History    
Date  Author  Issue     Description

***********************************************************************/  

SELECT
	*
FROM
	SMInvoiceList
WHERE
	InvoiceStatus = 'Invoiced'


GO
GRANT SELECT ON  [dbo].[vrvSMInvoiceListOnlyInvoiced] TO [public]
GRANT INSERT ON  [dbo].[vrvSMInvoiceListOnlyInvoiced] TO [public]
GRANT DELETE ON  [dbo].[vrvSMInvoiceListOnlyInvoiced] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMInvoiceListOnlyInvoiced] TO [public]
GO
