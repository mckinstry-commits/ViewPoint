SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************/
CREATE PROC [dbo].[vspMRMigrateStructureCleanup]
/*************************************
* CREATED BY:	GP 03/20/2009
* Modified By:	
*
* This procedure has a update statement that can
* be used to correct the account code structure
* replacing the dots (.) with dashes (-)
*
*		Input Parameters:
*    
*		Output Parameters:
*
**************************************/


with execute as 'viewpointcs'
	
as
set nocount on

declare @rcode smallint, @msg varchar(255)
		
select @rcode = 0

---- select
select replace(Low,'.','-'), replace(High,'.','-')
from ManagementReporter.dbo.ControlTreeCriteria
where Low like '%.%' or High like '%.%'

---- update
----update ManagementReporter.dbo.ControlTreeCriteria
----	set Low = replace(Low,'.','-'),
----		High = replace(High,'.','-')
----from ManagementReporter.dbo.ControlTreeCriteria
----where Low like '%.%' or High like '%.%'



vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMRMigrateStructureCleanup] TO [public]
GO
