SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMChangeOrderRequest] as select a.* From vPMChangeOrderRequest a
GO
GRANT SELECT ON  [dbo].[PMChangeOrderRequest] TO [public]
GRANT INSERT ON  [dbo].[PMChangeOrderRequest] TO [public]
GRANT DELETE ON  [dbo].[PMChangeOrderRequest] TO [public]
GRANT UPDATE ON  [dbo].[PMChangeOrderRequest] TO [public]
GO
