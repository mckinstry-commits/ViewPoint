SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRCALimitsAndRates]
AS
(
	SELECT * FROM [dbo].[vPRCALimitsAndRates]
)
GO
GRANT SELECT ON  [dbo].[PRCALimitsAndRates] TO [public]
GRANT INSERT ON  [dbo].[PRCALimitsAndRates] TO [public]
GRANT DELETE ON  [dbo].[PRCALimitsAndRates] TO [public]
GRANT UPDATE ON  [dbo].[PRCALimitsAndRates] TO [public]
GO
