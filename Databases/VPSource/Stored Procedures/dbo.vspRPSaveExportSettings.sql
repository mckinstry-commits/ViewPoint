SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspRPSaveExportSettings]
/***********************************************************
 * CREATED BY: Nitor 12/16/2011 (Split out vspRPSaveExportSettings - which should now be obsolete)
 * MODIFIED BY: 
 *
 *USAGE:
 * Save the Default Export settings for the given report/username combination. 
 * 
 * INPUT PARAMETERS
 *    @username					VPUserName
 *    @reportid					ReportID
 *    @deafultexportoption      String (128)  
 *    @lastaccessdate			small date time
 *
 * OUTPUT PARAMETERS
 *    @msg           error message from
 *
 * RETURN VALUE
 *    none
 *****************************************************/
	(@username VARCHAR(128) = NULL,
	 @reportid INT = NULL,
	 @deafultexportoption VARCHAR(128) = null, 
	 @lastaccessdate SMALLDATETIME = NULL, 
	 @msg VARCHAR(255) OUTPUT
	) 
AS 

SET NOCOUNT OFF
DECLARE @rcode INT
SELECT @rcode = 0

IF @username is null
	BEGIN
		SELECT @msg = 'Missing VP User Name', @rcode = 1
		GOTO vspexit
	END

IF @reportid is null or @reportid = 0
	BEGIN
		SELECT @msg = 'Missing ReportID', @rcode = 1
		GOTO vspexit
	END

IF @reportid >0 
	BEGIN
		IF (SELECT COUNT(*) FROM RPRTShared WHERE ReportID = @reportid) = 0
			BEGIN
				SELECT @msg = 'VP User:  ' + @username + 'Report ID: ' + CONVERT(VARCHAR,ISNULL(@reportid , 0)) + 'does not exist!', @rcode = 1
				GOTO vspexit
			END
	END

IF (SELECT COUNT(*) FROM dbo.vRPUP WHERE VPUserName = @username AND ReportID = @reportid)= 0
	BEGIN
		INSERT INTO vRPUP  (VPUserName, ReportID, ExportFormat, LastAccessed)
		VALUES( @username, @reportid, @deafultexportoption, @lastaccessdate)
		IF @@ROWCOUNT =0
			BEGIN
				SELECT @msg = 'VP User:  ' + @username + 'Report ID: ' + CONVERT(VARCHAR,ISNULL(@reportid,0)) + ' did not insert!', @rcode = 1
				GOTO vspexit
			END
	END
ELSE
	BEGIN
		UPDATE dbo.vRPUP
		SET ExportFormat= ISNULL(@deafultexportoption, ExportFormat), 
		LastAccessed = ISNULL(@lastaccessdate, LastAccessed)
		FROM dbo.vRPUP  WHERE VPUserName = @username AND ReportID = @reportid

		IF @@ROWCOUNT =0
		BEGIN
			SELECT @msg = 'VP User:  ' + @username + 'Report ID: ' + CONVERT(VARCHAR,ISNULL(@reportid,0)) + ' did not update!', @rcode = 1
			GOTO vspexit
		END
	END

vspexit:
	IF @rcode <> 0
	SELECT @msg =  @msg + CHAR(13) + CHAR(10) + '[vspRPSaveExportSettings]'	
	RETURN @rcode




GO
GRANT EXECUTE ON  [dbo].[vspRPSaveExportSettings] TO [public]
GO
