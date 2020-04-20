SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[DDUDGrid] 
   /**************************************************
   *	Created:	??
   *	Modified:	DANF 3/16/2005 - #26761 top 100 percent, order by
   *	Used by:	IM IMRecordTypes 
   ***************************************************/
   as 
   
   select top 100 percent a.TableName, a.Form 
   From dbo.bDDUD a with (nolock)
   where isnull(a.TableName,'') <> ''
   group by a.TableName, a.Form
   order by a.TableName, a.Form

GO
GRANT SELECT ON  [dbo].[DDUDGrid] TO [public]
GRANT INSERT ON  [dbo].[DDUDGrid] TO [public]
GRANT DELETE ON  [dbo].[DDUDGrid] TO [public]
GRANT UPDATE ON  [dbo].[DDUDGrid] TO [public]
GO
