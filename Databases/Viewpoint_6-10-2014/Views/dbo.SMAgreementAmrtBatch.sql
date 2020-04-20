SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementAmrtBatch]
AS
SELECT *
FROM dbo.vSMAgreementAmrtBatch
GO
GRANT SELECT ON  [dbo].[SMAgreementAmrtBatch] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementAmrtBatch] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementAmrtBatch] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementAmrtBatch] TO [public]
GRANT SELECT ON  [dbo].[SMAgreementAmrtBatch] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMAgreementAmrtBatch] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMAgreementAmrtBatch] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMAgreementAmrtBatch] TO [Viewpoint]
GO
