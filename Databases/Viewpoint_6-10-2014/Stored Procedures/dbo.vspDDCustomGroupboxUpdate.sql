SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[vspDDCustomGroupboxUpdate]
/********************************
* Created: mj 6/22/04
* Modified:	TML 04/04/2012 TK-13822 change delete for DDGBc to no use ControlPosition
*
*
* Called from the VPForm Class to update and delete custom group box entries from vDDGBc
*
* Input:
*	@form			Form 
*	@seq			Sequence # of the group box on the tab
*	@position		Comma delimited string of top, left, width, height
*	@tab			Tab page 
*	@title			Group box title
*	@deleteflag		1 = delete group box entry
*	
* Output:
*	@errmsg			error message

* Return code:
*	0 = success, 1 = failure
*
*********************************/
	(@form varchar(30) = null, @seq smallint = null, @position varchar(20) = null,  
	@tab tinyint = null, @title varchar(30) = null, @deleteflag smallint = null,
	@errmsg varchar(256) output)
as

set nocount on

declare @rcode int
select @rcode = 0

-- pass delete flag to remove the group box entry
if @deleteflag = 1 
	begin
	delete vDDGBc
	----TK-13822
	where Form = @form and GroupBox = @seq and Tab = @tab ----and ControlPosition = @position
	end
else
	begin
	-- try to update existing group box entry
	update vDDGBc
	set Title = @title, ControlPosition = @position
	where Form = @form and GroupBox = @seq and Tab = @tab
	if @@rowcount = 0
		begin
		-- if unable to update, add an entry 
		insert vDDGBc (Form, Tab, GroupBox, Title, ControlPosition)
		select @form, @tab, @seq, @title, @position
		end
	end

vspexit:
	if @rcode<>0 select @errmsg = @errmsg
  	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspDDCustomGroupboxUpdate] TO [public]
GO
