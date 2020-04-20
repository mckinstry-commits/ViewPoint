SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.PRAllowanceRuleSet 
AS
SELECT * FROM dbo.vPRAllowanceRuleSet
GO
GRANT SELECT ON  [dbo].[PRAllowanceRuleSet] TO [public]
GRANT INSERT ON  [dbo].[PRAllowanceRuleSet] TO [public]
GRANT DELETE ON  [dbo].[PRAllowanceRuleSet] TO [public]
GRANT UPDATE ON  [dbo].[PRAllowanceRuleSet] TO [public]
GO
