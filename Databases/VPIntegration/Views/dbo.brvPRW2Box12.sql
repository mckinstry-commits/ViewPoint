SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************
* Copyright © 2013 Viewpoint Construction Software. All rights reserved.
* Created: 
* Modified:  CWirtz	9/20/2010 Issue 123660  Added Description field(PRWI.Description)
* 
* Purpose:  
* 	Return Box 12 information for W2 reporting
* 
******************************************************************/
CREATE   view [dbo].[brvPRW2Box12] as select PRWA.PRCo, PRWA.TaxYear, Employee, PRWA.Item, PRWA.ItemID, PRWA.Seq, W2Code, PRWI.Description,Amount,
       CountItem=(select count(distinct b.Item) From PRWA b
                  Join PRWI wi on wi.TaxYear=b.TaxYear and wi.Item=b.Item where PRWA.PRCo=b.PRCo 
                    and PRWA.TaxYear=b.TaxYear and PRWA.Employee=b.Employee 
                    and b.Item<=PRWA.Item and (wi.W2Code is not null and wi.W2Code<>''))
    From PRWA 
    Join PRWI on PRWI.TaxYear=PRWA.TaxYear and PRWI.Item=PRWA.Item
    Where (PRWI.W2Code is not null and PRWI.W2Code<>'')

GO
GRANT SELECT ON  [dbo].[brvPRW2Box12] TO [public]
GRANT INSERT ON  [dbo].[brvPRW2Box12] TO [public]
GRANT DELETE ON  [dbo].[brvPRW2Box12] TO [public]
GRANT UPDATE ON  [dbo].[brvPRW2Box12] TO [public]
GO
