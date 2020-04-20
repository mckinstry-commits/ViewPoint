SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VCPasswordRules]
AS
SELECT * --PasswordRuleID, IsActive, MaxAge, MinLength, MinAge, ContainsLower, ContainsUpper, ContainsNumeric, ContainsSpecial, SpecialCharacters
FROM dbo.pPasswordRules
GO
GRANT SELECT ON  [dbo].[VCPasswordRules] TO [public]
GRANT INSERT ON  [dbo].[VCPasswordRules] TO [public]
GRANT DELETE ON  [dbo].[VCPasswordRules] TO [public]
GRANT UPDATE ON  [dbo].[VCPasswordRules] TO [public]
GO
