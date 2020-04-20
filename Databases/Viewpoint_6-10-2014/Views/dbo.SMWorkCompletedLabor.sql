SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[SMWorkCompletedLabor]
AS
SELECT *
FROM dbo.vSMWorkCompletedLabor

GO
GRANT SELECT ON  [dbo].[SMWorkCompletedLabor] TO [public]
GRANT INSERT ON  [dbo].[SMWorkCompletedLabor] TO [public]
GRANT DELETE ON  [dbo].[SMWorkCompletedLabor] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkCompletedLabor] TO [public]
GRANT SELECT ON  [dbo].[SMWorkCompletedLabor] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMWorkCompletedLabor] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMWorkCompletedLabor] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMWorkCompletedLabor] TO [Viewpoint]
GO
