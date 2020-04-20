SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE        procedure [dbo].[vpspPortalLicenseTypeChanges]
/********************************
* Created: Tom Jochums
* Modified:		AR - 4/7/2011 - 142200 - wrapping brackets around the database name
*
* Retrieves all PortalLicenseTypes that exist in the newer database
*
* Parameters: 
*   @SourceDB:		The database name to copy data from.	
*	@TargetDB:		The database name to copy data to.
*
* Returns:
*   RecordSet 1:  Deleted License Types
*   RecordSet 2:  Added License Types
*********************************/
(
	@SourceDB VARCHAR(100),
	@TargetDB VARCHAR(100)
)
AS
	DECLARE @Name VARCHAR(100),
		@SQLString VARCHAR(1000),
		@ExecuteString NVARCHAR(1000),
		@Debug BIT

	-- Set to 0 for no comments, 1 to print comments
	SET @Debug = 0
	--------------------------------------------------------
	---- Synch pLicenseType table - this is a special handler so we don't blow out the assigned license counts
	---- but make sure the checksums and names get properly updated.
	SET @Name = 'pLicenseType'
			/** Retrieve Deleted License Types*/
	SET @SQLString = 'SELECT d.* FROM ' + QUOTENAME(@TargetDB) + '.[dbo].' + QUOTENAME(@Name) + ' d'
		+ '  LEFT JOIN ' + QUOTENAME(@SourceDB) + '.[dbo].' + @Name + ' s'
		+ ' ON s.LicenseTypeID = d.LicenseTypeID WHERE s.LicenseTypeID IS NULL'
	SELECT @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
	EXEC sp_executesql @ExecuteString 
	
	/** Retrieve ADDED License Types*/
	SET @SQLString = 'SELECT d.* FROM ' + QUOTENAME(@SourceDB) + '.[dbo].' + QUOTENAME(@Name) + ' d'
		+ '  LEFT JOIN ' + QUOTENAME(@TargetDB) + '.[dbo].' + @Name + ' s'
		+ ' ON s.LicenseTypeID = d.LicenseTypeID WHERE s.LicenseTypeID IS NULL'
	SELECT @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
	EXEC sp_executesql @ExecuteString 


GO
GRANT EXECUTE ON  [dbo].[vpspPortalLicenseTypeChanges] TO [VCSPortal]
GO
