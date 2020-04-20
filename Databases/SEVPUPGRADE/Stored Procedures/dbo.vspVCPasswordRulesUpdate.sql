SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVCPasswordRulesUpdate]
/************************************************************************
* CREATED BY:	chs 10/04/07
*
* Purpose of Stored Procedure:
*
*	Update Procedure for pPasswordRules from VC winform
*
* Returns:
*	0 if successful.
*	1 and an error message if failed.
*
*************************************************************************/

(@PasswordRuleID int,
@IsActive tinyint,
@MinAge int,
@MaxAge int,
@MinLength int,
@ContainsLower tinyint,
@ContainsUpper tinyint,
@ContainsNumeric tinyint,
@ContainsSpecial tinyint,
@SpecialCharacters varchar(255),
@ErrorMessage varchar(80) = '' output)

AS
SET NOCOUNT ON
	
	--Create the return code and set it to zero.
    declare @ReturnCode int
    select @ReturnCode = 0

	--Do the update.
	UPDATE pPasswordRules SET 

IsActive = @IsActive,
MinAge = @MinAge,
MaxAge = @MaxAge,
MinLength = @MinLength,
ContainsLower = @ContainsLower,
ContainsUpper = @ContainsUpper,
ContainsNumeric = @ContainsNumeric,
ContainsSpecial = @ContainsSpecial,
SpecialCharacters = @SpecialCharacters

Where PasswordRuleID = @PasswordRuleID


ExitLabel:
	--Return 0 on success, 1 on failure.
	return @ReturnCode


GO
GRANT EXECUTE ON  [dbo].[vspVCPasswordRulesUpdate] TO [public]
GO
