SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.WDJBLog
AS
SELECT * FROM dbo.vfVAWDJobLogs()
GO
GRANT SELECT ON  [dbo].[WDJBLog] TO [public]
GRANT INSERT ON  [dbo].[WDJBLog] TO [public]
GRANT DELETE ON  [dbo].[WDJBLog] TO [public]
GRANT UPDATE ON  [dbo].[WDJBLog] TO [public]
GRANT SELECT ON  [dbo].[WDJBLog] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WDJBLog] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WDJBLog] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WDJBLog] TO [Viewpoint]
GO
