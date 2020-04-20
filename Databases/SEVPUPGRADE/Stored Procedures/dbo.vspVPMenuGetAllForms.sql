SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



















CREATE   PROCEDURE [dbo].[vspVPMenuGetAllForms]
/**************************************************
* Created: JK 05/12/04 - 
* Modified: GG 5/24/04 - Simplified to return all forms, remove input/output params
*			GG 07/15/04 - skip DD and forms whose primary module is inactive
*			JRK 01/19/2005 - Exclude forms with null AssemblyName
*			GG 04/10/06 - mods for LicLevel
*
* Used by VPMenu (and F3 Field Overrides??) to list all Forms 
*
* Inputs:
*	none
*
* Output:
*	resultset of all Forms
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	
as

set nocount on 

declare @rcode int

select @rcode = 0

-- resultset of eligible Forms (shown on Menu, active module, exclude DD)
select f.Form, f.Title
from DDFHShared f (nolock)
join vDDMO m (nolock) on m.Mod = f.Mod
where m.Active = 'Y' and f.Mod <> 'DD' and f.AssemblyName is not null and f.ShowOnMenu = 'Y'
	and (m.LicLevel > 0 and m.LicLevel >= f.LicLevel)
order by f.Title

vspexit:
	return @rcode













GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetAllForms] TO [public]
GO
