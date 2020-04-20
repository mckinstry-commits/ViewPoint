SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPGetRecentUserItems]
/**************************************************
* Created: CC 08/15/2008
* Modified: CC 07/09/2009 - Issue #129922 - Add culture to pass to forms for culture specific form titles.
*			CC 07/15/2009 - Issue #133695 - Hide forms that are not applicable to the current country
*			
*	
*	Gets top n most recently viewed items for the given user.
* 
*
* Inputs:
*	@co					Company
*	@User				Username
*	@NumberOfItems		Number of items to display
*	@Type				Forms, Reports, or both
*	@Mod				Module to return items for
*
* Output:
*	resultset	Reports with access info
*	@errmsg		Error message

*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/

(@co bCompany = 0, 
@User bVPUserName = NULL,
@NumberOfItems int = 0,
@Type VARCHAR(30) = NULL,
@Mod VARCHAR(2) = NULL,
@SubFolder int = 0,
@culture INT = NULL,
@country CHAR(2) = NULL,
@errmsg VARCHAR(512) OUTPUT)

AS


DECLARE	@return_value int

IF @Type = 'Report'
	EXEC @return_value = [dbo].[vspVPGetRecentUserReports]
		@co = @co,
		@User = @User,
		@NumberOfReports = @NumberOfItems,
		@country = @country,
		@errmsg = @errmsg OUTPUT

IF @Type = 'Form'
	EXEC	@return_value = [dbo].[vspVPGetRecentUserForms]
			@co = @co,
			@User = @User,
			@NumberOfForms = @NumberOfItems,
			@culture = @culture,
			@country = @country,
			@errmsg = @errmsg OUTPUT

IF @Type = 'Menu'
	IF (ISNULL(@Mod,'') = '' AND ISNULL(@co,0) = 0) OR (ISNULL(@Mod,'') <> '' AND ISNULL(@co,0) <> 0)
		EXEC	@return_value = [dbo].[vspVPMenuGetSubFolderItems]
				@co = @co,
				@mod = @Mod,
				@subfolder = @SubFolder,
				@culture = @culture,
				@country = @country,
				@errmsg = @errmsg OUTPUT
	ELSE
		EXEC	@return_value = [dbo].[vspVPMenuGetCompanySubFolderItems]
				@co = @co,
				@subfolder = @SubFolder,
				@culture = @culture,
				@country = @country,
				@errmsg = @errmsg OUTPUT




GO
GRANT EXECUTE ON  [dbo].[vspVPGetRecentUserItems] TO [public]
GO
