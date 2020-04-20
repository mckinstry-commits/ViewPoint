SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspPasswordRulesLoadProc]
/************************************************************************
* CREATED BY:    CHS 10/02/07
* MODIFIED BY:    
*
* PUPOSE: for module VC - returns the one record contained in the table
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

    declare @ReturnCode int
    select @ReturnCode = 0

SELECT 
@PasswordRuleID = PasswordRuleID, 
@IsActive = IsActive, 
@IsActive = IsActive, 
@MaxAge = MaxAge, 
@MinAge = MinAge,
@MinLength = MinLength, 
@ContainsLower = ContainsLower, 
@ContainsUpper = ContainsUpper, 
@ContainsNumeric = ContainsNumeric, 
@ContainsSpecial = ContainsSpecial, 
@SpecialCharacters = SpecialCharacters 

FROM dbo.pPasswordRules with (nolock)

	--If there is not exactly 1 record in DDVS, then the correct record may not have been used.
	if @@rowcount <> 1
	begin
		select @ErrorMessage = 'Error: pPasswordRules information could not be retrieved.', @ReturnCode = 1
		goto ExitLabel
	end

ExitLabel:
     return @ReturnCode
GO
GRANT EXECUTE ON  [dbo].[vspPasswordRulesLoadProc] TO [public]
GO
