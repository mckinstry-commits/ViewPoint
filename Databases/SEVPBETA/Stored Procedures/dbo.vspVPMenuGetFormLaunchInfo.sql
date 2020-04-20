SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO













CREATE    PROCEDURE [dbo].[vspVPMenuGetFormLaunchInfo]
/**************************************************
* Created: JK 05/25/04 - 
*
* Used by VPMenu when launching a form via F8.
*
* Inputs:
*	Form	The form name like "AP1099Process"
*
* Output:
*	resultset of all Forms
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@form varchar(30) = null, @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int

select @rcode = 0

if @form is null
	begin
	select @errmsg = 'Missing required input parameter: Form!', @rcode = 1
	goto vspexit
	end

-- resultset of all Forms (shown on Menu)
select AssemblyName + ':' + FormClassName As FormLaunchInfo
from DDFHShared 
where Form = @form
   
vspexit:
	return @rcode







GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetFormLaunchInfo] TO [public]
GO
