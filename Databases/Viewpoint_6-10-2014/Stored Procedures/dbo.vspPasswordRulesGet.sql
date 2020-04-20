SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


AS
	SET NOCOUNT ON;
SELECT PasswordRuleID, IsActive, MinAge, MaxAge, MinLength, ContainsLower, ContainsUpper, ContainsNumeric, ContainsSpecial, SpecialCharacters FROM pPasswordRules


GO
GRANT EXECUTE ON  [dbo].[vspPasswordRulesGet] TO [public]
GO