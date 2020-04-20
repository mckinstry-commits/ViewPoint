SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jonathan Paullin 
-- Create date: 02/17/2009
-- Description:	#129835 - This function will generate the dynamic sql need to create/update a view
--				based on our current security settings in DDSLShared. (adapted from vspVAViewGen)
-- Modified by:	JG 11/29/10 - JCJM view needs to be filtered when created.
-- =============================================
CREATE FUNCTION [dbo].[vfVAViewGenQuery]
(
	-- Add the parameters for the function here
	@viewname varchar(60),  @tablename varchar(60) = null
)
RETURNS varchar(max)
AS
BEGIN

	declare @fromclause varchar(max), @whereclause varchar(max), @instancecol varchar(30), 
			@datatype varchar(30), @inputtype tinyint, @qualifycol varchar(30), @i int, 
			@securecolcount int, @firstnull tinyint, @onedatatypewhereclause varchar(1000), 
			@closeisnull tinyint, @dynamicSqlQuery varchar(max), @viewOutOfSync char(1)

	select @firstnull = 0 	-- identifies first null secure column  

	select @onedatatypewhereclause = null				 
  
	-- check for datatype security
	select @securecolcount = count(*)
	from DDSLShared s with (nolock) JOIN DDDTShared d with (nolock) ON s.Datatype=d.Datatype
	where s.TableName = @tablename and s.InUse = 'Y' and d.Secure = 'Y'
   
	-- construct view text
	if @securecolcount = 0	-- no secure datatypes
   		select @fromclause = @viewname + ' as select a.* From ' + @tablename + ' a'
	else 
	begin
   		-- use a cursor to process all secure datatypes
		declare SecureDatatype cursor local fast_forward for
   		select s.InstanceColumn, s.Datatype, d.InputType, s.QualifierColumn
		from DDSLShared s (nolock)
		JOIN DDDTShared d with (nolock) ON s.Datatype=d.Datatype
		where s.TableName = @tablename and s.InUse = 'Y' and d.Secure = 'Y'	-- must be 'in use' and 'secure'
		
		select @whereclause='' -- clear out any previous calue
     
	 open SecureDatatype
 	 select @i = 0, @firstnull = 0, @fromclause = @viewname + ' as select a.* from ' 
		+ @tablename + ' a '+char(13)+'   where '
		+' (suser_sname() = '+char(39)+'viewpointcs'+char(39)+' or '
        +' suser_sname() = '+char(39)+'VCSPortal'+char(39)+' or '
        
	 if @securecolcount>1 select @fromclause = @fromclause + char(13)+Space(6)+'(  '
 	 next_SecureDatatype:
 	    fetch next from SecureDatatype into @instancecol, @datatype, @inputtype, @qualifycol
 		
 		if @@fetch_status <> 0 goto SecureDatatype_end
 
 		select @i = @i + 1
		select @closeisnull=0 -- reset for each column if it is nullable or not

		-- add 'and' to each additional column
		if @i>1 select @whereclause = @whereclause + char(13)+space(6) + 'and '

 		-- construct portion of where clause used to test for null values
		if COLUMNPROPERTY( OBJECT_ID(@tablename),@instancecol,'AllowsNull')=1
 			begin
  			select @whereclause = @whereclause +'(a.' + @instancecol + ' is null or'
			select @closeisnull=1 -- need to know whether to close the parenethesis or not
			end

         select @whereclause = rtrim(@whereclause) + char(13)+space(10)+ 'exists(select top 1 1 from vDDDU c' + convert(varchar(4), @i)+	
				' with (nolock) '+char(13)
         select @whereclause = @whereclause + space(10)+'where a.' + @qualifycol + '=c' + convert(varchar(4), @i) + '.Qualifier '
 
         -- conversion may be necessary based on input type
         if @inputtype <> 1 and @inputtype <> 6
				begin
				select @whereclause = @whereclause + 'and a.' + @instancecol + '=c' + convert(varchar(4), @i) + '.Instance '
				end
          else	-- numeric
			begin
			 if @datatype = 'bEmployee'
				select @whereclause = @whereclause + 'and a.' + @instancecol + ' = c' + convert(varchar(4), @i) + '.Employee '
			 else
				select @whereclause = @whereclause + 'and convert(varchar(30),a.' + @instancecol + ') = c' + convert(varchar(4), @i) + '.Instance '
			end
 		select @whereclause = @whereclause + char(13)+space(10)+'and c' + convert(varchar(4), @i)
            	+ '.Datatype =''' + rtrim(@datatype) + ''' and c' + convert(varchar(4), @i)
 			    + '.VPUserName=suser_sname() )'
	    if @closeisnull=1 select @whereclause = @whereclause +')' 

 		goto next_SecureDatatype	-- get next secure column
 	
 	SecureDatatype_end:		-- finished with cursor on sercured columns
 		close SecureDatatype
     	deallocate SecureDatatype		
    end
 
 -- put it all together
 select @dynamicSqlQuery = @fromclause
 if @securecolcount > 0 
 	begin
 	
 	select @dynamicSqlQuery = @dynamicSqlQuery  + rtrim(@whereclause) + char(13)+Space(3)+ ')'
	if @i > 1  select @dynamicSqlQuery=@dynamicSqlQuery+'  )'  -- close the paranthesis for 'and'
	
	 	-- JG 11/29/10 - JCJM view needs to be filtered when created.
	IF (@viewname = 'JCJM')
		BEGIN
			SELECT @dynamicSqlQuery = @dynamicSqlQuery + CHAR(13) + SPACE(3) + 'and a.PCVisibleInJC = ''Y'''
		END
	
 	end 			 	 	
 else
	begin
	-- JG 11/29/10 - JCJM view needs to be filtered when created.
	IF (@viewname = 'JCJM')
		BEGIN
			SELECT @dynamicSqlQuery = @dynamicSqlQuery + CHAR(13) + 'WHERE a.PCVisibleInJC = ''Y'''
		END
	end
 	
-- Append create or alter depending on if the view already exists.
if object_id(@viewname) is null
	set @dynamicSqlQuery = 'create view ' + @dynamicSqlQuery
else
 	set @dynamicSqlQuery = 'alter view ' + @dynamicSqlQuery 
  	
	RETURN @dynamicSqlQuery
END

GO
GRANT EXECUTE ON  [dbo].[vfVAViewGenQuery] TO [public]
GO
