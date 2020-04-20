SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE       PROCEDURE [dbo].[vpspPortalImportBCP]
(
	@TableName varchar(100),
	@BCPFile varchar(100)
)
AS

DECLARE @SQLString varchar(1000), 
		@ExecuteString NVARCHAR(1000)

--Check to see if the Install table exists, if it doesn't then create it
IF Object_ID(@TableName) IS NOT NULL
	BEGIN
	
	--Empty the table
	--SET @SQLString = 'TRUNCATE TABLE ' + @TableName 
	--Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
	--exec sp_executesql @ExecuteString

	--Insert all the data from the BCP file into the INSTALL table keeping the identity's the same
	--SET @SQLString = 'BULK INSERT ' + @TableName + ' FROM ''' + @BCPFile + ''' WITH (KEEPIDENTITY, DATAFILETYPE = ''native'')'
	
	SET @SQLString = 'BULK INSERT ' + @TableName + ' FROM ''' + @BCPFile + ''' WITH (KEEPIDENTITY, DATAFILETYPE = ''char'', FIELDTERMINATOR = ''\t'', ROWTERMINATOR = ''\n'' )'
	Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
	exec sp_executesql @ExecuteString

	END










GO
GRANT EXECUTE ON  [dbo].[vpspPortalImportBCP] TO [VCSPortal]
GO
