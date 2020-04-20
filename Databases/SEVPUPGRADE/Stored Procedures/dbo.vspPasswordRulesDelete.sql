SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE dbo.vspPasswordRulesDelete
(
	@Original_PasswordRuleID int,
	@Original_ContainsLower bit,
	@Original_ContainsNumeric bit,
	@Original_ContainsSpecial bit,
	@Original_ContainsUpper bit,
	@Original_IsActive bit,
	@Original_MaxAge int,
	@Original_MinAge int,
	@Original_MinLength int,
	@Original_SpecialCharacters varchar(255)
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPasswordRules WHERE (PasswordRuleID = @Original_PasswordRuleID) AND (ContainsLower = @Original_ContainsLower) AND (ContainsNumeric = @Original_ContainsNumeric) AND (ContainsSpecial = @Original_ContainsSpecial) AND (ContainsUpper = @Original_ContainsUpper) AND (IsActive = @Original_IsActive) AND (MaxAge = @Original_MaxAge) AND (MinAge = @Original_MinAge) AND (MinLength = @Original_MinLength) AND (SpecialCharacters = @Original_SpecialCharacters)


GO
GRANT EXECUTE ON  [dbo].[vspPasswordRulesDelete] TO [public]
GO
