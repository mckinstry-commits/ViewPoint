SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[POXBGrid] 
   /*********************************
   *	Created by:	??
   *	Modified by:	MV 01/21/05 - #26761 comments,with (nolock)
   *					MV 02/23/05 - #26761 top 100 percent, order by
   *	Used by:		PO Close Form?
   ***********************************/
   as
    select top 100 percent a.* From POXB a with (nolock)
   	order by a.Co,a.Mth, a.BatchId, a.BatchSeq

GO
GRANT SELECT ON  [dbo].[POXBGrid] TO [public]
GRANT INSERT ON  [dbo].[POXBGrid] TO [public]
GRANT DELETE ON  [dbo].[POXBGrid] TO [public]
GRANT UPDATE ON  [dbo].[POXBGrid] TO [public]
GO
