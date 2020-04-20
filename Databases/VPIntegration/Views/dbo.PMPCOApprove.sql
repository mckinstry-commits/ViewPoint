SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMPCOApprove] as select a.* From vPMPCOApprove a
GO
GRANT SELECT ON  [dbo].[PMPCOApprove] TO [public]
GRANT INSERT ON  [dbo].[PMPCOApprove] TO [public]
GRANT DELETE ON  [dbo].[PMPCOApprove] TO [public]
GRANT UPDATE ON  [dbo].[PMPCOApprove] TO [public]
GO
