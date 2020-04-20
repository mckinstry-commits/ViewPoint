SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.BITargetDetail
AS
SELECT * FROM dbo.vBITargetDetail
GO
GRANT SELECT ON  [dbo].[BITargetDetail] TO [public]
GRANT INSERT ON  [dbo].[BITargetDetail] TO [public]
GRANT DELETE ON  [dbo].[BITargetDetail] TO [public]
GRANT UPDATE ON  [dbo].[BITargetDetail] TO [public]
GO
