SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW dbo.DDTHUnionUDTH
/**************************************************
*	Created:	??
*	Modified:	DANF 3/16/2005 - #26761 top 100 percent, order by
*				GG 01/19/06 - VP6.0 - use vDD table
*
*	Used by:	DDTH Lookup
***************************************************/
    AS
    
SELECT top 100 percent TableName, Description
FROM dbo.vDDTH with (nolock)
UNION
SELECT top 100 percent TableName, Description
from dbo.bUDTH with (nolock)
order by TableName, Description
    
    
    
   
   
  
 




GO
GRANT SELECT ON  [dbo].[DDTHUnionUDTH] TO [public]
GRANT INSERT ON  [dbo].[DDTHUnionUDTH] TO [public]
GRANT DELETE ON  [dbo].[DDTHUnionUDTH] TO [public]
GRANT UPDATE ON  [dbo].[DDTHUnionUDTH] TO [public]
GO
