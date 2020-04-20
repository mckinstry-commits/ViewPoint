SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspGLAcctParts]
/************************************
* Created:	GG	02/19/96
* Modified:	GG	02/19/96
*			MV 01/31/03 - #20246 dbl quote cleanup.
*			ES 03/30/04 - #24131 Initialize variables for ANSI nulls
*			GG 05/02/07 - V6.0 mods
*
* Usage:
*	Called by the GLAP form (GL Accounts Parts) to
*	return the individual parts of the GL Account mask.
*
* Inputs:
*	None - hardcoded for bGLAcct datatype.
*
* Outputs:
*	Up to 6 parts of the GL Account mask, w/o separators
*	@errmsg	message if procedure fails
**********************************************/
   	(@errmsg varchar(255) output)
as

set nocount on

declare @part1 varchar(3), @part2 varchar(3), @part3 varchar(3),
	@part4 varchar(3), @part5 varchar(3), @part6 varchar(3),
	@mask varchar(20), @i int, @char char(1), @partno int, @rcode int

select @rcode = 0, @i = 1, @partno = 1, @part1 = '', @part2 = '', @part3 = '',
	@part4 = '', @part5 = '', @part6 = ''

/* get mask for GL Account datatype - V6.0 use shared datatype view */
select @mask = InputMask from dbo.DDDTShared where Datatype = 'bGLAcct'
if @@rowcount = 0
	begin
	select @errmsg = 'Missing datatype ''bGLAcct'' in DD Datatypes!', @rcode = 1
	goto bspexit
	end
   
while @i < datalength(@mask)
   	begin
   	select @char = substring(@mask,@i,1)
   	if @partno = 1  select @part1 = @part1 + @char
   	if @partno = 2  select @part2 = @part2 + @char
   	if @partno = 3  select @part3 = @part3 + @char
   	if @partno = 4  select @part4 = @part4 + @char
   	if @partno = 5  select @part5 = @part5 + @char
   	if @partno = 6  select @part6 = @part6 + @char
   	select @i = @i + 1
   	if @char not like '[0-9]'
   		begin
   		select @partno = @partno + 1
   		select @i = @i + 1	/* skip the 'separator' character */
   		end
   	end

select 'Part1'= @part1,'Part2'= @part2,'Part3'= @part3,
   	'Part4'= @part4, 'Part5'= @part5, 'Part6'= @part6
   
bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLAcctParts] TO [public]
GO
