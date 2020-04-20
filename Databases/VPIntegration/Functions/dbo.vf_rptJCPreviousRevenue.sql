SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vf_rptJCPreviousRevenue]
				(@JCCo tinyint,
				 @Contract varchar(10),
				 @BeginMth smalldatetime)

/*****CREATED:  9/8/11 DH
  MODIFIED:
  
  USAGE:  Returns revenue amounts for all months prior to the beginning month.  
		  Used to select a total amount for all months before the first month 
		  in a SQL statement returning a range of months (like a beginning balance).
		  
*******/

RETURNS TABLE
AS
RETURN (

SELECT
	SUM(ContractAmt) as ContractAmount,
	SUM(BilledAmt) as BilledAmount,
	SUM(ProjDollars) as ProjectedRevenue
FROM
	JCIP
WHERE
	JCIP.JCCo=@JCCo and JCIP.Contract=@Contract and JCIP.Mth < @BeginMth
)

			
	
GO
GRANT SELECT ON  [dbo].[vf_rptJCPreviousRevenue] TO [public]
GO
