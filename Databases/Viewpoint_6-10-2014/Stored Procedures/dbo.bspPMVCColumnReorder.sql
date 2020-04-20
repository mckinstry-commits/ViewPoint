SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspPMVCColumnReorder]
/***********************************************************
 * CREATED By:	GF 03/27/2007 6.x
 * MODIFIED By:
 *
 *
 * USAGE:
 * called from PMDocTrackViewGridOrder form to update the grid column order.
 *
 * PASS:
 * ViewName		Document Tracking View Name
 * GridForm		Document Tracking Grid Form
 * ColumnList	Document Tracking Grid Form Column Names
 *
 *
 *	RETURNS:
 *  ErrMsg if any
 * 
 * OUTPUT PARAMETERS
 *   @msg     Error message if invalid, 
 * RETURN VALUE
 *   0 Success
 *   1 fail
 *****************************************************/ 
(@viewname varchar(10), @gridform varchar(30), @column_list varchar(4000), @msg varchar(255) output)
as
set nocount on

declare @rcode int, @colseq int, @gridcol smallint, @part varchar(128), @char char(1),
		@charpos int, @endcharpos int, @complete tinyint, @retstring varchar(max),
		@retstringlist varchar(max), @columnpart varchar(128), @errmsg varchar(255)

select @rcode = 0, @colseq = 0, @gridcol = 0, @complete = 0, @char = '~'


while @complete = 0
BEGIN
   	---- get part
   	exec dbo.bspParseString @column_list, @char, @charpos output, @retstring output, @retstringlist output, @errmsg output
   	select @columnpart = ltrim(rtrim(@retstring))
   	select @column_list = ltrim(rtrim(@retstringlist))
   	select @endcharpos = @charpos
	select @gridcol = @gridcol + 1

   	---- update PMVC column with grid column
   	if @endcharpos > 0
   		begin
		update PMVC set GridCol=@gridcol
		where ViewName=@viewname and Form=@gridform and ColTitle=@columnpart
		end
   
	if @endcharpos = 0 set @complete = 1
   
	----if @endcharpos > 0 select @columnpart, @gridcol, @endcharpos

END




bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMVCColumnReorder] TO [public]
GO
