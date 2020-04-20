SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bsp_WDRecover]
   /***********************************************
   *
   *    Created by: TV 01/17/03
   *
   *    Modified:
   *
   *    Purpose: to Restore the WD tables
   *
   ************************************************/
   as 
   
   set nocount on
   
   
   insert bWDQY (QueryName,Description,Title,SelectClause,FromWhereClause,Standard,Notes,UniqueAttchID)
   select y.QueryName,y.Description,y.Title,y.SelectClause,y.FromWhereClause,y.Standard,y.Notes,y.UniqueAttchID
   from bWDQYSave y
   where y.Standard <>'Y' and not exists (select QueryName from bWDQY y2 where y.QueryName = y2.QueryName)
   
   insert  bWDQP (QueryName,Param,Description)
   select p.QueryName,p.Param,p.Description
   from  bWDQPSave p join bWDQY y on p.QueryName = y.QueryName
   where y.Standard <>'Y' and not exists (select QueryName from bWDQP p2 where p.QueryName = p2.QueryName)
   
   
   insert bWDQF(QueryName,Seq,TableColumn,EMailField)
   select p.QueryName,p.Seq,p.TableColumn,p.EMailField
   from  bWDQFSave p join bWDQY y on p.QueryName = y.QueryName
   where y.Standard <>'Y'  and not exists (select QueryName from bWDQF p2 where p.QueryName = p2.QueryName)

GO
GRANT EXECUTE ON  [dbo].[bsp_WDRecover] TO [public]
GO
