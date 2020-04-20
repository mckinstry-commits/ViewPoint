SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE       proc [dbo].[bspHQWFMergeFieldBuild]
/*************************************
* Created By:   GF 01/15/2002
* Modified By:  GF 07/22/2002 - Added special format for bPct data type.
*				GF 08/22/2003 - issue #22218 - expanded notes variable from 4000 to 6000 characters.
*				GF 01/20/2004 - issue #18841 - added word table flag to distingish main vs table query.
*				RM 03/26/04 - Issue# 23061 - Added IsNulls
*				GF 12/01/2007 - added check for uniqueidentifer column
*				GF 02/14/2008 - issue #127101 expanded Notes to use varchar(max) instead of varchar(8000)
*				GF 05/12/2008 - issue #128235 need to strip char(13) + char(10) from notes.
*				GF 11/11/2009 - issue #136548 back-out replace for char(13)+char(10). Causes problems in word doc.
*				GF 10/10/2010 - issue #141664 use HQCO.ReportDateFormat to specify the style for dates.
*
*
*
* Creates MergeField Header string and Column string for use with Word Document Template merge.
*
*
* Pass:
*	TemplateName
*	Header String
*	Column String
*
* Success returns:
*	0 and HeaderString, ColumnString String
*
* Error returns:
*	1 and error message
**************************************/
(@templatename varchar(40), @headerstring varchar(8000) output, @columnstring varchar(8000) output,
 @msg varchar(255) OUTPUT, @PMCo INT = null)
as
set nocount on
  
declare @rcode int, @validcnt int, @opencursor tinyint, @docobject varchar(30), @columnname varchar(30),
		@mergefieldname varchar(30), @mergeorder smallint, @wordtableyn bYN, @templatetype varchar(10), 
		@alias varchar(2), @objecttable varchar(30), @object varchar(30), @objectid int,
		@wordtable bYN, @char_find nvarchar(2), @char_replace nvarchar(2),
		----#141664
		@Style INT, @ReportDateFormat tinyint
		
select @rcode = 0, @opencursor = 0

set @char_find = char(13) + char(10)
set @char_replace = char(10)
----#141664
SET @Style = 101
SET @ReportDateFormat = 1

if @templatename is null
	begin
	select @msg = 'Missing Template Name', @rcode = 1
	goto bspexit
	END
	
---- #141664 when @pmco is not null get HQCO report date format.
IF @PMCo IS NOT NULL
	BEGIN
	SELECT @ReportDateFormat = ReportDateFormat
	FROM dbo.bHQCO WHERE HQCo=@PMCo
	IF @@rowcount = 0 SET @ReportDateFormat = 1
	END
	
---- #141664 set style based on Report Date Format
IF @ReportDateFormat = 1 SET @Style = 101
IF @ReportDateFormat = 2 SET @Style = 103
IF @ReportDateFormat = 3 SET @Style = 111


-- get template type
select @templatetype=TemplateType
from bHQWD with (nolock) where TemplateName=@templatename
	if @@rowcount = 0
	begin
	select @msg = 'Missing Document Template - ' + isnull(@templatename,'') + '.', @rcode=1
	goto bspexit
	end
  
