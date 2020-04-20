SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementServiceRevDefer]
AS
SELECT [dbo].vSMAgreementRevenueDeferral.*
FROM [dbo].[vSMAgreementRevenueDeferral]
WHERE [vSMAgreementRevenueDeferral].[Service] IS NOT NULL


GO
GRANT SELECT ON  [dbo].[SMAgreementServiceRevDefer] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementServiceRevDefer] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementServiceRevDefer] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementServiceRevDefer] TO [public]
GRANT SELECT ON  [dbo].[SMAgreementServiceRevDefer] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMAgreementServiceRevDefer] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMAgreementServiceRevDefer] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMAgreementServiceRevDefer] TO [Viewpoint]
GO
