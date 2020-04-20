SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE VIEW [dbo].[SMWorkCompletedPart]
AS
SELECT a.* FROM dbo.vSMWorkCompletedPart a







GO
GRANT SELECT ON  [dbo].[SMWorkCompletedPart] TO [public]
GRANT INSERT ON  [dbo].[SMWorkCompletedPart] TO [public]
GRANT DELETE ON  [dbo].[SMWorkCompletedPart] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkCompletedPart] TO [public]
GO
