SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[SMWorkCompletedMisc]
AS
SELECT *
FROM dbo.vSMWorkCompletedMisc




GO
GRANT SELECT ON  [dbo].[SMWorkCompletedMisc] TO [public]
GRANT INSERT ON  [dbo].[SMWorkCompletedMisc] TO [public]
GRANT DELETE ON  [dbo].[SMWorkCompletedMisc] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkCompletedMisc] TO [public]
GO
