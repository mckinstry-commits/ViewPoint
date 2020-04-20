SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRAULimitsAndRates] as select a.* From vPRAULimitsAndRates a
GO
GRANT SELECT ON  [dbo].[PRAULimitsAndRates] TO [public]
GRANT INSERT ON  [dbo].[PRAULimitsAndRates] TO [public]
GRANT DELETE ON  [dbo].[PRAULimitsAndRates] TO [public]
GRANT UPDATE ON  [dbo].[PRAULimitsAndRates] TO [public]
GRANT SELECT ON  [dbo].[PRAULimitsAndRates] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAULimitsAndRates] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAULimitsAndRates] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAULimitsAndRates] TO [Viewpoint]
GO
