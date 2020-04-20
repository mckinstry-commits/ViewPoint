SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE dbo.vspPasswordRulesInsert
(
	@IsActive bit,
	@MinAge int,
	@MaxAge int,
	@MinLength int,
	@ContainsLower bit,
	@ContainsUpper bit,
	@ContainsNumeric bit,
	@ContainsSpecial bit,
	@SpecialCharacters varchar(255)
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPasswordRules(IsActive, MinAge, MaxAge, MinLength, ContainsLower, ContainsUpper, ContainsNumeric, ContainsSpecial, SpecialCharacters) VALUES (@IsActive, @MinAge, @MaxAge, @MinLength, @ContainsLower, @ContainsUpper, @ContainsNumeric, @ContainsSpecial, @SpecialCharacters);
	SELECT PasswordRuleID, IsActive, MinAge, MaxAge, MinLength, ContainsLower, ContainsUpper, ContainsNumeric, ContainsSpecial, SpecialCharacters FROM pPasswordRules WHERE (PasswordRuleID = SCOPE_IDENTITY())



GO
GRANT EXECUTE ON  [dbo].[vspPasswordRulesInsert] TO [public]
GO
