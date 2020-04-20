SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   view [dbo].[SLIBGrid]
   /***************************************
   *	Created by:	??
   *	Modified by:	MV 01/21/05 - #26761 comments,with nolock
   *					MV 02/23/05 - #26761 top 100 percent, order by
   *	Used by:		SL EntryItems Form
   ****************************************/
    as
   select top 100 percent * from SLIB with (nolock) order by Co, Mth, BatchId, BatchSeq, SLItem



GO
GRANT SELECT ON  [dbo].[SLIBGrid] TO [public]
GRANT INSERT ON  [dbo].[SLIBGrid] TO [public]
GRANT DELETE ON  [dbo].[SLIBGrid] TO [public]
GRANT UPDATE ON  [dbo].[SLIBGrid] TO [public]
GRANT SELECT ON  [dbo].[SLIBGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SLIBGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SLIBGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SLIBGrid] TO [Viewpoint]
GO
