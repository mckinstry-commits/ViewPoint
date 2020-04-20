SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE dbo.vspViewRefresher
--------------------------------------------------
-- Created: GG 08/19/05
-- Modified:
--
-- This procedure refreshes all views within the current database
--
--------------------------------------------------
AS 
    SET nocount ON

    DECLARE @name VARCHAR(60),
			@tsql VARCHAR(120)

-- create a cursor to process all Views
    DECLARE bcView CURSOR LOCAL FAST_FORWARD
    FOR
        SELECT  name
        FROM    sysobjects
        WHERE   type = 'V'
        ORDER BY name

    OPEN bcView

    FETCH NEXT FROM bcView INTO @name

    WHILE @@fetch_status = 0 
    BEGIN
		BEGIN TRY
			SELECT  @tsql = 'sp_refreshview ''' + @name + ''''
			EXEC(@tsql)
			FETCH NEXT FROM bcView INTO @name
		END TRY
		BEGIN CATCH
			PRINT 'unable to refresh '+ @name
			PRINT 'Error Number: ' + CONVERT(varchar(12),ERROR_NUMBER())
			PRINT 'Error Severity: '+ CONVERT(varchar(12),ERROR_SEVERITY())
			PRINT 'Error State: '+ CONVERT(varchar(12),ERROR_STATE())
			PRINT 'Error Procedure: '+ ERROR_PROCEDURE()
			PRINT 'Error Line: '+ CONVERT(varchar(12),ERROR_LINE())
			PRINT 'Error Message: '+ CONVERT(varchar(12),ERROR_MESSAGE())
			
			IF @@TRANCOUNT <> 0 BEGIN ROLLBACK TRAN END
		END CATCH
	END
	
	CLOSE bcView
    DEALLOCATE bcView
	








GO
GRANT EXECUTE ON  [dbo].[vspViewRefresher] TO [public]
GO
