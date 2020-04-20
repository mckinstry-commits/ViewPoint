SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE view [dbo].[PCBidMessageHistory] as select a.*, a.DateSent as [TimeSent] From vPCBidMessageHistory a









GO
GRANT SELECT ON  [dbo].[PCBidMessageHistory] TO [public]
GRANT INSERT ON  [dbo].[PCBidMessageHistory] TO [public]
GRANT DELETE ON  [dbo].[PCBidMessageHistory] TO [public]
GRANT UPDATE ON  [dbo].[PCBidMessageHistory] TO [public]
GO
