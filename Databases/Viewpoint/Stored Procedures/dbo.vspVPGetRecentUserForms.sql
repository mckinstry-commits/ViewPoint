SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPGetRecentUserForms]
/**************************************************
* Created: CC 08/15/2008
* Modified: 
*			CC 02/26/2009 Issue #132457 - Ignore errors from security check
*			CC 07/09/2009 Issue #129922 - Add culture to pass to forms for culture specific form titles.
*			CC 07/15/2009 - Issue #133695 - Hide forms that are not applicable to the current country
*			
* This procedure returns the top n (most recent) Forms that the user has access to
* for the given company
*
* Inputs:
*	@co				Company
*	@User			Username
*	@NumberOfForms	Number of forms to return
*
* Output:
*	resultset	Forms with access info
*	@errmsg		Error message

*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/

(@co bCompany = null, 
@User bVPUserName = null, 
@NumberOfForms int = 0,
@culture INT = NULL,
@country CHAR(2) = NULL,
@errmsg VARCHAR(512) OUTPUT)

AS

SET NOCOUNT ON

DECLARE @rcode int, 
		@opencursor tinyint, 
		@form VARCHAR(30),
		@access tinyint, 
		@formaccess tinyint
	
IF @co IS NULL
	BEGIN
		SELECT @errmsg = 'Missing required input parameter(s): Company #', @rcode = 1
		GOTO vspexit
	END

SELECT @rcode = 0

-- use a local table to hold all Forms for the Module
DECLARE @allforms TABLE(
						MenuItem varchar(30), 
						Title varchar(30),
						IconKey varchar(20),
						LastAccessed datetime, 
						Accessible char(1),
						AssemblyName varchar(50), 
						FormClassName varchar(50)
						)

	INSERT @allforms (MenuItem, Title, IconKey, LastAccessed, Accessible, AssemblyName, FormClassName)
	SELECT	m.Form, 
			ISNULL(CultureText.CultureText, h.Title) AS Title,
			h.IconKey,
			u.LastAccessed, 
			'Y', 
			h.AssemblyName, 
			h.FormClassName	
	FROM DDMFShared m (NOLOCK)
	INNER JOIN DDFHShared h (NOLOCK) ON h.Form = m.Form
	INNER JOIN DDMO o (NOLOCK) ON h.Mod = o.Mod	AND o.Mod <> 'DD'-- join on form's primary module
	LEFT OUTER JOIN DDFU u (NOLOCK) ON u.Form = m.Form AND u.VPUserName = @User
	LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture AND CultureText.TextID = h.TitleID
	LEFT OUTER JOIN dbo.DDFormCountries ON h.Form = dbo.DDFormCountries.Form
	WHERE	m.Active = 'Y' 
			AND h.ShowOnMenu = 'Y' 
			AND o.LicLevel > 0 
			AND o.LicLevel >= h.LicLevel
			AND (dbo.DDFormCountries.Country = @country OR dbo.DDFormCountries.Country IS NULL)

	IF @User = 'viewpointcs' GOTO return_results	-- Viewpoint system user has access to all forms 

-- create a cursor to process each Form
DECLARE vcForms CURSOR LOCAL FAST_FORWARD FOR
	SELECT MenuItem FROM @allforms

OPEN vcForms
SET @opencursor = 1

form_loop:	-- check Security for each Form
	FETCH NEXT FROM vcForms INTO @form
	IF @@fetch_status <> 0 GOTO end_form_loop

	EXEC @rcode = vspDDFormSecurity @co, @form, @access = @formaccess OUTPUT, @errmsg = @errmsg OUTPUT
	
	UPDATE @allforms
	SET Accessible = CASE 
						WHEN @formaccess IN (0,1) THEN 'Y' 
						ELSE 'N' 
					 END
	WHERE MenuItem = @form

	GOTO form_loop

end_form_loop:	--  all Forms checked
	CLOSE vcForms
	DEALLOCATE vcForms
	SELECT @opencursor = 0

return_results:	-- return resultset
	SELECT TOP (@NumberOfForms) 
				MenuItem, 
				Title, 
				IconKey,
				LastAccessed, 
				AssemblyName, 
				FormClassName
	FROM @allforms
	WHERE Accessible = 'Y'
	ORDER BY LastAccessed DESC
   
vspexit:
	IF @opencursor = 1
		BEGIN
			CLOSE vcForms
			DEALLOCATE vcForms
		END

	IF @rcode <> 0 
		SELECT @errmsg = @errmsg + CHAR(13) + CHAR(10) + '[vspVPMenuGetModuleForms]'
	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspVPGetRecentUserForms] TO [public]
GO
