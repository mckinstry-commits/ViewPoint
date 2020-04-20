SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/*****************************************
* Created By:	Dan So	03/30/2011
* Modfied By:
*
*
*****************************************/

CREATE view [dbo].[PMPOCO] as
select a.*
from dbo.vPMPOCO a


























GO
GRANT SELECT ON  [dbo].[PMPOCO] TO [public]
GRANT INSERT ON  [dbo].[PMPOCO] TO [public]
GRANT DELETE ON  [dbo].[PMPOCO] TO [public]
GRANT UPDATE ON  [dbo].[PMPOCO] TO [public]
GO