if isnull(@templatetype,'') = ''
	begin
	select @msg = 'Missing template type for document template.', @rcode=1
	goto bspexit
	end
  
  -- create a cursor to to process document objects from bHQWO
  declare bcHQWF cursor FAST_FORWARD
  for select DocObject, ColumnName, MergeFieldName, MergeOrder, WordTableYN
  from bHQWF with (NOLOCK) where TemplateName = @templatename
  Order By TemplateName, MergeOrder, Seq
  
  -- open cursor
  open bcHQWF
  select @opencursor = 1
  
  -- loop through bcHQWF cursor
  HQWF_loop:
  fetch next from bcHQWF into @docobject, @columnname, @mergefieldname, @mergeorder, @wordtableyn
  
  if @@fetch_status <> 0 goto HQWF_end
  
  
  -- get document object data from HQWO
  select @alias=Alias, @objecttable=ObjectTable, @wordtable=WordTable
  from bHQWO with (nolock) where TemplateType=@templatetype and DocObject=@docobject
  if @@rowcount = 0
  	begin
  	select @msg = 'Missing Document object for document template.', @rcode=1
  	goto bspexit
  	end
  if isnull(@alias,'') = ''
  	begin
  	select @msg = 'Missing alias for Document Object - ' + isnull(@docobject,'') + '.', @rcode=1
  	goto bspexit
  	end
  if isnull(@objecttable,'') = ''
  	begin
  	select @msg = 'Missing object table for Document Object - ' + isnull(@docobject,'') + '.', @rcode=1
  	goto bspexit
  	end
  
  -- if word table field then query is created separately
  if @wordtable = 'Y' goto HQWF_loop
  
  -- update header string
  if isnull(@headerstring,'') = ''
  	select @headerstring = @mergefieldname
  else
  	select @headerstring = @headerstring + ',' + @mergefieldname
  
  -- -- get object_id from sysobjects for base table
  -- select @object = 'b' + @objecttable
  -- select @objectid = id from sysobjects where name = @object
  select @objectid = id from sysobjects where name = @objecttable
  
  -- if type=bDate do something different
  if exists(select t.name from systypes t join syscolumns c on c.usertype=t.usertype
  	where c.name = @columnname and c.id = @objectid and t.name = 'bDate')
  	BEGIN
  	----#141664
  	if isnull(@columnstring,'') = ''
  		select @columnstring = 'select convert(varchar(20),' + @alias + '.' + @columnname + ', ' + CONVERT(VARCHAR(3),@Style) + ')'
  	else
  		select @columnstring = @columnstring + ',convert(varchar(20),' + @alias + '.' + @columnname + ', ' + CONVERT(VARCHAR(3),@Style) + ')'
  	goto HQWF_loop
  	end


----#136548
---- if type=bNotes do something different
if exists(select t.name from systypes t join syscolumns c on c.usertype=t.usertype
			where c.name = @columnname and c.id = @objectid and t.name = 'bNotes')
	begin
	if isnull(@columnstring,'') = ''
		----select @columnstring = 'select replace(convert(varchar(max),' + @alias + '.' + @columnname + '), char(13)+char(10),char(13))'
		select @columnstring = 'select convert(varchar(max), dbo.vfPMDocumentNotesCheck(' + @alias + '.' + @columnname + '))'
	else
		----select @columnstring = @columnstring + ', replace(convert(varchar(max),' + @alias + '.' + @columnname + ')' + ', char(13)+char(10),char(13))'
		select @columnstring = @columnstring + ', convert(varchar(max), dbo.vfPMDocumentNotesCheck(' + @alias + '.' + @columnname + '))'
	goto HQWF_loop
	end

----#136548
---- varchar(max) - #135797
if exists(select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME=@objecttable
			and COLUMN_NAME=@columnname and DATA_TYPE='varchar' and CHARACTER_MAXIMUM_LENGTH = -1
			and DOMAIN_NAME is null)
	begin
	if isnull(@columnstring,'') = ''
		begin
		select @columnstring = 'select dbo.vfPMDocumentNotesCheck(' + @alias + '.' + @columnname + ')'
		goto HQWF_loop
		end
	else
		begin
		select @columnstring = @columnstring + ', dbo.vfPMDocumentNotesCheck(' + @alias + '.' + @columnname + ')'
		end
	goto HQWF_loop
	end

---- if type=bPct do something different
if exists(select t.name from systypes t join syscolumns c on c.usertype=t.usertype
  	where c.name = @columnname and c.id = @objectid and t.name = 'bPct')
  	begin
  	if isnull(@columnstring,'') = ''
  		select @columnstring = 'select (isnull(' + isnull(@alias,'null') + '.' + isnull(@columnname,'') + ', 0) * 100)'
  	else
  		select @columnstring = @columnstring + ',(isnull(' + isnull(@alias,'null') + '.' + isnull(@columnname,'') + ',0) * 100)'
  	
  	goto HQWF_loop
  	end
  
  -- do other types
  if isnull(@columnstring,'') = ''
  	select @columnstring = 'select ' + isnull(@alias,'') + '.' + isnull(@columnname,'')
  else
  	select @columnstring = @columnstring + ',' + isnull(@alias,'') + '.' + isnull(@columnname,'')
  
  goto HQWF_loop
  
  
  HQWF_end:
  -- deallocate cursor
  if @opencursor = 1
      begin
      close bcHQWF
      deallocate bcHQWF
      select @opencursor = 0
      end
  
  
  bspexit:
  
  	-- deallocate cursor
  	if @opencursor = 1
      	begin
      	close bcHQWF
      	deallocate bcHQWF
      	select @opencursor = 0
      	end
  
      if @rcode<>0 select @msg=isnull(@msg,'')
      return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspHQWFMergeFieldBuild] TO [public]
GO
