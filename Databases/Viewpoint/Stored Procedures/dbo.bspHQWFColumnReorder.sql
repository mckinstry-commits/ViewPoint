SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspHQWFColumnReorder]
/***********************************************************
 * CREATED By:	GF 04/30/2007 6.x
 * MODIFIED By:
 *
 *
 * USAGE:
 * called from PMDocTemplatesMergeOrder form to update the merge column order.
 *
 * PASS:
 * Template		Template Name
 * ColumnList	Template Merge Column Names
 * WordTableYN	Word Table columns flag
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
(@template varchar(40), @column_list varchar(8000), @wordtableyn bYN = 'N', @msg varchar(255) output)
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

   	---- update HQWF merge column with grid column
   	if @endcharpos > 0
   		begin
		update HQWF set MergeOrder=@gridcol
		where TemplateName=@template and MergeFieldName=@columnpart and WordTableYN=@wordtableyn
		end
   
	if @endcharpos = 0 set @complete = 1

END




bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWFColumnReorder] TO [public]
GO
