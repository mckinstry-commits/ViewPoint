SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDGetFormFilterSettings]
/********************************    
* Created: CC 2010-01-07   
* Modified: 
*    
* Input:    
* @FormName - the form to retrieve filter settings for
* @UserName - the user to retrieve filter settings for
* @Company	- the company to retrieve filter settings for, currently unused
*    
* Output: returns the field sequences used in filtering, and their value.
*    
* Return code: none
*    
*********************************/
	@FormName	VARCHAR(30),
	@UserName	VARCHAR(128),
	@Company	bCompany
AS
BEGIN
	SELECT FieldSeq, FilterValue
	FROM DDFormFilters
	WHERE	FormName = @FormName
			AND VPUserName = @UserName;
			--AND Company = @Company;

END
GO
GRANT EXECUTE ON  [dbo].[vspDDGetFormFilterSettings] TO [public]
GO
