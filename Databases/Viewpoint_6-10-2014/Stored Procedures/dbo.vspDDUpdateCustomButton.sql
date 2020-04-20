SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspDDUpdateCustomButton]
/********************************
* Created: RM 03/11/09
* Modified:	
*
* Called to update the size/position of a custom button
*
* Output:
*	@errmsg		error message

* Return code:
*	0 = success, 1 = failure
*
*********************************/
	(@form varchar(30) = null, @buttonid int = null, @top int = null, @left int = null, @height int = null, @width int = null, @parent varchar(255) = null, 
	@errmsg varchar(256) output)
as

set nocount on

declare @rcode int
select @rcode = 0

-- update custom button info
update vDDFormButtonsCustom
set ButtonTop = @top,
ButtonLeft = @left,
Height=@height,
Width=@width,
Parent = @parent
where Form = @form and ButtonID = @buttonid

if @@rowcount = 0
	begin
	select @errmsg = 'Invalid Form and/or Button ID, unable to update custom button info.', @rcode = 1
	goto vspexit
	end

vspexit:
	if @rcode<>0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDUpdateCustomButton]'
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUpdateCustomButton] TO [public]
GO
