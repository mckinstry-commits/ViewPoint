SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspDDFTGet]
/********************************
* Created: JRK 10/23/06  
* Modified:	JRK 09/07/2007 - Include other tabs that have GridForms that do not ShowOnMenu.
*
* Called from HQUDAdd to enumerate tabs a custom field can be added to.
* Don't return tab 0 (Grid), the Notes tab, nor any tabs that are related grids.
*
* Input:
*	@form				current form name
*
* Output:
*	resultset - current lookup information
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@form varchar(30) = null)
as
	
set nocount on
	
declare @rcode int
	
select @rcode = 0

-- resultset --
select  t.Form, t.Tab, t.Title, t.GridForm, h.Form RelatedForm, h.ShowOnMenu RelatedShowOnMenu, h.ViewName RelatedViewName, h.CustomFieldTable RelatedCustomFieldTable --, h.AllowCustomFields RelatedAllowCustomFields
from DDFTShared t (nolock)
left outer join DDFHShared h (nolock) on t.GridForm = h.Form
where t.Form = @form 
 and t.Tab <> 0 -- The Grid tab is not an option for ud fields.
 and t.Title <> 'Notes' -- The Notes tab is out too.
 and (t.GridForm is null or  h.ShowOnMenu <> 'Y')-- Related grids are not valid tabs either.
order by t.Tab

/* -- Before changes
select  Form, Tab, Title 
from DDFTShared (nolock)
where Form = @form 
 and Tab <> 0 -- The Grid tab is not an option for ud fields.
 and Title <> 'Notes' -- The Notes tab is out too.
 and GridForm is null -- Related grids are not valid tabs either.
order by Tab
*/
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFTGet] TO [public]
GO
