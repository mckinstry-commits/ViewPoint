SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMChangeOrderRequestPCO] as select a.* From vPMChangeOrderRequestPCO a
GO
GRANT SELECT ON  [dbo].[PMChangeOrderRequestPCO] TO [public]
GRANT INSERT ON  [dbo].[PMChangeOrderRequestPCO] TO [public]
GRANT DELETE ON  [dbo].[PMChangeOrderRequestPCO] TO [public]
GRANT UPDATE ON  [dbo].[PMChangeOrderRequestPCO] TO [public]
GO
