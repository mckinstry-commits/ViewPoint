SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        PROCEDURE [dbo].[vspDDVerifyDatabaseCompatibilityLevel]
/**************************************************
* Created: JRK 06/27/06 
*
* Called by RemoteHelper startup to ensure CompatibilityLevel is 90 (SQL 2005).
*
* Inputs:
*	none
*
* Output:
*	@rcode		result code:  -1=error.
*	@errmsg		Error message
*
*
* Return code:
*	@rcode	0 = success, -1 = failure
*
****************************************************/
	(@dbname varchar(128), @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int
select @rcode = 0


return_results:		
select compatibility_level from sys.databases where name = @dbname


vspexit:

	if @rcode < 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDVerifyDatabaseCompatibilityLevel]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDVerifyDatabaseCompatibilityLevel] TO [public]
GO
