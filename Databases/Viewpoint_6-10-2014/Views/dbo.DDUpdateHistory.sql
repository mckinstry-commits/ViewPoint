SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  view [dbo].[DDUpdateHistory] as select * from dbo.vDDUpdateHistory



GO
GRANT SELECT ON  [dbo].[DDUpdateHistory] TO [public]
GRANT INSERT ON  [dbo].[DDUpdateHistory] TO [public]
GRANT DELETE ON  [dbo].[DDUpdateHistory] TO [public]
GRANT UPDATE ON  [dbo].[DDUpdateHistory] TO [public]
GRANT SELECT ON  [dbo].[DDUpdateHistory] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDUpdateHistory] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDUpdateHistory] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDUpdateHistory] TO [Viewpoint]
GO
