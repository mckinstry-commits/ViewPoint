SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bsp_WDSave]
   /***********************************************
   *
   *    Created by: TV 01/17/03
   *
   *    Modified:
   *
   *    Purpose: to back up the WD tables
   *
   ************************************************/
   as 
   
   set nocount on
   
   
   --delete any existing records
   if (select count(*) from bWDQYSave) > 0
       begin
       delete bWDQYSave
       end  
   if (select count(*) from bWDQPSave) > 0
       begin
       delete bWDQPSave
       end  
   if (select count(*) from bWDQFSave) > 0
       begin
       delete bWDQFSave
       end  
   
   --copy out the non-standard queries and params
   insert bWDQYSave (QueryName,Description,Title,SelectClause,FromWhereClause,Standard,Notes,UniqueAttchID)
   select y.QueryName,y.Description,y.Title,y.SelectClause,y.FromWhereClause,y.Standard,y.Notes,y.UniqueAttchID
   from bWDQY y
   where y.Standard <>'Y'
   
   insert bWDQPSave (QueryName,Param,Description)
   select p.QueryName,p.Param,p.Description
   from bWDQP p join bWDQY y on p.QueryName = y.QueryName
   where y.Standard <>'Y'
   
   insert bWDQFSave(QueryName,Seq,TableColumn,EMailField)
   select p.QueryName,p.Seq,p.TableColumn,p.EMailField
   from bWDQF p join bWDQY y on p.QueryName = y.QueryName
   where y.Standard <>'Y'

GO
GRANT EXECUTE ON  [dbo].[bsp_WDSave] TO [public]
GO
