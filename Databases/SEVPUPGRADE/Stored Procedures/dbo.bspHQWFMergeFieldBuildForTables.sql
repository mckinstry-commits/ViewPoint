SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************************/
CREATE    proc [dbo].[bspHQWFMergeFieldBuildForTables]
/*******************************************************
* Created By:   GF 01/20/2004 - issue #18841 - create column string for word tables merge fields
* Modified By:	RM 03/26/04 - Issue# 23061 - Added IsNulls
*				GF 10/18/2004 - issue #25803 need to wrap columns with isnull when doing concatenation.
*				GF 10/10/2010 - issue #141664 use HQCO.ReportDateFormat to specify the style for dates.
*
*
*
* Creates MergeField Column string for use with Word Document Template merge for word tables only
*
*
* Pass:
*	TemplateName
*	Column String
*
* Success returns:
*	0 and ColumnString String
*
* Error returns:
*	1 and error message
**************************************/
(@templatename varchar(40), @headerstring varchar(8000) output, @columnstring varchar(8000) output, 
@msg varchar(255) OUTPUT, @PMCo INT = null)
as
set nocount on
   
   declare @rcode int, @validcnt int, @opencursor tinyint, @opencursor_hqwo tinyint, @docobject varchar(30), 
   		@columnname varchar(60), @mergefieldname varchar(60), @mergeorder smallint, @templatetype varchar(10), 
   		@alias varchar(2), @objecttable varchar(30), @object varchar(30), @objectid int, @wordtable bYN,
   		@linkeddocobject varchar(30), @joinorder tinyint, @required bYN, @char char(1), @charpos int, 
   		@joinstring varchar(max), @joinclause varchar(255), @linkedobjecttable varchar(30),
   		@retstring varchar(max), @retstringlist varchar(max), @errmsg varchar(255), @pattern varchar(10),
   		@columnlist varchar(140), @complete int, @endcharpos int, @columnpart varchar(140),
   		@partstring varchar(140), @filler varchar(10), @format varchar(30), @formatcolumn varchar(140)
   
   select @rcode = 0, @opencursor = 0, @opencursor_hqwo = 0, @pattern = '''' + '%_%' + ''''
   
   if @templatename is null
   	begin
   	select @msg = 'Missing Template Name', @rcode = 1
   	goto bspexit
   	end
   
   -- get template type
   select @templatetype=TemplateType
   from bHQWD with (nolock) where TemplateName=@templatename
   if @@rowcount = 0
   	begin
   	select @msg = 'Missing Document Template - ' + @templatename + '.', @rcode=1
   	goto bspexit
   	end
   
   if isnull(@templatetype,'') = ''
   	begin
   	select @msg = 'Missing template type for document template.', @rcode=1
   	goto bspexit
   	end
   
   -- create a cursor to to process document objects from bHQWO
   declare bcHQWF cursor FAST_FORWARD
   for select DocObject, ColumnName, MergeFieldName, MergeOrder, Format
   from bHQWF with (NOLOCK) where TemplateName = @templatename and WordTableYN='Y'
   -- Order By TemplateName, MergeOrder, Seq
   order by MergeOrder asc, TemplateName, Seq
   
   -- open cursor
   open bcHQWF
   select @opencursor = 1
   
   -- loop through bcHQWF cursor
   HQWF_loop:
   fetch next from bcHQWF into @docobject, @columnname, @mergefieldname, @mergeorder, @format
   
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
   if @wordtable = 'N'
   	begin
   	select @msg = 'Document Object is not set up for word table. Object - ' + isnull(@docobject,'') + '.', @rcode=1
   	goto bspexit
   	end
   
   -- update header string
   if isnull(@headerstring,'') = ''
   	select @headerstring = @mergefieldname
   else
   	select @headerstring = @headerstring + ',' + @mergefieldname 
   
   
   -- -- get object_id from sysobjects for base table
   -- select @object = 'b' + @objecttable
   -- select @objectid = id from sysobjects where name = @object
   select @objectid = id from sysobjects where name = @objecttable
   
   -- need to check if column is concatenated - if so need to do parts separately
   select @charpos = 0, @char = '+'
   exec dbo.bspParseString @columnname, @char, @charpos output, @retstring output, @retstringlist output, @errmsg output
   if @charpos = 0
   	begin
   	-- execute store procedure that will build column based on data type
   	----#141664
   	exec @rcode = bspHQWFMergeFieldByType @objectid, @columnname, @alias, @formatcolumn output, @msg OUTPUT, @PMCo
   	if @rcode <> 0 goto bspexit
   	-- add to column string
   	if isnull(@columnstring,'') = ''
   		select @columnstring = 'select ' + isnull(@formatcolumn,'')
   	else
   		select @columnstring = @columnstring + ', ' + isnull(@formatcolumn,'')
   	
   	goto HQWF_loop
   	end
   
   
   -- need to parse out columns and build separately then put back together to add to column string
   select @complete = 0, @columnlist = @columnname, @partstring = null
   while @complete = 0
   BEGIN
   	-- get part
   	set @char = '+'
   	exec dbo.bspParseString @columnlist, @char, @charpos output, @retstring output, @retstringlist output, @errmsg output
   	set @columnpart = ltrim(rtrim(@retstring))
   	set @columnlist = ltrim(rtrim(@retstringlist))
   	set @endcharpos = @charpos
   	set @filler = null
   
   	-- check part for non column values
   	if PATINDEX('%' + @pattern + '%', @columnpart) > 0 
   		begin
   		select @filler = @columnpart
   		exec dbo.bspParseString @columnlist, @char, @charpos output, @retstring output, @retstringlist output, @errmsg output
   		set @columnpart = ltrim(rtrim(@retstring))
   		set @columnlist = ltrim(rtrim(@retstringlist))
   		set @endcharpos = @charpos
   		if isnull(@filler,'') <> ''
   			select @partstring = @partstring + ' + ' + @filler + ' + '
   		end
   
   	-- execute store procedure that will build column based on data type
   	----#141664
   	exec @rcode = bspHQWFMergeFieldByType @objectid, @columnpart, @alias, @formatcolumn output, @msg OUTPUT, @PMCo
   	if @rcode <> 0 goto bspexit
   	if isnull(@partstring,'') = ''
   		select @partstring = 'isnull(' + @formatcolumn + ',' + CHAR(39) + CHAR(39) + ')'
   	else
   		select @partstring = @partstring + ' isnull(' + @formatcolumn + ',' + CHAR(39) + CHAR(39) + ')'
   
   	if @endcharpos = 0 set @complete = 1
   
   END
   
   -- do other types
   if isnull(@columnstring,'') = ''
   	select @columnstring = 'select ' + isnull(@partstring,'')
   else
   	select @columnstring = @columnstring + ', ' + isnull(@partstring,'')
   
   
   GOTO HQWF_loop
   
   
   
   HQWF_end:
   -- deallocate cursor
   if @opencursor = 1
       begin
       close bcHQWF
       deallocate bcHQWF
       select @opencursor = 0
       end
   
   
   
   
   
   
   -- create a cursor to to process document objects from bHQWO
   declare bcHQWO cursor FAST_FORWARD
   for select DocObject, LinkedDocObject, ObjectTable, JoinOrder, Alias, Required, JoinClause
   from bHQWO where TemplateType = @templatetype and WordTable = 'Y'
   Order By JoinOrder
   
   -- open cursor
   open bcHQWO
   select @opencursor_hqwo = 1
   
   -- loop through bcHQWO cursor
   HQWO_loop:
   fetch next from bcHQWO into @docobject, @linkeddocobject, @objecttable, @joinorder, @alias, @required, @joinclause
   
   if @@fetch_status <> 0 goto HQWO_end
   
   if @joinorder = 0 and @required <> 'Y'
   	begin
   	select @msg = 'First document object must be required. DocObject: ' + isnull(@docobject,'') + '!', @rcode = 1
   	goto bspexit
   	end
   
   if @joinorder = 0 and isnull(@joinclause,'') <> ''
   	begin
   	select @msg = 'First document object may not have a join clause. DocObject: ' + isnull(@docobject,'') + '!', @rcode = 1
   	goto bspexit
   	end
   
   if isnull(@joinstring,'') = '' and @joinorder <> 0
   	begin
   	select @msg = 'Missing base join clause, join order must be zero and required for first document object', @rcode = 1
   	goto bspexit
   	end
   
   -- get linked object data
   if isnull(@linkeddocobject,'') <> ''
   	begin
   	select @linkedobjecttable = ObjectTable
   	from bHQWO with (nolock) where TemplateType=@templatetype and DocObject=@linkeddocobject
   	if @@rowcount <> 1
   		begin
   		select @msg = 'Missing linked object - ' + isnull(@linkeddocobject,'') + ', cannot build join statement', @rcode = 1
   		goto bspexit
   		end
   	end
   
   -- create base join clause
   if @joinorder = 0
   	begin
   	select @joinstring = ' from ' + isnull(@objecttable,'') + ' ' + isnull(@alias,'') + ' with (nolock)'
   	goto HQWO_loop
   	end
   
   -- build required join clauses
   if @required = 'Y'
   	begin
   	select @joinstring = isnull(@joinstring,'') + ' join ' + isnull(@objecttable,'') + ' ' + isnull(@alias,'') + ' with (nolock) ON ' + isnull(@joinclause,'')
   	goto HQWO_loop
   	end
   
   -- -- build other joins for view
   -- if @viewjoins = 'Y'
   -- 	begin
   -- 	select @joinstring = @joinstring + ' left join ' + @objecttable + ' ' + @alias + ' with (nolock) ON ' + @joinclause + CHAR(13) + CHAR(10)
   -- 	goto HQWO_loop
   -- 	end
   
   -- if @templatetype is not 'Submit'
   if @templatetype <> 'Submit'
   	begin
   	select @joinstring = isnull(@joinstring,'') + ' left join ' + isnull(@objecttable,'') + ' ' + isnull(@alias,'') + ' with (nolock) ON ' + isnull(@joinclause,'')
   	goto HQWO_loop
   	end
   
   
   -- need to replace the SubFirm with the ArchEngFirm - not sending to sub
   -- select @joinclause = replace(@joinclause, 'SubFirm', 'ArchEngFirm')
   -- select @joinclause = replace(@joinclause, 'SubContact', 'ArchEngContact')
   select @joinstring = isnull(@joinstring,'') + ' left join ' + isnull(@objecttable,'') + ' ' + isnull(@alias,'') + ' with (nolock) ON ' + isnull(@joinclause,'')
   goto HQWO_loop
   
   
   
   
   HQWO_end:
   -- deallocate cursor
   if @opencursor_hqwo = 1
       begin
       close bcHQWO
       deallocate bcHQWO
       select @opencursor_hqwo = 0
       end
   
   
   
   -- add @columnstring and @joinstring together
   select @columnstring = isnull(@columnstring,'') + isnull(@joinstring,'')
   
   
   
   
   
   
   
   
   
   bspexit:
   	-- deallocate cursor
   	if @opencursor = 1
       	begin
       	close bcHQWF
       	deallocate bcHQWF
       	select @opencursor = 0
       	end
   
   	-- deallocate cursor
   	if @opencursor_hqwo = 1
   	    begin
   	    close bcHQWO
   	    deallocate bcHQWO
   	    select @opencursor_hqwo = 0
   	    end
   
       if @rcode<>0 select @msg=isnull(@msg,'')
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWFMergeFieldBuildForTables] TO [public]
GO
