SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    view [dbo].[RPRMc] as select a.* From vRPRMc a

GO
GRANT SELECT ON  [dbo].[RPRMc] TO [public]
GRANT INSERT ON  [dbo].[RPRMc] TO [public]
GRANT DELETE ON  [dbo].[RPRMc] TO [public]
GRANT UPDATE ON  [dbo].[RPRMc] TO [public]
GRANT SELECT ON  [dbo].[RPRMc] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPRMc] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPRMc] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPRMc] TO [Viewpoint]
GO
