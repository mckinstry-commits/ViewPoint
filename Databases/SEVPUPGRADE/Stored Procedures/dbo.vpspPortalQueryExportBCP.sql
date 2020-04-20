SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vpspPortalQueryExportBCP]
(
    @Name varchar(100),
	@Query varchar(2000),
	@Filepath varchar(100),
    @User varchar(100),
    @Password varchar(100)
)
AS
--Usage: Export the data of the passed in table with the Bulk Copy Program
--Note:  TableName should be passed in with the format Databasename.dbo.TableName

DECLARE @FileName varchar(255),
		@bcpCommand varchar(2000)

--Create the Filename
--SET @FileName = 'd:\VPDev\Portal\data\' + @TableName + '.bcp'
SET @FileName = @Filepath + @Name + '.bcp'

PRINT 'FileName: ' + @FileName

--Create the Bulk copy program command
SET @bcpCommand = 'bcp "' + @Query + '" queryout ' + @FileName + ' -t\t -r\n -c -U' + @User + ' -P' + @Password 

PRINT 'Command: ' + @bcpCommand

--Execute the Bulk copy command to export the table to the given filepath and name
EXEC master..xp_cmdshell @bcpCommand





GO
GRANT EXECUTE ON  [dbo].[vpspPortalQueryExportBCP] TO [VCSPortal]
GO
