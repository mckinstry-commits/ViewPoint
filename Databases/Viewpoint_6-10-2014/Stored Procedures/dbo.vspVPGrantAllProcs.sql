SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGrantAllProcs]  
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
			AMR 9/7/2010	- Issue 141247 - fixing access to the pPortalAudit table
			AMR 1/3/2010	- 142601 - because of tax installers adding an output option where GrantAll
								does not output any statuses or object changes, removing cursors, providing
								a one set status at the end so the do, creating a separate proc now
								
 * Usage:
 * Sets SQL Permissions on stored procedures.
 *************************************/
@Output char(1) = 'Y'

AS

DECLARE @itemcount int,
    @name varchar(8000),
    @tsql varchar(8000)

SET NOCOUNT ON

	SET @itemcount = 0
	print 'Granting execute permission to public on all Viewpoint procedures in ' + DB_NAME()+ ' ' + convert(varchar(30),GETDATE())

	-- create temp table so we can create one result set at the end
	-- will loop through procs and grant permissions
	CREATE TABLE #tProcs (	ProcName sysname,
							Granted tinyint DEFAULT(0)
							)

	INSERT INTO #tProcs
			( ProcName )
	SELECT  r.ROUTINE_NAME
	FROM    INFORMATION_SCHEMA.ROUTINES r WITH ( NOLOCK )
			LEFT JOIN sys.database_permissions p WITH ( NOLOCK ) ON OBJECT_NAME(major_id) = r.ROUTINE_NAME
																  AND USER_NAME(grantee_principal_id) = 'public'
	WHERE   ( ROUTINE_TYPE = 'PROCEDURE'
			  AND ( r.ROUTINE_NAME LIKE 'bsp%'
					OR ROUTINE_NAME LIKE 'brpt%'
					OR ROUTINE_NAME LIKE 'vrpt%'
					OR ROUTINE_NAME LIKE 'bcr%'
					OR ROUTINE_NAME LIKE 'vcr%'
					OR ROUTINE_NAME LIKE 'vsp%'
				  )
			  AND ROUTINE_SCHEMA = 'dbo'
			)
			AND ISNULL(p.state, '') = ''
			OR ( state = 'D'
				 AND type = 'EX'
			   )
	ORDER BY r.ROUTINE_NAME

	SET @name = NULL
	SELECT TOP (1) @name = ProcName FROM #tProcs AS tp WHERE Granted = 0

	WHILE @name IS NOT NULL
	BEGIN
		SET @tsql = 'GRANT EXECUTE ON [' + @name + '] TO [public]'

		BEGIN TRY
			EXEC (@tsql)

			UPDATE #tProcs
			SET Granted = 1
			WHERE ProcName = @name
		END TRY
		BEGIN CATCH
			UPDATE #tProcs
			SET Granted = 2
			WHERE ProcName = @name
		END CATCH
		
		SET @name = NULL
		SELECT TOP (1) @name = ProcName FROM #tProcs AS tp WHERE Granted = 0
	END

	-- finished with Viewpoint procedures
	IF @Output = 'Y'
	BEGIN
		IF EXISTS (SELECT 1 FROM #tProcs)
		BEGIN
			SELECT ProcName + CASE WHEN Granted = 1 THEN ' updated' ELSE ' Error Granting Permission to Public' END	 AS [Procedure Update]
			FROM #tProcs AS tp
		END
		
		SELECT @itemcount = COUNT(*) FROM #tProcs AS tp
		SELECT  CONVERT(varchar(4), @itemcount) + ' procedures updated.'
		SET @itemcount = NULL
		SELECT @itemcount = COUNT(*) FROM #tProcs AS tp	WHERE Granted <> 1
		SELECT  CONVERT(varchar(4), @itemcount) + ' procedures failed.'
	END
	
	DROP TABLE #tProcs
	
  RETURN (0)



GO
GRANT EXECUTE ON  [dbo].[vspVPGrantAllProcs] TO [public]
GO