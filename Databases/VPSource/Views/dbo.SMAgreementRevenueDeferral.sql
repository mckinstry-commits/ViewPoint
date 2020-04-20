SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementRevenueDeferral]
AS
SELECT     *
FROM [dbo].[vSMAgreementRevenueDeferral];


GO
GRANT SELECT ON  [dbo].[SMAgreementRevenueDeferral] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementRevenueDeferral] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementRevenueDeferral] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementRevenueDeferral] TO [public]
GO
