SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementServiceDate]
AS
SELECT *
FROM dbo.vSMAgreementServiceDate
GO
GRANT SELECT ON  [dbo].[SMAgreementServiceDate] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementServiceDate] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementServiceDate] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementServiceDate] TO [public]
GO
