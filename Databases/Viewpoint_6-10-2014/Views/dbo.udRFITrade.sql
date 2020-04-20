SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udRFITrade] as select a.* From budRFITrade a
GO
GRANT SELECT ON  [dbo].[udRFITrade] TO [public]
GRANT INSERT ON  [dbo].[udRFITrade] TO [public]
GRANT DELETE ON  [dbo].[udRFITrade] TO [public]
GRANT UPDATE ON  [dbo].[udRFITrade] TO [public]
GO
