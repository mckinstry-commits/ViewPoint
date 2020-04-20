SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udPMDailyLogTrade] as select a.* From budPMDailyLogTrade a
GO
GRANT SELECT ON  [dbo].[udPMDailyLogTrade] TO [public]
GRANT INSERT ON  [dbo].[udPMDailyLogTrade] TO [public]
GRANT DELETE ON  [dbo].[udPMDailyLogTrade] TO [public]
GRANT UPDATE ON  [dbo].[udPMDailyLogTrade] TO [public]
GO
