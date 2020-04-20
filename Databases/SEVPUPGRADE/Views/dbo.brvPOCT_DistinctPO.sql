SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   
CREATE  view [dbo].[brvPOCT_DistinctPO]
    
/**************
  Created	6/21/2011 HH - Added Complied logic: 
				Any Compliance Codes from POCT Where Expiration Date is on 
				or before the current system date or where the Complied flag = N.  
				Should return N if one compliance code is out of compliance according 
				to the definition above, else return Y.
				
				     
 Usage:  Used by the PM Vendor Register Drilldown report to display the Compliance Details for POs.  
         View returns one line per PO

**************/

AS

WITH POCTDistinct (POCo, PO, CompliedLogic)
AS
(
	SELECT		POCo,
				PO,
				CASE
					WHEN Complied = 'N' AND Verify = 'Y' THEN 'N'
					WHEN ISNULL(ExpDate, '2050-12-31') <= GETDATE() AND Verify = 'Y' THEN 'N'
					ELSE 'Y'
				END AS CompliedLogic
	FROM POCT
)
SELECT	POCo, 
		PO, 
		Min(CompliedLogic) AS Complied
FROM POCTDistinct
GROUP BY POCo, PO
  


GO
GRANT SELECT ON  [dbo].[brvPOCT_DistinctPO] TO [public]
GRANT INSERT ON  [dbo].[brvPOCT_DistinctPO] TO [public]
GRANT DELETE ON  [dbo].[brvPOCT_DistinctPO] TO [public]
GRANT UPDATE ON  [dbo].[brvPOCT_DistinctPO] TO [public]
GO
