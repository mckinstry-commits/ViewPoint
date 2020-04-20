SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROCEDURE [dbo].[vspVPGrantAll]  
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
			AMR 12/22/2010 - 142601 - because of tax installers adding an output option where GrantAll
								does not output any statuses or object changes, removing cursors, providing
								a one set status at the end so the do
			AMR 1/3/2011 - 142601 - breaking out grant all into a couple of procs for better control by the installers
 * Usage:
 * Sets SQL Permissions on views, functions, and stored procedures.
 * 
 * Viewpoint Application
 * 
 * 	Stored Procedures ( beginning with bsp, brpt, bcr, vsp )
 * 		Grant execute to public
 * 
 * 	Functions ( beginning with bf and vf )
 * 		Grant execute to public
 * 
 * 	Views ( all views execpt those that begin with pv)
 * 		Grant select, insert, delete, update to public
 * 	
 * Portal Application
 * 	Stored Procedures ( beginning with vpsp )
 * 		Grant execute to VCSPortal
 * 
 * 	Views ( beginning with pv ) 
 * 		Grant select to VCSPortal
 * 
 * Viewpoint Application Role Security when turned on
 * 	Views
 * 		Grant select to public
 * 		Deny insert, update and delete to public
 * 		Grant insert, update and delete to Viewpoint
 *
 *************************************/
@Output char(1) = 'Y'

as

DECLARE @errmsg varchar(255)

SET NOCOUNT ON;
	-- grant permissions for procs
	EXEC [dbo].[vspVPGrantAllProcs] @Output
	-- grant permissions for functions
	EXEC [dbo].[vspVPGrantAllFuncs]	@Output
	-- grant permissions to portal
	EXEC [dbo].[vspVPGrantAllPortal] @Output 

	-- check app role and add it to views if it exists
	PRINT 'Checking to see if Application role security is set in VA. If it is set reapply Application Role security.'
		+ ' ' + CONVERT(varchar(30), GETDATE())
	IF EXISTS ( SELECT TOP 1
						1
				FROM    DDVS WITH ( NOLOCK )
				WHERE   UseAppRole = 'Y' ) 
		BEGIN
			EXEC dbo.vspVAAppSec 
				'Y',
				@errmsg
		END
	ELSE
		BEGIN
			-- grant permissions to views
			EXEC [dbo].[vspVPGrantAllViews] @Output
		END

GO
GRANT EXECUTE ON  [dbo].[vspVPGrantAll] TO [public]
GO
