SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMPCOApproveItem] as select a.* From vPMPCOApproveItem a
GO
GRANT SELECT ON  [dbo].[PMPCOApproveItem] TO [public]
GRANT INSERT ON  [dbo].[PMPCOApproveItem] TO [public]
GRANT DELETE ON  [dbo].[PMPCOApproveItem] TO [public]
GRANT UPDATE ON  [dbo].[PMPCOApproveItem] TO [public]
GO
