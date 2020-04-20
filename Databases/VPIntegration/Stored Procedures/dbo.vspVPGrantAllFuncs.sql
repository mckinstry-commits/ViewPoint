SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[vspVPGrantAllFuncs]  
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
			AMR 4/14/2011 - 143793 - TK-04266 - adding vpf to the list of functions
 * Usage:
 * Sets SQL Permissions on functions
 *************************************/
@Output char(1) = 'Y'

AS

DECLARE @itemcount int,
    @name varchar(8000),
    @tsql varchar(8000),
    @datatype varchar(32)

SET NOCOUNT ON
	--********************** Functions ************************************************** 
	SELECT  @itemcount = 0
	PRINT 'Granting execute permission to public on all functions starting with (bf) in '
		+ DB_NAME() + ' ' + CONVERT(varchar(30), GETDATE())
    
	-- create temp table so we can create one result set at the end
	-- will loop through functions and grant permissions
	CREATE TABLE #tFunc (	FuncName sysname,
							DataType sysname,
							Granted tinyint DEFAULT(0))

	INSERT INTO #tFunc
			(	FuncName,
				DataType )      
	SELECT ISR.ROUTINE_NAME, 
			ISR.DATA_TYPE
	FROM INFORMATION_SCHEMA.ROUTINES ISR WITH (NOLOCK)
		LEFT JOIN  sys.database_permissions DP WITH (NOLOCK) ON USER_NAME(DP.grantee_principal_id) = 'public' 
															AND	 OBJECT_NAME(DP.major_id) = ISR.ROUTINE_NAME 
															AND DP.[state] = 'G' 
															AND (ISR.DATA_TYPE = 'TABLE' AND DP.[type] = 'SL' OR (ISR.DATA_TYPE <> 'TABLE' AND DP.[type] = 'EX'))
	WHERE ISR.ROUTINE_TYPE = 'FUNCTION' 
		AND (ISR.ROUTINE_NAME LIKE 'bf%' 
				OR ISR.ROUTINE_NAME LIKE 'vf%'  
				OR ISR.ROUTINE_NAME LIKE 'vpf%') 
		AND ISR.ROUTINE_SCHEMA = 'dbo'
		-- don't need to reassign to the public role, otherwise why left join
		AND DP.grantee_principal_id IS NULL 
	ORDER BY ROUTINE_NAME

	SET @name = NULL
	SELECT TOP (1) @name = FuncName, @datatype = DataType FROM #tFunc AS f WHERE Granted = 0

	WHILE @name IS NOT NULL
	BEGIN
        SELECT  @tsql = 'GRANT ' + CASE WHEN @datatype = 'TABLE' THEN 'SELECT' ELSE 'EXECUTE' END
						+ ' ON [' + @name + '] TO [public]'
		
		BEGIN TRY
			EXEC (@tsql)

			UPDATE  #tFunc
			SET     Granted = 1
			WHERE   FuncName = @name
		END TRY
		BEGIN CATCH
			UPDATE  #tFunc
			SET     Granted = 2
			WHERE   FuncName = @name
		END CATCH
		
		SET @name = NULL
		SELECT TOP (1) @name = FuncName, @datatype = DataType FROM #tFunc AS f WHERE Granted = 0
	END

	
	-- finished with Viewpoint procedures
	IF @Output = 'Y'
	BEGIN
		IF EXISTS (SELECT 1 FROM #tFunc)
		BEGIN
			SELECT FuncName + CASE WHEN Granted = 1 THEN ' updated' ELSE ' Error Granting Permission to Public' END  AS [Function Update]
			FROM #tFunc AS f
		END
		
		SELECT @itemcount = COUNT(*) FROM #tFunc AS f
		SELECT  CONVERT(varchar(4), @itemcount) + ' functions updated.'
		SET @itemcount = NULL
		SELECT @itemcount = COUNT(*) FROM #tFunc WHERE Granted <> 1
		SELECT  CONVERT(varchar(4), @itemcount) + ' functions failed.'
	END
	
	DROP TABLE #tFunc

RETURN (0)



GO
GRANT EXECUTE ON  [dbo].[vspVPGrantAllFuncs] TO [public]
GO
