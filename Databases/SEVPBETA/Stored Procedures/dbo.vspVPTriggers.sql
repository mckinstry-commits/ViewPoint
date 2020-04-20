SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspVPTriggers]
/************************************
* Created: GG 02/26/09 - #132417
* Modified: 
*
* Used to generate a list of Viewpoint triggers and their status.  Typically run to
* find disabled triggers on a customer's system.
*
* Input paramters:
*   @disabledonly   Y = returns disabled triggers only, N = return all triggers
*
************************************/
(@disabledonly bYN = 'Y')
as
set nocount on
   
select name, object_name(parent_id) as [parent], [type],
	case when is_disabled = 1 then 'yes' else 'no' end as [disabled],
	case when is_instead_of_trigger = 1 then 'yes' else 'no' end as [instead_of_trigger]
from sys.triggers
where is_disabled = case when @disabledonly = 'Y' then 1 else is_disabled end
order by name
   
return


GO
GRANT EXECUTE ON  [dbo].[vspVPTriggers] TO [public]
GO
