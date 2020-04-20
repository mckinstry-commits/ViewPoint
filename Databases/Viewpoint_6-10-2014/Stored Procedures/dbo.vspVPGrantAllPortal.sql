SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGrantAllPortal]  
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
								a one set status at the end so the do, creating a separate proc nowo
			AMR 2/14/2011	- 143287 - now updates procs that have not been granted along with those that are denied
 * Usage:
 * Sets SQL Permissions on Portal Procs.
 *
 *************************************/
@Output char(1) = 'Y'

as

DECLARE @itemcount int,
    @name varchar(8000),
    @tsql varchar(8000)
  

SET NOCOUNT ON

	PRINT 'Granting execute permission to VCSPortal on all procedures starting with (vpsp) in ' + DB_NAME() + ' ' + convert(varchar(30),GETDATE())

	-- create temp table so we can create one result set at the end
	-- will loop through procs and grant permissions
	--143287 - lets find all the procs missing the grant permission, not just the denied ones
	CREATE TABLE #tPProcs (	ProcName sysname,
							Granted tinyint DEFAULT(0)
							)

	INSERT INTO #tPProcs
			( ProcName )
	SELECT  pr.name
	FROM	sys.procedures pr
			JOIN sys.schemas s ON s.[schema_id] = pr.[schema_id]
	 		LEFT JOIN sys.database_permissions p WITH ( NOLOCK ) ON USER_NAME(p.grantee_principal_id) = 'VCSPortal'
															 AND p.major_id = pr.[object_id]
															 AND p.[state] = 'G'
															 AND p.[type] = 'EX'
	WHERE   
			pr.name LIKE 'vpsp%'
			AND s.name = 'dbo'
			AND p.major_id IS NULL
	ORDER BY pr.name
	  
  -- loop through all procs 
 	SET @name = NULL
	SELECT TOP (1) @name = ProcName FROM #tPProcs AS tp WHERE Granted = 0

	WHILE @name IS NOT NULL
	BEGIN
		SELECT @tsql = 'grant execute on [' + @name + '] to [VCSPortal]'

		BEGIN TRY
			EXEC (@tsql)

			UPDATE #tPProcs
			SET Granted = 1
			WHERE ProcName = @name
		END TRY
		BEGIN CATCH
			UPDATE #tPProcs
			SET Granted = 2
			WHERE ProcName = @name
		END CATCH
		
		SET @name = NULL
		SELECT TOP (1) @name = ProcName FROM #tPProcs AS tp WHERE Granted = 0
	END
  
	IF @Output = 'Y'
    BEGIN
		IF EXISTS (SELECT 1 FROM #tPProcs)
		BEGIN
			SELECT ProcName + CASE WHEN Granted = 1 THEN ' updated' ELSE ' Error Granting Permission to Public' END AS [Portal Procedure Update]
			FROM #tPProcs AS tp
		END
		
		SELECT @itemcount = COUNT(*) FROM #tPProcs AS tp	WHERE Granted = 1
		SELECT  CONVERT(varchar(4), @itemcount) + ' procedures updated.'
		SET @itemcount = NULL
		SELECT @itemcount = COUNT(*) FROM #tPProcs AS tp	WHERE Granted <> 1
		SELECT  CONVERT(varchar(4), @itemcount) + ' procedures failed.'
	END
	
	DROP TABLE #tPProcs
  ----
--#141247 - adding public to the pPortalAudit
PRINT 'Updating the portal permissions on the Audit table'
GRANT SELECT,UPDATE,INSERT,DELETE ON dbo.pPortalAudit TO PUBLIC

RETURN(0)



GO
GRANT EXECUTE ON  [dbo].[vspVPGrantAllPortal] TO [public]
GO
