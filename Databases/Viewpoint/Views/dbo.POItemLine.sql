SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*****************************************
* Created By:	GF 07/21/2011 - TK-07029 6.4.1 Q4 release
* Modfied By:	
*
*
* Provides a base view of PO Item Distribution Lines
*
*****************************************/


CREATE view [dbo].[POItemLine] as select a.* From vPOItemLine a


GO
GRANT SELECT ON  [dbo].[POItemLine] TO [public]
GRANT INSERT ON  [dbo].[POItemLine] TO [public]
GRANT DELETE ON  [dbo].[POItemLine] TO [public]
GRANT UPDATE ON  [dbo].[POItemLine] TO [public]
GO
