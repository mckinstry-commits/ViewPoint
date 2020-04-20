SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspDDFormTabInsert]
/********************************
* Created: mj 8/11/04 
* Modified:	GG 08/29/05 - fix new tab # and load sequence assignment
*
* Called from DD Form Properties to add custom Form Tab info.
*
* Input:
*	@form		Form
*	@title		Tab title
*	
* Output:
*	@msg - errmsg if one is encountered

* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@form varchar(30), @title varchar(30), @errmsg varchar(60) output)

as
set nocount on

declare @rcode int, @newtab tinyint, @loadseq tinyint

select @rcode = 0, @newtab = 100, @loadseq = 0

-- get next available Custom Tab # (0 - 99 = standard tabs, 100 - 255 custom tabs)
select @newtab = isnull(max(Tab),0) + 1 
from vDDFTc
where Form = @form

if @newtab < 100 select @newtab = 100

-- get next available Load Seq (0 - 255 all tabs)
select @loadseq = max(LoadSeq) + 1
from DDFTShared
where Form = @form

-- add a custom tab 
insert vDDFTc (Form, Tab, Title, LoadSeq)
values(@form, @newtab, @title, @loadseq)
	

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFormTabInsert] TO [public]
GO
