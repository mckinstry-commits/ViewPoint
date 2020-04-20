SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDMAttachmentIndexSearch]
-- =============================================
-- Author:		Rick Mogstad
-- Create date: 06/30/10	
-- Modified by AL 10/11/10
-- Description:	Performs the search (potentially cross database) as viewpointcs
-- =============================================
(@searchsql nvarchar(max),@fulltextsearchjoin varchar(max),@hqatfilter varchar(max))
WITH EXECUTE AS 'viewpointcs'
as
SET NOCOUNT ON

DECLARE @originaluser varchar(256)

SELECT @originaluser = ORIGINAL_LOGIN()

DECLARE @attachmentgridcolumns TABLE (ColumnName varchar(MAX))
INSERT INTO @attachmentgridcolumns exec vspDMGetAttachmentIndexSearchGridColumnOrder @originaluser

DECLARE @usercolumns varchar(max)
		
IF (select count(*) from @attachmentgridcolumns) = 0
BEGIN
--if there are no columns in the DMAttachmentGridColumnOrder table use this
	DECLARE @attachmentgridoptions TABLE (SysColumn varchar(max),UserColumn varchar(max))
	INSERT INTO @attachmentgridoptions exec vspDMAttachmentGridOptionsLoad @originaluser

	SELECT @usercolumns = isnull(COALESCE(@usercolumns + ', ','') + 'i.' + UserColumn,@usercolumns) from @attachmentgridoptions

	IF @usercolumns is not null
	BEGIN
		SELECT @usercolumns = @usercolumns + ','
	END


	SELECT @searchsql = 'SELECT HQAT.AttachmentID,HQAT.DocName,HQAT.Description,
						HQAT.AddDate, HQAT.FormName, HQAT.OrigFileName, 
						t.Name as AttachmentType, ' 
						+ isnull(@usercolumns,'') + 
						' CASE HQAT.CurrentState WHEN ''A'' THEN ''Attached'' WHEN ''S'' THEN ''Stand Alone''  WHEN ''D'' THEN ''Deleted'' END AS CurrentState'
						+ ' FROM HQAT ' +
						'LEFT JOIN DMAttachmentTypesShared t ON HQAT.AttachmentTypeID = t.AttachmentTypeID ' + 
						'LEFT JOIN HQAI i ON HQAT.AttachmentID = i.AttachmentID ' +
				  @fulltextsearchjoin +
				  ' WHERE ' + @searchsql + @hqatfilter
 END 
--Else: Get all of the columns out of the DMAttachmentGridColumnOrder table to use in the select statement.
ELSE
BEGIN

	SELECT @usercolumns = isnull(COALESCE(@usercolumns + ', ','') + ColumnName,@usercolumns) from @attachmentgridcolumns
	
	--SET @usercolumns = LEFT(@usercolumns, LEN(@usercolumns) - 2)
		SELECT @searchsql = 'SELECT ' + isnull(@usercolumns,'')
						+ ' FROM HQAT ' +
						'LEFT JOIN DMAttachmentTypesShared t ON HQAT.AttachmentTypeID = t.AttachmentTypeID ' + 
						'LEFT JOIN HQAI i ON HQAT.AttachmentID = i.AttachmentID ' +
				  @fulltextsearchjoin +
				  ' WHERE ' + @searchsql + @hqatfilter
END

PRINT @searchsql

exec sp_executesql @searchsql


GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentIndexSearch] TO [public]
GO
