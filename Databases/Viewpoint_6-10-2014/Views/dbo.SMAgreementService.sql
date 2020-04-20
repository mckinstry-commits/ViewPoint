SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementService]
AS
SELECT *
FROM dbo.vSMAgreementService


GO
GRANT SELECT ON  [dbo].[SMAgreementService] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementService] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementService] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementService] TO [public]
GRANT SELECT ON  [dbo].[SMAgreementService] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMAgreementService] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMAgreementService] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMAgreementService] TO [Viewpoint]
GO
