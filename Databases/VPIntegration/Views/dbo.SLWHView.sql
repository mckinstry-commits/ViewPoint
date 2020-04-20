SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--ALTER  view SLWHView as select distinct SLCo, JCCo, Job from SLWH
   CREATE   view [dbo].[SLWHView]
   /***************************************
   *	Created by:	??
   *	Modified by:	MV 01/21/05 - with nolock
   *	Used by:		SL WorkSheet Form
   ****************************************/
    as
    select SLCo, SL, JCCo, Job, UniqueAttchID from SLWH with (nolock)

GO
GRANT SELECT ON  [dbo].[SLWHView] TO [public]
GRANT INSERT ON  [dbo].[SLWHView] TO [public]
GRANT DELETE ON  [dbo].[SLWHView] TO [public]
GRANT UPDATE ON  [dbo].[SLWHView] TO [public]
GO
