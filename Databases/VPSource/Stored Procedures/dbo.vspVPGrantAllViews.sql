SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGrantAllViews]  
/*****************************************
 * Created: GG 02/26/01
 * Modified:DANF 11/27/01 Added check for dbo onwer
 *          DANF 06/13/02 Added select to check App Role Security in VA.
 *			DANF 11/22/2004 - Issue 26262 Added [] around the names of stored procedures and views.
 *			DANF 04/20/2004 - Issue 28468 Added Functions.
 *			DANF 04/26/2005 - Added VP6.X stored procedures that begin with vsp..
 *          GWC  03/30/2006 - Removed execution of Portal Stored procedure to grant permissions
 *			TRL  07/17/2007 - Added code to grant persmissions Crystal Report Stored procedures 
							  beginning with vrpt, vcr
 *			DANF 10/24/2007 - Added try catch to stored procedure.
 *			AMR	 3/15/2010	- Issue 138318
								Fixed table functions from being granted exec, cleaned up code a bit,
								added space between dates in the printed message
			AMR 9/7/2010   - Issue 141247 - fixing access to the pPortalAudit table
			AMR 1/3/2010	- 142601 - because of tax installers adding an output option where GrantAll
								does not output any statuses or object changes, removing cursors, providing
								a one set status at the end so the do, creating a separate proc now
 * Usage:
 * Sets SQL Permissions on views
 * 
 *************************************/
@Output char(1) = 'Y'

as

DECLARE @itemcount int,
    @name varchar(8000),
    @tsql varchar(8000)

SET NOCOUNT ON
----
SET @itemcount = 0
PRINT  'Granting select, insert, update, and delete permission to public on all views in ' + DB_NAME()+ ' ' + convert(varchar(30),GETDATE())

	-- create temp table so we can create one result set at the end
	-- will loop through tables and grant permissions
	CREATE TABLE #tViews (	ViewName sysname,
							Granted tinyint DEFAULT(0)
							)
	INSERT INTO #tViews
			( ViewName)
	SELECT v.name
	FROM sys.views v
		LEFT JOIN sys.database_permissions AS dp ON v.object_id = dp.major_id 
													AND USER_NAME(dp.grantee_principal_id) = 'public'
													AND dp.[state] = 'G'
													AND dp.[type] ='SL'
		LEFT JOIN sys.database_permissions AS dpi ON v.object_id = dpi.major_id 
													AND USER_NAME(dpi.grantee_principal_id) = 'public'
													AND dpi.[state] = 'G'
													AND dpi.[type] = 'IN'
		LEFT JOIN sys.database_permissions AS dpd ON v.object_id = dpd.major_id 
													AND USER_NAME(dpd.grantee_principal_id) = 'public'
													AND dpd.[state] = 'G'
													AND dpd.[type] = 'DL'
		LEFT JOIN sys.database_permissions AS dpu ON v.object_id = dpu.major_id 
													AND USER_NAME(dpu.grantee_principal_id) = 'public'
													AND dpu.[state] = 'G'
													AND dpu.[type] = 'UP'
	WHERE  
			v.name NOT LIKE 'sys%'
			AND v.is_ms_shipped = 0
			AND (dp.major_id IS NULL
					OR dpi.major_id IS NULL
					OR dpd.major_id IS NULL
					OR dpu.major_id IS NULL)
	ORDER BY v.name

	SET @name = NULL
	SELECT TOP (1) @name = ViewName FROM #tViews WHERE Granted = 0

	WHILE @name IS NOT NULL
	BEGIN
		BEGIN TRY
			SELECT  @tsql = 'grant select,insert,delete,update on [' + @name + '] to [public]'
			EXEC (@tsql)
			
	 		UPDATE  #tViews
			SET     Granted = 1
			WHERE   ViewName = @name	
	 	END TRY
		BEGIN CATCH
			UPDATE  #tViews
			SET     Granted = 2
			WHERE   ViewName = @name
		END CATCH

		SET @name = NULL
		SELECT TOP (1) @name = ViewName FROM #tViews WHERE Granted = 0
	END
	
	IF @Output = 'Y'
    BEGIN
    	IF EXISTS (SELECT 1 FROM #tViews)
		BEGIN
			SELECT ViewName + CASE WHEN Granted = 1 THEN ' updated' ELSE ' Error Granting Permission to Public' END AS [View Update]
			FROM #tViews
		END
		
		SELECT @itemcount = COUNT(*) FROM #tViews WHERE Granted = 1
		SELECT  CONVERT(varchar(4), @itemcount) + ' views updated.'
		SET @itemcount = NULL
		SELECT @itemcount = COUNT(*) FROM #tViews WHERE Granted <> 1
		SELECT  CONVERT(varchar(4), @itemcount) + ' views failed.'
	END
	
	DROP TABLE #tViews

RETURN(0)



GO
GRANT EXECUTE ON  [dbo].[vspVPGrantAllViews] TO [public]
GO
