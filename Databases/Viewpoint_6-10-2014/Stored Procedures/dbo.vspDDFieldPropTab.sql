SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE dbo.vspDDFieldPropTab
/**************************************************
* Created:  MJ 02/2/05 
* Modified: 
*
* Retrieves the tab page name for the FieldProperties form.
*
* Inputs
*	@form		Form
*	@tab 		Tab
*
* Output
*	@errmsg
*
****************************************************/
	(@form varchar(30) = null, @tab varchar(4) = null, @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- get title for form and tab
select Title 
from DDFTShared 
where Form = @form and Tab = @tab

   
vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspDDFieldPropTab] TO [public]
GO
