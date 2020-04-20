SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[vf_rptJCPreviousCost]
				(@JCCo tinyint,
				 @Contract varchar(10),
				 @BeginMth smalldatetime)

/*****CREATED:  9/8/11 DH
  MODIFIED:
  
  USAGE:  Returns cost amounts for all months prior to the beginning month.  
		  Used to select a total amount for all months before the first month 
		  in a SQL statement returning a range of months (like a beginning balance).
		  
*******/

RETURNS TABLE
AS
RETURN (

SELECT
	SUM(CurrEstCost) as CurrentEstCost,
	SUM(ActualCost) as ActualCost,
	SUM(ProjCost) as ProjectedCost
FROM
	JCCP
WHERE
	JCCP.JCCo=@JCCo and JCCP.Job=@Contract and JCCP.Mth < @BeginMth
)

			
	

GO
GRANT SELECT ON  [dbo].[vf_rptJCPreviousCost] TO [public]
GO
