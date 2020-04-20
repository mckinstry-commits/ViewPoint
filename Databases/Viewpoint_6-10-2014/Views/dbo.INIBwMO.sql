SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INIBwMO] as
/******************************
*
* Created by:  TRL 05/08/07
* Modified by:  
*
*
*Used to link INIB back to INMI for IN MO Entry Items
*
******************************/
Select INIB.Co,INIB.Mth, INIB.BatchId, INIB.BatchSeq,INMB.MO,INIB.MOItem From dbo.INIB with(nolock)
Left Join dbo.INMB with(nolock) on INMB.Co=INIB.Co and INMB.Mth=INIB.Mth and INMB.BatchId=INIB.BatchId and INMB.BatchSeq=INIB.BatchSeq

GO
GRANT SELECT ON  [dbo].[INIBwMO] TO [public]
GRANT INSERT ON  [dbo].[INIBwMO] TO [public]
GRANT DELETE ON  [dbo].[INIBwMO] TO [public]
GRANT UPDATE ON  [dbo].[INIBwMO] TO [public]
GRANT SELECT ON  [dbo].[INIBwMO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INIBwMO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INIBwMO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INIBwMO] TO [Viewpoint]
GO
