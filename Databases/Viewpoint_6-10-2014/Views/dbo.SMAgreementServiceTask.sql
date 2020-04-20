SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementServiceTask]
AS
SELECT *
FROM dbo.vSMAgreementServiceTask


GO
GRANT SELECT ON  [dbo].[SMAgreementServiceTask] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementServiceTask] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementServiceTask] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementServiceTask] TO [public]
GRANT SELECT ON  [dbo].[SMAgreementServiceTask] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMAgreementServiceTask] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMAgreementServiceTask] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMAgreementServiceTask] TO [Viewpoint]
GO
