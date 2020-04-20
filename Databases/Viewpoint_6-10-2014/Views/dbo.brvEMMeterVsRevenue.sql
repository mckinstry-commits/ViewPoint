SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 
  
   
   CREATE view [dbo].[brvEMMeterVsRevenue] as
   
   select EMCo, Mth, Equipment, RD_HourReading = HourReading, RD_PrevHourReading = PreviousHourReading,
   MR_CurrentTotalHourMeter = 0, MR_PreviousTotalHourMeter=0
   from dbo.EMRD  with(nolock)
   UNION ALL
   select EMCo, ReadingDateMth, Equipment, RD_HourReading=0, RD_PrevHourReading=0, CurrentTotalHourMeter, PreviousTotalHourMeter from dbo.brvEMMR with(nolock)
   
   
  
 





GO
GRANT SELECT ON  [dbo].[brvEMMeterVsRevenue] TO [public]
GRANT INSERT ON  [dbo].[brvEMMeterVsRevenue] TO [public]
GRANT DELETE ON  [dbo].[brvEMMeterVsRevenue] TO [public]
GRANT UPDATE ON  [dbo].[brvEMMeterVsRevenue] TO [public]
GRANT SELECT ON  [dbo].[brvEMMeterVsRevenue] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvEMMeterVsRevenue] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvEMMeterVsRevenue] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvEMMeterVsRevenue] TO [Viewpoint]
GO
