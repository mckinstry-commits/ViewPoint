SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**********************************************************
  Purpose:  
	Calculates the number of PAYG Individual non-business
	payment summaries an Australian company	has issued during a tax year  
			
  Maintenance Log:
	Coder	Date	Issue#	Description of Change
	CWirtz	4/01/11	142504	New
********************************************************************/
CREATE  VIEW [dbo].[vrvPRPAYGCountETPPaymentSummaries] AS

SELECT PRCo,TaxYear,COUNT(*)AS ETPPaymentSummaries
FROM
	(
		SELECT DISTINCT(Seq),PRCo,TaxYear,Employee
		FROM dbo.PRAUEmployeeETPAmounts
		GROUP BY PRCo,TaxYear,Employee,Seq
	)x
GROUP BY PRCo,TaxYear


GO
GRANT SELECT ON  [dbo].[vrvPRPAYGCountETPPaymentSummaries] TO [public]
GRANT INSERT ON  [dbo].[vrvPRPAYGCountETPPaymentSummaries] TO [public]
GRANT DELETE ON  [dbo].[vrvPRPAYGCountETPPaymentSummaries] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRPAYGCountETPPaymentSummaries] TO [public]
GRANT SELECT ON  [dbo].[vrvPRPAYGCountETPPaymentSummaries] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPRPAYGCountETPPaymentSummaries] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPRPAYGCountETPPaymentSummaries] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPRPAYGCountETPPaymentSummaries] TO [Viewpoint]
GO
