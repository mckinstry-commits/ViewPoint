SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[SMAgreementType]
AS
SELECT a.* FROM dbo.vSMAgreementType a


GO
GRANT SELECT ON  [dbo].[SMAgreementType] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementType] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementType] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementType] TO [public]
GO
