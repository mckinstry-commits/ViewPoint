SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPRDTRecompile] with execute as 'viewpointcs'
/***********************************************************
* Created: GG 2/1/07
* Modified: 
*
* Flags the bPRDT table for recompile to force new query plans for
* payroll process procedures and triggers.  
*
* 'execute as' sets the execution context because 'public' will not have sufficient permission
*
* Inputs:
*	none
*
* Outputs:
*   none
*
*****************************************************/

as

set nocount on

exec sys.sp_recompile 'dbo.bPRDT'

return

GO
GRANT EXECUTE ON  [dbo].[vspPRDTRecompile] TO [public]
GO
