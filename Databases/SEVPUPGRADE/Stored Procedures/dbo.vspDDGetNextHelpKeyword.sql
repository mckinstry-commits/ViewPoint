SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************
* CREATED:	AL 6/16/09     
* MODIFIED:	AR 12/20/2010 -142549 - looking for the help lookup server
*
* Purpose:	 Query returns the next available help keyword by module,
			leaving @form in to keep app consistent and record the form that the change is in

* returns 1 and error msg if failed
*
*************************************************************************/
 
CREATE PROCEDURE [dbo].[vspDDGetNextHelpKeyword] ( @form varchar(30) )
AS 
SET NOCOUNT ON ;  
SET XACT_ABORT ON;

DECLARE @result bigint 
DECLARE @Ver varchar(20)

--just check the server for NETDEVEL existing
IF NOT EXISTS (SELECT 1 FROM sys.servers AS s WHERE [name] = 'NETDEVEL')
BEGIN
	RAISERROR ('You cannot add help context on this server without the Documentation Database',15,1)
END 

BEGIN TRY
	-- make this dynamic so it doesn't blow up
	DECLARE @tsql VARCHAR(MAX)
	SET @tsql = '    SET XACT_ABORT ON
					DECLARE @result bigint 
					DECLARE @Ver varchar(20)
					SELECT @Ver = [Version] FROM dbo.vDDVS WITH (NOLOCK)
	
					INSERT INTO NETDEVEL.Documentation.dbo.HelpContextNumber ([Version], [Form])
					VALUES (@Ver,''' + @form + ''')

					SELECT @result = MAX(HelpContextID)
					FROM NETDEVEL.Documentation.dbo.HelpContextNumber
					WHERE Form = ''' + @form + '''

					SELECT @result'
	DECLARE @tblID TABLE (ReturnResult INT)
	DECLARE @ReturnResult int
	INSERT INTO @tblID
	        ( ReturnResult )
	EXEC (@tsql)
	
	SELECT @ReturnResult = ReturnResult
	FROM @tblID
	
	RETURN ISNULL(@ReturnResult,0)
	
END TRY
BEGIN CATCH
	DECLARE @Err VARCHAR(MAX)
	SET @Err = ERROR_MESSAGE()
	RAISERROR (@Err,15,1)
	--RAISERROR ('Error adding the help context ID, verify the Documentation database has been updated',15,1)
END CATCH



GO
GRANT EXECUTE ON  [dbo].[vspDDGetNextHelpKeyword] TO [public]
GO
