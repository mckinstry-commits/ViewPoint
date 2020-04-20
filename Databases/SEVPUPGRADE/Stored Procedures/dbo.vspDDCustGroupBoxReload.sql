SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[vspDDCustGroupBoxReload]
/********************************
* Created: GG 06/09/03 
* Modified: 
*
* Called from the VPForm Class to retrieve CustomGroupBox info
*
* Input:
*	@form	Form name
*
* Output:
*	Multiple resultsets - 1st: Form Header info
*						: Custom Group Box controls
*
* Return code:
*	0 = success, 1 = failure
*
*********************************/
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

-- 6th resultset - Custom group box controls
select Tab, GroupBox, Title, ControlPosition
from vDDGBc
where Form = @form
order by Tab, GroupBox

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDCustGroupBoxReload]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDCustGroupBoxReload] TO [public]
GO
