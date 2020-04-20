SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPCopyWorkCenterInLibrary]
/***********************************************************
* CREATED BY:   HH 03/29/2013 TFS 45214
* MODIFIED BY:  
*
* Usage: Used by VA Work Center Library to copy work center
*	
*
* Input params:
*	@SourceKeyID
*	@SourceName
*	@SourceOwner	
*	@DestinationName
*	@DestinationOwner
* Output params:
*	
*
* Return code:
*
*	
************************************************************/
@SourceKeyID int = null,
@SourceName varchar(50) = null,
@SourceOwner bVPUserName = null,
@DestinationName varchar(50) = null,
@DestinationOwner bVPUserName = null,
@msg VARCHAR(255) OUTPUT

AS
BEGIN
SET NOCOUNT ON

IF @DestinationName IS NULL OR LTRIM(RTRIM(@DestinationName)) = ''
	BEGIN
		SELECT @msg = 'Missing Name.'
		RETURN
	END

IF @DestinationOwner IS NULL OR LTRIM(RTRIM(@DestinationOwner)) = ''
	BEGIN
		SELECT @msg = 'Missing Owner.'
		RETURN
	END

IF NOT EXISTS (SELECT TOP 1 1 FROM DDUPExtended WHERE VPUserName = @DestinationOwner)
	BEGIN
		SELECT @msg = 'Invalid Owner "' + @DestinationOwner + '".'
		RETURN
	END

IF EXISTS (SELECT TOP 1 1 FROM vVPWorkCenterUserLibrary WHERE UPPER(LibraryName) = UPPER(@DestinationName) AND [Owner] = @DestinationOwner)
	BEGIN
		SELECT @msg = '"' + @DestinationName + '" already exists for Owner "' + @DestinationOwner + '".'
		RETURN
	END

	INSERT INTO vVPWorkCenterUserLibrary (LibraryName, [Owner], WorkCenterInfo, PublicShare, DateModified, Notes)
		SELECT @DestinationName, @DestinationOwner, WorkCenterInfo, PublicShare, GETDATE(), Notes
		FROM vVPWorkCenterUserLibrary
		WHERE LibraryName = @SourceName AND [Owner] = @SourceOwner AND KeyID = @SourceKeyID;

END


GO
GRANT EXECUTE ON  [dbo].[vspVPCopyWorkCenterInLibrary] TO [public]
GO
