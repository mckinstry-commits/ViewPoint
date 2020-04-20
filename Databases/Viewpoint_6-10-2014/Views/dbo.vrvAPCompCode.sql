SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[vrvAPCompCode] as 

select APCo, UserId, Mth, APTrans, APLine, APSeq, HoldYN, PayYN, DiscTaken, Amount, 
POCompCode=null, PODesc=null, SLCompCode=null, SLDesc=null, APCompCode=null, APDesc=null
from APWD

Union all

select POCo, null, '1/1/1950', 0, 0, 0, null, null, 0, 0, 
CompCode, POCT.Description,null,null,null,null
from POCT
JOIN APTL with (nolock) ON  
 		APTL.APCo=POCT.POCo AND  
 		APTL.PO=POCT.PO

Union all

select SLCo, null, '1/1/1950', 0, 0, 0, null, null, 0, 0,
null, null, CompCode, SLCT.Description,null,null
from SLCT
JOIN APTL with (nolock) ON  
 		APTL.APCo=SLCT.SLCo AND  
 	    APTL.SL=SLCT.SL

Union all

select APCo, null, '1/1/1950', 0, 0, 0, null, null, 0, 0,
null, null, null, null, HQCP.CompCode, HQCP.Description
from APVC
JOIN HQCP with (nolock) ON
        HQCP.CompCode=APVC.CompCode AND
        HQCP.AllInvoiceYN='Y'




GO
GRANT SELECT ON  [dbo].[vrvAPCompCode] TO [public]
GRANT INSERT ON  [dbo].[vrvAPCompCode] TO [public]
GRANT DELETE ON  [dbo].[vrvAPCompCode] TO [public]
GRANT UPDATE ON  [dbo].[vrvAPCompCode] TO [public]
GRANT SELECT ON  [dbo].[vrvAPCompCode] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvAPCompCode] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvAPCompCode] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvAPCompCode] TO [Viewpoint]
GO
