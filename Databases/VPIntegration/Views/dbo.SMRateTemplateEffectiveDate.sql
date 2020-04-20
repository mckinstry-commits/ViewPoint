SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMRateTemplateEffectiveDate]
AS

SELECT *
FROM dbo.vSMRateTemplateEffectiveDate
GO
GRANT SELECT ON  [dbo].[SMRateTemplateEffectiveDate] TO [public]
GRANT INSERT ON  [dbo].[SMRateTemplateEffectiveDate] TO [public]
GRANT DELETE ON  [dbo].[SMRateTemplateEffectiveDate] TO [public]
GRANT UPDATE ON  [dbo].[SMRateTemplateEffectiveDate] TO [public]
GO
