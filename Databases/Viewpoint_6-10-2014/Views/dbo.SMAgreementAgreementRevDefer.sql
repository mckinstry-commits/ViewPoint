SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementAgreementRevDefer]
AS
SELECT [dbo].vSMAgreementRevenueDeferral.*
FROM [dbo].[vSMAgreementRevenueDeferral]
WHERE [vSMAgreementRevenueDeferral].[Service] IS NULL


GO
GRANT SELECT ON  [dbo].[SMAgreementAgreementRevDefer] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementAgreementRevDefer] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementAgreementRevDefer] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementAgreementRevDefer] TO [public]
GRANT SELECT ON  [dbo].[SMAgreementAgreementRevDefer] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMAgreementAgreementRevDefer] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMAgreementAgreementRevDefer] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMAgreementAgreementRevDefer] TO [Viewpoint]
GO
