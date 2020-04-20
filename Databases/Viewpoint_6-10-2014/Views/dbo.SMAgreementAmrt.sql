SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementAmrt]
AS
SELECT *
FROM dbo.vSMAgreementAmrt
GO
GRANT SELECT ON  [dbo].[SMAgreementAmrt] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementAmrt] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementAmrt] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementAmrt] TO [public]
GRANT SELECT ON  [dbo].[SMAgreementAmrt] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMAgreementAmrt] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMAgreementAmrt] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMAgreementAmrt] TO [Viewpoint]
GO
