SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Procedure [dbo].[bspTableDiff]
   /**********************************************
   	Created 04/30/01 RM
   
   	Returns all differences for tables in a particular module
   
   	pass in:
   	@mod - Module ex( 'DD','MS','AP')
   
   **********************************************/
   (@mod char(2),@errmsg varchar(255) output)
   as
   
   declare @tablename varchar(20),@selectstring varchar(8000),@columnname varchar(30),
   @wherestring varchar(4000),@numkeys int,@numcolumns int,@rcode int
   
   select @rcode = 0
   
   if @mod is null
   begin
   	select @errmsg = 'Missing Module',@rcode = 1
   	goto bspexit
   end
   
   
   
   declare tablecursor cursor for select name from sysobjects where name like 'b' + @mod + '%' and name not like '%[Aa]udit%'
   open tablecursor
   fetch next from tablecursor into @tablename
   while @@fetch_status = 0
   begin
   
   select @numcolumns = 0
   select @numkeys = isnull(len(keys),0) from sysindexes where id = object_id(@tablename) and name like 'bi' + @mod + '%'
   if @numkeys = 32
   begin
   	select @numkeys = 1
   end
   else
   begin
   	select @numkeys = (@numkeys - 32) / 32
   end
   
   declare columncursor cursor for select name from syscolumns where id = object_id(@tablename)
   open columncursor
   fetch next from  columncursor into @columnname
   while @@fetch_status = 0
   begin
   
   	if @columnname = 'Notes'
   	goto ColLoop
   
   	if @wherestring is null
   	begin
   		select @wherestring = ''
   	end
   	else
   	begin
   		if @numkeys >= @numcolumns
   		begin
   			select @wherestring = @wherestring + ' and '
   		end
   		else
   		begin
   			if @numkeys = @numcolumns - 1
   			select @wherestring = @wherestring + ' and ('
   			else
   			select @wherestring = @wherestring + ' or '
   		end
   	end
   	
   	
   	
   	if @numkeys >= @numcolumns
   	begin
   		select @wherestring = @wherestring + 'v1.' + @columnname + ' = v2.' + @columnname
   		select @numcolumns = @numcolumns + 1
   	end
   	else
   	begin
   		select @wherestring = @wherestring + 'v1.' + @columnname + ' <> v2.' + @columnname
   		select @numcolumns = @numcolumns + 1	
   	end
   
   	ColLoop:
   
   	fetch next from columncursor into @columnname
   end
   close columncursor
   deallocate columncursor
   
   select @selectstring = 'select ' + char(39) + @tablename + char(39) + ',* from Viewpoint.dbo.' + @tablename + ' v1, VisTestData.dbo.' + @tablename + ' v2 where ' + @wherestring + case isnull(@numkeys,0) when 0 then '' when -1 then '' when @numcolumns  then ''  else ')' end
   
   select @wherestring = null
   
   --exec(@selectstring)
   --if @@rowcount<>0
   print @selectstring
   
   fetch next from tablecursor into @tablename
   end
   
   close tablecursor
   deallocate tablecursor
   
   bspexit:
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspTableDiff] TO [public]
GO
