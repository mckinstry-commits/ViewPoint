SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRAllowanceRulesLookup]
AS
SELECT DISTINCT PRCo, AllowanceRuleName, 
	(SELECT MAX(p2.AllowanceRuleDesc)
	 FROM dbo.vPRAllowanceRules AS p2
	 WHERE p2.PRCo = p1.PRCo AND p2.AllowanceRuleName=p1.AllowanceRuleName) AS p2						
FROM  dbo.vPRAllowanceRules AS p1

--SELECT DISTINCT PRCo, AllowanceRuleName
--FROM         dbo.vPRAllowanceRules

GO
GRANT SELECT ON  [dbo].[PRAllowanceRulesLookup] TO [public]
GRANT INSERT ON  [dbo].[PRAllowanceRulesLookup] TO [public]
GRANT DELETE ON  [dbo].[PRAllowanceRulesLookup] TO [public]
GRANT UPDATE ON  [dbo].[PRAllowanceRulesLookup] TO [public]
GO
