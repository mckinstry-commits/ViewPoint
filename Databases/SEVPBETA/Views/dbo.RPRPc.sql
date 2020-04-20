SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[RPRPc] as select a.* From vRPRPc a

GO
GRANT SELECT ON  [dbo].[RPRPc] TO [public]
GRANT INSERT ON  [dbo].[RPRPc] TO [public]
GRANT DELETE ON  [dbo].[RPRPc] TO [public]
GRANT UPDATE ON  [dbo].[RPRPc] TO [public]
GO
