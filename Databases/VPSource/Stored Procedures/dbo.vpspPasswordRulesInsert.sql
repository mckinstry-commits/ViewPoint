SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE dbo.vpspPasswordRulesInsert
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
	exec vspPasswordRulesInsert @IsActive,	@MinAge, @MaxAge, @MinLength, @ContainsLower, @ContainsUpper, @ContainsNumeric,	@ContainsSpecial, @SpecialCharacters

GO
GRANT EXECUTE ON  [dbo].[vpspPasswordRulesInsert] TO [VCSPortal]
GO
