SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[SMWorkCompletedDetail]
AS
SELECT *
FROM dbo.vSMWorkCompletedDetail




GO
GRANT SELECT ON  [dbo].[SMWorkCompletedDetail] TO [public]
GRANT INSERT ON  [dbo].[SMWorkCompletedDetail] TO [public]
GRANT DELETE ON  [dbo].[SMWorkCompletedDetail] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkCompletedDetail] TO [public]
GO
