SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        PROCEDURE [dbo].[vspDDVerifyDatabaseViewDefinitionGrant]
/**************************************************
* Created: JRK 06/27/06 
*
* Called by RemoteHelper startup to ensure CompatibilityLevel is 90 (SQL 2005).
*
* Inputs:
*	none
*
* Output:
*	@rcode		result code:  1 on success, 0 on failure
*	@errmsg		Error message
*
*
* Return code:
*	@rcode	0 = success, -1 = failure
*
****************************************************/
	(@errmsg varchar(512) output)
as

set nocount on 

declare @rcode int, @perm varchar(30)
select @rcode = 0

select @perm = state_desc from sys.database_permissions perm
join sys.database_principals prin on perm.grantee_principal_id = prin.principal_id
where perm.class=0 and perm.permission_name='VIEW DEFINITION'
and prin.name='public'

return_results:		
if @perm = 'GRANT'
	return 1
else
	return 0

GO
GRANT EXECUTE ON  [dbo].[vspDDVerifyDatabaseViewDefinitionGrant] TO [public]
GO
