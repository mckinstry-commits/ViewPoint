SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[bspHQWFColumnNameVal]
/***********************************************************
 * CREATED By:	GF 01/08/2002
 * MODIFIED BY:	GF 01/26/2004 - issue #18841 allow multiple columns in @columnname check for '+'
 *
 * USAGE:
 *   validates HQ Document Template column name for document object table
 *
 *	PASS:
 *  ObjectTable		Document Object Table
 *	 ColumnName		Column name for object table to be validated
 *	 MergeFieldType		Either 'R' for reqular type merge field or 'T' for table type merge field
 *
 *	RETURNS:
 *  @xusertype_name	Data type name for numeric data types only
 *  ErrMsg if any
 * 
 * OUTPUT PARAMETERS
 *   @msg     Error message if invalid, 
 * RETURN VALUE
 *   0 Success
 *   1 fail
 *****************************************************/ 
(@objecttable varchar(30), @columnname varchar(80), @mergefieldtype varchar(1),
 @numeric_precision tinyint = null output, @domain_name varchar(128) = null output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @part varchar(30), @char char(1), @charpos int, @endcharpos int,
   		@complete tinyint, @retstring varchar(max), @retstringlist varchar(max), 
   		@columnlist varchar(80), @columnpart varchar(80), @errmsg varchar(255),
   		@pattern varchar(10) ----, @xtype int, @object_id int, @slit_object int

select @rcode = 0, @complete = 0, @endcharpos = 0, @charpos = 0, @pattern = '''' + '%_%' + ''''

if isnull(@columnname,'') = ''
   	begin
   	select @msg = 'Missing column name.', @rcode = 1
   	goto bspexit
   	end

if isnull(@mergefieldtype,'') = '' set @mergefieldtype = 'R'

---- get numeric precision and domain name from INFORMATION_SCHEMA.COLUMNS
if exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @objecttable)
	begin
	select @numeric_precision=NUMERIC_PRECISION, @domain_name=DOMAIN_NAME
	from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @objecttable and COLUMN_NAME=@columnname
	end


---- get object table object_id from sysobjects for SLIT
----select @slit_object = id from sysobjects where name = 'SLIT'

---- get object table object_id from sysobjects
----select @object_id = id from sysobjects where name = @objecttable
--if @@rowcount <> 0 
--   	begin
--   	-- if valid object_id get xusertype_name and SQL datatype from systypes
--   	select @xusertype_name = d.name, @xtype = d.xtype
--   	from systypes d join syscolumns c on c.xusertype=d.xusertype
--   	where c.name=@columnname and c.id=@object_id
--   	if @@rowcount <> 0
--   		begin
--   		-- check if numeric data type, we only care about numerics
--   		if @xtype not in(48,52,56,59,60,62,106,108,122,127)
--   			begin
--   			select @xusertype_name = null
--   			end
--   		end
--   	end


set @char = '+'
exec dbo.bspParseString @columnname, @char, @charpos output, @retstring output, @retstringlist output, @errmsg output

---- if @charpos is 0 then no multiple columns validate @columnname to syscolumns
if @charpos = 0
   	begin
   	if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME=@objecttable and COLUMN_NAME=@columnname)
   		begin
   	 	select @msg = 'Column does not exist for Document Object Table: ' + isnull(@objecttable,'') + ' Column: ' + isnull(@columnname,'') + ' .', @rcode = 1
   	 	goto bspexit
   		end
   	-- if object table is PMSL and column name starts with 'ud' must exist in SLIT also
   	if @objecttable = 'PMSL' and substring(@columnname,1,2) = 'ud' and @mergefieldtype = 'T'
   		begin
   		if not exists(select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME=@columnname and TABLE_NAME='SLIT')
   			begin
   	 		select @msg = 'To use a user memo column, must exist in both PMSL and SLIT with the same name.', @rcode = 1
   	 		goto bspexit
   			end
   		end
   	goto bspexit
   	end

---- if reqular type merge field - do not allow concatenation
if @charpos > 0 and @mergefieldtype = 'R'
   	begin
   	select @msg = 'Invalid column name', @rcode = 1
   	goto bspexit
   	end


set @columnlist = @columnname
while @complete = 0
BEGIN
   	---- get part
   	set @char = '+'
   	exec dbo.bspParseString @columnlist, @char, @charpos output, @retstring output, @retstringlist output, @errmsg output
   	set @columnpart = ltrim(rtrim(@retstring))
   	set @columnlist = ltrim(rtrim(@retstringlist))
   	set @endcharpos = @charpos
   
   	---- check part for non column values
   	if PATINDEX('%' + @pattern + '%', @columnpart) > 0 
   		begin
   		exec dbo.bspParseString @columnlist, @char, @charpos output, @retstring output, @retstringlist output, @errmsg output
   		set @columnpart = ltrim(rtrim(@retstring))
   		set @columnlist = ltrim(rtrim(@retstringlist))
   		set @endcharpos = @charpos
   -- 		select @charpos, @columnpart, @columnlist
   		end
   
   	---- validate column to syscolumns
   	if @endcharpos > 0
   		begin
   		if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME=@objecttable and COLUMN_NAME=@columnpart)
   			begin
   		 	select @msg = 'Column: ' + isnull(@columnpart,'') + ' does not exist for Document Object Table.', @rcode = 1
   		 	goto bspexit
   			end
   		---- if object table is PMSL and column name starts with 'ud' must exist in SLIT also
   		if @objecttable = 'PMSL' and substring(@columnpart,1,2) = 'ud' and @mergefieldtype = 'T'
   			begin
   			if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='SLIT' and COLUMN_NAME=@columnname)
   				begin
   		 		select @msg = 'To use a user memo column, must exist in both PMSL and SLIT with the same name.', @rcode = 1
   		 		goto bspexit
   				end
   			end
   		end
   
	if @endcharpos = 0 set @complete = 1
   
	--select @endcharpos, @columnpart, @columnlist, @errmsg, @complete

END


bspexit:
   	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWFColumnNameVal] TO [public]
GO
