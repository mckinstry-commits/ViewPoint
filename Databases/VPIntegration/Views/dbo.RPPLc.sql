SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[RPPLc] as select a.* From vRPPLc a

GO
GRANT SELECT ON  [dbo].[RPPLc] TO [public]
GRANT INSERT ON  [dbo].[RPPLc] TO [public]
GRANT DELETE ON  [dbo].[RPPLc] TO [public]
GRANT UPDATE ON  [dbo].[RPPLc] TO [public]
GO
