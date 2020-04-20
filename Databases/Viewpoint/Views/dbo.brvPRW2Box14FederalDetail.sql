SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************
* Copyright © 2013 Viewpoint Construction Software. All rights reserved.
* Created: CWirtz	9/20/2010 Issue 123660
* Modified:  
* 
* Purpose:   
* 	This view will return federal box 14 detail data.
* 	The federal box 14 entries are identified by PRWA.Item with specific fixed values of 40,41,46,47,51,52,53,54.
* 
********************************************************************/
CREATE VIEW [dbo].[brvPRW2Box14FederalDetail] 
AS


SELECT PRWA.PRCo, PRWA.TaxYear,PRWA.Employee,PRWA.Item,PRWA.Amount,isnull(PRWC.Description,' ') AS Description
			FROM PRWA LEFT OUTER JOIN PRWC
				ON PRWA.PRCo = PRWC.PRCo AND PRWA.TaxYear = PRWC.TaxYear AND PRWA.Item = PRWC.Item
			WHERE PRWA.Item in (40,41,46,47,51,52,53,54)

GO
GRANT SELECT ON  [dbo].[brvPRW2Box14FederalDetail] TO [public]
GRANT INSERT ON  [dbo].[brvPRW2Box14FederalDetail] TO [public]
GRANT DELETE ON  [dbo].[brvPRW2Box14FederalDetail] TO [public]
GRANT UPDATE ON  [dbo].[brvPRW2Box14FederalDetail] TO [public]
GO
