SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPasswordRulesLoadProc]
/************************************************************************
* CREATED BY:    CHS 10/02/07
* MODIFIED BY:    
*
* PURPOSE: for module VC - returns the one record contained in the table
*	pPasswordRules
*************************************************************************/

(@PasswordRuleID int = NULL output, 
@IsActive tinyint = NULL output, 
@MinAge int = NULL output, 
@MaxAge int = NULL output, 
@MinLength int = NULL output, 
@ContainsLower tinyint = NULL output, 
@ContainsUpper tinyint = NULL output, 
@ContainsNumeric tinyint = NULL output, 
@ContainsSpecial tinyint = NULL output, 
@SpecialCharacters varchar(255) = NULL output,
@ErrorMessage varchar(80) = '' output)

AS
	SET NOCOUNT ON;
	--Create the return code and set it to zero.

   return exec vspPasswordRulesLoadProc @PasswordRuleID, @IsActive, @MinAge, @MaxAge, @MinLength, @ContainsLower, @ContainsUpper, @ContainsNumeric, @ContainsSpecial, @SpecialCharacters,@ErrorMessage
   
GO
GRANT EXECUTE ON  [dbo].[vpspPasswordRulesLoadProc] TO [VCSPortal]
GO
