SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    view [dbo].[RPRTc] as select a.* From dbo.vRPRTc a

GO
GRANT SELECT ON  [dbo].[RPRTc] TO [public]
GRANT INSERT ON  [dbo].[RPRTc] TO [public]
GRANT DELETE ON  [dbo].[RPRTc] TO [public]
GRANT UPDATE ON  [dbo].[RPRTc] TO [public]
GRANT SELECT ON  [dbo].[RPRTc] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPRTc] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPRTc] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPRTc] TO [Viewpoint]
GO
