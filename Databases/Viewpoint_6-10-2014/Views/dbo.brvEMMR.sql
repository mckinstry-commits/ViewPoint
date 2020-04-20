SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[brvEMMR] as

Select EMCo, Mth/*BatchMonth*/,EMTrans, BatchId, InUseBatchID, Source,Equipment, PostingDate,
CAST(LEFT(CONVERT(CHAR(8), ReadingDate, 112), 6) + '01' AS datetime)  as ReadingDateMth, ReadingDate, 
PreviousHourMeter = CurrentHourMeter-[Hours], CurrentHourMeter, PreviousTotalHourMeter=CurrentTotalHourMeter-[Hours], CurrentTotalHourMeter, [Hours], 
PreviousOdometer=CurrentOdometer-Miles, CurrentOdometer, PreviousTotalOdometer=CurrentTotalOdometer-Miles, CurrentTotalOdometer,Miles
from dbo.EMMR  with(nolock)



GO
GRANT SELECT ON  [dbo].[brvEMMR] TO [public]
GRANT INSERT ON  [dbo].[brvEMMR] TO [public]
GRANT DELETE ON  [dbo].[brvEMMR] TO [public]
GRANT UPDATE ON  [dbo].[brvEMMR] TO [public]
GRANT SELECT ON  [dbo].[brvEMMR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvEMMR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvEMMR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvEMMR] TO [Viewpoint]
GO
