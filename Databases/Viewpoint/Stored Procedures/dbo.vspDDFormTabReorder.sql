SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDDFormTabReorder]
/********************************
* Created: mj 8/11/04 
* Modified:	GG 07/20/05 - added vDDFTc cleanup 
*
* Called from DD Form Properties form to reorder a pair of tab pages
*
* Input:
*	@form		Form
*	@tab1		1st in a pair of Tab Pages
*	@tab2		2nd in a pair of Tab Pages
*
* Output:
*	@errmsg - 	error message if one is encountered

* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@form varchar(30) = null, @tab1 int = null, @tab2 int = null, @errmsg varchar(255) output)
as

set nocount on
declare @rcode int
select @rcode = 0

declare @seq1 int, @seq2 int

--check for Grid and Info Tabs
if @tab1 in (0,1) or @tab2 in (0,1)
	begin
	select @errmsg = 'Not allowed to change the load sequence of Grid or Info tabs', @rcode = 1
	goto vspexit
	end	

-- get Load Sequence for 1st Tab
select @seq1 = LoadSeq
from dbo.vDDFTc (nolock)
where Form = @form and Tab = @tab1
if @@rowcount = 0
	begin
	if @tab1 > 99	-- custom tabs (100 - 255) must exist in vDDFTc
		begin
		select @errmsg = 'Tab page #:' + convert(varchar,@tab1) + ' is invalid!', @rcode = 1
		goto vspexit
		end
	-- get standard Load Sequence - standard tabs (0 - 100) must exist in vDDFT
	select @seq1 = LoadSeq
	from dbo.vDDFT (nolock)
	where Form = @form and Tab = @tab1
	if @@rowcount = 0
		begin	
		select @errmsg = 'Tab page #:' + convert(varchar,@tab1) + ' is invalid!', @rcode = 1
		goto vspexit
		end
	end
-- get Load Sequence for 2nd Tab
select @seq2 = LoadSeq
from dbo.vDDFTc (nolock)
where Form = @form and Tab = @tab2
if @@rowcount = 0
	begin
	if @tab2 > 99	-- custom tabs (100 - 255) must exist in vDDFTc
		begin
		select @errmsg = 'Tab page #:' + convert(varchar,@tab2) + ' is invalid!', @rcode = 1
		goto vspexit
		end
	-- get standard Load Sequence - standard tabs (0 - 100) must exist in vDDFT
	select @seq2 = LoadSeq
	from dbo.vDDFT (nolock)
	where Form = @form and Tab = @tab2
	if @@rowcount = 0
		begin	
		select @errmsg = 'Tab page #:' + convert(varchar,@tab2) + ' is invalid!', @rcode = 1
		goto vspexit
		end
	end
	
	
-- Tabs are valid, swap LoadSeq and update/insert vDDFTc
update dbo.vDDFTc
set LoadSeq = @seq2  
where Form = @form and Tab = @tab1
if @@rowcount = 0
	insert dbo.vDDFTc (Form, Tab, LoadSeq)
	values(@form, @tab1, @seq2)

update dbo.vDDFTc
set LoadSeq = @seq1  
where Form = @form and Tab = @tab2
if @@rowcount = 0
	insert dbo.vDDFTc (Form, Tab, LoadSeq)
	values(@form, @tab2, @seq1)


--Cleanup - remove overridden Form Tabs when LoadSeq is same as standard
/*delete dbo.vDDFTc
from dbo.vDDFTc c
join dbo.vDDFT t on t.Form = c.Form and t.Tab = c.Tab
where c.Form = @form and c.LoadSeq = t.LoadSeq
	and c.IsVisible is null	-- not yet implemented, should always be null		
*/

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFormTabReorder] TO [public]
GO
