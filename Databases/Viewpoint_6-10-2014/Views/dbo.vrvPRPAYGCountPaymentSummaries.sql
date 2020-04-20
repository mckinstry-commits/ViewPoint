SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/**********************************************************
  Purpose:  
	Calculates the number of payments summaries an Australian 
	company	issued during a tax year  
			
  Maintenance Log:
	Coder	Date	Issue#	Description of Change
	CWirtz	4/01/11	142504	New
********************************************************************/
CREATE  VIEW [dbo].[vrvPRPAYGCountPaymentSummaries] AS

SELECT PRCo,TaxYear,COUNT(*)AS PaymentSummaries
FROM
	(
		SELECT DISTINCT(SummarySeq),PRCo,TaxYear,Employee
		FROM dbo.PRAUEmployeeItemAmounts
		GROUP BY PRCo,TaxYear,Employee,SummarySeq
	)x
 GROUP BY PRCo,TaxYear



GO
GRANT SELECT ON  [dbo].[vrvPRPAYGCountPaymentSummaries] TO [public]
GRANT INSERT ON  [dbo].[vrvPRPAYGCountPaymentSummaries] TO [public]
GRANT DELETE ON  [dbo].[vrvPRPAYGCountPaymentSummaries] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRPAYGCountPaymentSummaries] TO [public]
GRANT SELECT ON  [dbo].[vrvPRPAYGCountPaymentSummaries] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPRPAYGCountPaymentSummaries] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPRPAYGCountPaymentSummaries] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPRPAYGCountPaymentSummaries] TO [Viewpoint]
GO
