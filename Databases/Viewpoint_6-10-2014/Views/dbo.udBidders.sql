SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udBidders] as select a.* From budBidders a
GO
GRANT SELECT ON  [dbo].[udBidders] TO [public]
GRANT INSERT ON  [dbo].[udBidders] TO [public]
GRANT DELETE ON  [dbo].[udBidders] TO [public]
GRANT UPDATE ON  [dbo].[udBidders] TO [public]
GO
