SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROCEDURE [dbo].[vspVPColorsGetCompaniesWithOverridenThemes]

/**************************************************
* Created: JonathanP 03/12/2007
* Modified: 
*
* Used by the VPColors form to get the list of companies that have overriden color themes.
*
* Inputs:
*	@userName
*
* Output:
*	The result set will be a single column list of companies that have overriden themes.
*
*	@errorMessage
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@userName bVPUserName, @errorMessage varchar(512) output)
as
set nocount on 

declare @ReturnCode int --Not used     
select @ReturnCode = 0

-- Return the list of companies that have overriden color themes (which is denoted by having an
-- entry in vDDUC.
SELECT [Company] FROM vDDUC WHERE VPUserName = @userName
   
vspExit:
	return @ReturnCode

GO
GRANT EXECUTE ON  [dbo].[vspVPColorsGetCompaniesWithOverridenThemes] TO [public]
GO
