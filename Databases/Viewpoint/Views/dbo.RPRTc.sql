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
GO
