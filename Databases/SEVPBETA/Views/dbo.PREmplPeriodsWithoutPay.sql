SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PREmplPeriodsWithoutPay] as select a.* From vPREmplPeriodsWithoutPay a
GO
GRANT SELECT ON  [dbo].[PREmplPeriodsWithoutPay] TO [public]
GRANT INSERT ON  [dbo].[PREmplPeriodsWithoutPay] TO [public]
GRANT DELETE ON  [dbo].[PREmplPeriodsWithoutPay] TO [public]
GRANT UPDATE ON  [dbo].[PREmplPeriodsWithoutPay] TO [public]
GO
