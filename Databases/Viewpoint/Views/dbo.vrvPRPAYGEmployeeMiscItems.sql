SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







/**********************************************************
* Copyright © 2013 Viewpoint Construction Software. All rights reserved.
* Created: CWirtz	9/20/2010 Issue 123660
*
* 
* Purpose:  
* 	This view will return PAYG Employee miscellanous item amounts.  
*   It also creates a row number base on the partitioning by 
*   PRCo,TaxYear,Employee,SummarySeq, ItemCode.  This row number will be 
*   used to determine what data is will go on page 1 or page 2
*   of the PAYG payment summary Individual Non Business report.
* 
* 
******************************************************************/
CREATE VIEW [dbo].[vrvPRPAYGEmployeeMiscItems] 
AS

SELECT PRCo,TaxYear,Employee,SummarySeq,ItemCode,EDLType,EDLCode,ISNULL(Amount,0)AS Amount,OrganizationName,AllowanceDesc 
,ROW_NUMBER() OVER (PARTITION BY PRCo,TaxYear,Employee,SummarySeq, ItemCode ORDER BY EDLType,EDLCode) AS RowNumber
FROM dbo.PRAUEmployeeMiscItemAmounts
WHERE (Amount IS NOT NULL) AND Amount <> 0





GO
GRANT SELECT ON  [dbo].[vrvPRPAYGEmployeeMiscItems] TO [public]
GRANT INSERT ON  [dbo].[vrvPRPAYGEmployeeMiscItems] TO [public]
GRANT DELETE ON  [dbo].[vrvPRPAYGEmployeeMiscItems] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRPAYGEmployeeMiscItems] TO [public]
GO
