SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE dbo.vpspPasswordRulesUpdate
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
	exec vspPasswordRulesUpdate @IsActive,	@MinAge, @MaxAge, @MinLength, @ContainsLower, @ContainsUpper, @ContainsNumeric, @ContainsSpecial, @SpecialCharacters, @Original_PasswordRuleID, @Original_ContainsLower, @Original_ContainsNumeric, @Original_ContainsSpecial, @Original_ContainsUpper, @Original_IsActive, @Original_MaxAge, @Original_MinAge, @Original_MinLength, @Original_SpecialCharacters, @PasswordRuleID
GO
GRANT EXECUTE ON  [dbo].[vpspPasswordRulesUpdate] TO [VCSPortal]
GO
