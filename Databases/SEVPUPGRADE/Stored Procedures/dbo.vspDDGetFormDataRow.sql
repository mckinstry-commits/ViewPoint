SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************
* Created: CJG 5/5/11
* MODIFIED:	
*			
*			
* This gets the data row for a forms KeyID
*
* Inputs:
*	@Form
*	@KeyId
*	
*
* Output:
*	data row for the given Form/KeyId
*
* Return code:
*
****************************************************/
CREATE PROCEDURE [dbo].[vspDDGetFormDataRow]
	@Form VARCHAR(30),
	@KeyID BIGINT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    CREATE TABLE #formQryTmp
	(
		query VARCHAR(MAX)
	)
	INSERT INTO #formQryTmp
	EXEC vspVPGetFilteredFormQuery @Form

	DECLARE @sql NVARCHAR(MAX)

	SELECT @sql = query FROM #formQryTmp
	
	EXEC sp_executesql @sql, N'@KEYID int', @KEYID = @KeyID
END

GO
GRANT EXECUTE ON  [dbo].[vspDDGetFormDataRow] TO [public]
GO
