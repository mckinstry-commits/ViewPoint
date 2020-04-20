SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE dbo.vspPasswordRulesUpdate
(
	@IsActive bit,
	@MinAge int,
	@MaxAge int,
	@MinLength int,
	@ContainsLower bit,
	@ContainsUpper bit,
	@ContainsNumeric bit,
	@ContainsSpecial bit,
	@SpecialCharacters varchar(255),
	@Original_PasswordRuleID int,
	@Original_ContainsLower bit,
	@Original_ContainsNumeric bit,
	@Original_ContainsSpecial bit,
	@Original_ContainsUpper bit,
	@Original_IsActive bit,
	@Original_MaxAge int,
	@Original_MinAge int,
	@Original_MinLength int,
	@Original_SpecialCharacters varchar(255),
	@PasswordRuleID int
)
AS
	SET NOCOUNT OFF;
UPDATE pPasswordRules SET IsActive = @IsActive, MinAge = @MinAge, MaxAge = @MaxAge, MinLength = @MinLength, ContainsLower = @ContainsLower, ContainsUpper = @ContainsUpper, ContainsNumeric = @ContainsNumeric, ContainsSpecial = @ContainsSpecial, SpecialCharacters = @SpecialCharacters WHERE (PasswordRuleID = @Original_PasswordRuleID) AND (ContainsLower = @Original_ContainsLower) AND (ContainsNumeric = @Original_ContainsNumeric) AND (ContainsSpecial = @Original_ContainsSpecial) AND (ContainsUpper = @Original_ContainsUpper) AND (IsActive = @Original_IsActive) AND (MaxAge = @Original_MaxAge) AND (MinAge = @Original_MinAge) AND (MinLength = @Original_MinLength) AND (SpecialCharacters = @Original_SpecialCharacters);
	SELECT PasswordRuleID, IsActive, MinAge, MaxAge, MinLength, ContainsLower, ContainsUpper, ContainsNumeric, ContainsSpecial, SpecialCharacters FROM pPasswordRules WHERE (PasswordRuleID = @PasswordRuleID)


GO
GRANT EXECUTE ON  [dbo].[vspPasswordRulesUpdate] TO [public]
GO
