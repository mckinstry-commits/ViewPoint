SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE             PROCEDURE dbo.vspDDFormReset
/********************************
* Created: kb 11/8/5
* Modified: 
*
* Input:
*	@co		Current active company #
*	@form	Form name
*
* Output:
*	Multiple resultsets - 1st: Form Header info
*						- 2nd: Form Tab info
*						- 3rd: Form Inputs 
*						- 4th: Form Input Lookups
*						- 5th: Form Input Lookup Detail
*						- 6th: Custom Group Box controls
*						- 7th: Accessible Form Reports 
*						- 8th: Form Report Defaults
*
* Return code:
*	0 = success, 1 = failure
*
*********************************/
  (@form varchar(30) = null, @errmsg varchar(5000) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @form is null 
	begin
	select @errmsg = 'Missing required input parameters: Form!', @rcode = 1
	goto vspexit
	end

delete from vDDFLc where Form = @form 
delete from vDDFIc where Form = @form and ControlType not in (6,7)

delete  
from vDDGBc WHERE Form = @form

delete  
from vDDFTc   WHERE   EXISTS 
   (Select * 
from vDDFTc t
left join vDDFIc i on t.Form = i.Form and t.Tab = i.Tab
where t.Form = @form)
and vDDFTc.Form = @form




select @errmsg = 'The form has been reset for ' + @form

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDFormReset]'
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspDDFormReset] TO [public]
GO
