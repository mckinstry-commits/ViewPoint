SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE  view [dbo].[brvSLCT_DistinctSL]
    
/**************
 Created	1/25/05 Nadine F.
 Modified:	6/21/2011 HH - Added Complied logic: 
				Any Compliance Codes from SLCT Where Expiration Date is on 
				or before the current system date or where the Complied flag = N.  
				Should return N if one compliance code is out of compliance according 
				to the definition above, else return Y.
				
				     
 Usage:  Used by the SL Drilldown report to display the Compliance Details for SL's.  
         View returns one line per SL

**************/

AS

WITH SLCTDistinct (SLCo, SL, CompliedLogic)
AS
(
	SELECT		SLCo,
				SL,
				CASE
					WHEN Complied = 'N' AND Verify = 'Y' THEN 'N'
					WHEN ISNULL(ExpDate, '2050-12-31') <= GETDATE() AND Verify = 'Y' THEN 'N'
					ELSE 'Y'
				END AS CompliedLogic
	FROM SLCT
)
SELECT	SLCo, 
		SL, 
		Min(CompliedLogic) AS Complied
FROM SLCTDistinct
GROUP BY SLCo, SL
  

GO
GRANT SELECT ON  [dbo].[brvSLCT_DistinctSL] TO [public]
GRANT INSERT ON  [dbo].[brvSLCT_DistinctSL] TO [public]
GRANT DELETE ON  [dbo].[brvSLCT_DistinctSL] TO [public]
GRANT UPDATE ON  [dbo].[brvSLCT_DistinctSL] TO [public]
GO
