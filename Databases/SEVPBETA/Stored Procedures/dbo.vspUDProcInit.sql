SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       PROCEDURE [dbo].[vspUDProcInit] 
     /******************************************************
     	Created  04/05/01 RM
    	Modified 12/03/01 RM  Changed to add quotes to value if needed, and leave off if not needed
                 06/13/02 RM  Changed to add [ and ] around some column names that were missed.
   				 01/10/03 RM  Make Parameters be passed in in order entered by form.
     			 07/10/07 JK expand @valproc to 60 chars.
				 08/10/07 JonathanP - Adapted this stored procedure from bspUDProcInit.
				 09/07/07 JonathanP - Added a check to make sure @msg gets added correctly is @parameters is null.
				 09/21/07 JonathanP - @columnname length changed from a varchar(30) to varchar(50). See issue 124950

     	Creates Text for  stored procedure for UDUserVal form based on user parameters 
     	and returns it to the form
     
     
     *******************************************************/
     (@valproc varchar(60),@msg varchar(8000) output)
    
     
     AS
     
     declare @rcode int,@seq int,@andor varchar(5),@typepc char(1), @param varchar(20),@operator varchar(5),
                 @type char(1),@columnname varchar(50),@value varchar(50),@notes varchar(255),
     	@tablename varchar(30),@comment varchar(255),@errmsg varchar(255),@crlf varchar(10),@numparens int,@desccolumn varchar(20)
     
     declare @parameters varchar(500),@checks varchar(500),@checkstring varchar(5000)
     
     declare paramcursor cursor for select d.Parameter from bUDVD d where d.ValProc = @valproc and d.TypePC = 'P' order by Seq
     
     declare tablecursor cursor for select TableName,ErrorMessage,DescriptionColumn from bUDVT where ValProc = @valproc
     
     select @rcode = 0,@crlf = char(13) + char(10),@numparens = 0
     
     open paramcursor
     fetch next from paramcursor into @param

	-- Loop through each parameter and add the generated text for it.
	while @@Fetch_status = 0
    begin	   
   		if charindex('@' + @param + ' varchar(100)',isnull(@parameters,'')) = 0
   		begin
   	  		if @parameters is null
   	  		begin
   	  			select @parameters = '('
   	  		end
   	  		else
   	  		begin
   	  			select @parameters = @parameters + ', '
   	  		end
	   	  	
   	  		select @parameters = @parameters + '@' + @param +  ' varchar(100)'
   		end  	
     fetch next from paramcursor into @param
	end
     
	-- Add the @msg parameter.
	if @parameters is null 
	begin
		select @parameters = '(@msg varchar(255) output)'
	end
	else
	begin
		select @parameters = @parameters + ', @msg varchar(255) output)'	
	end     
     
     select @msg = '/** User Defined Validation Procedure **/' + @crlf +
     				  @parameters + @crlf + 'AS' + @crlf + @crlf + 'declare @rcode int' + @crlf + 'select @rcode = 0'
     close paramcursor
     deallocate paramcursor    

     open tablecursor
     fetch next from tablecursor into @tablename,@errmsg,@desccolumn
     while @@Fetch_status = 0
     begin
     
     	declare checkcursor cursor for select d.AndOr,d.TypePC,d.Parameter,d.Operator,d.Type,d.ColumnName,d.Value,d.Notes,h.Notes
     	from bUDVH h inner join bUDVT t on h.ValProc = t.ValProc inner join  bUDVD d on t.ValProc = d.ValProc and t.TableName = d.TableName  where t.TableName = @tablename and h.ValProc = @valproc
     	order by d.Seq
     	
     	open checkcursor
     	fetch next from checkcursor into @andor,@typepc,@param,@operator,@type,@columnname,@value,@notes,@comment
     	while @@fetch_status = 0
     	begin
     
     		
     		--Keep track of the number of parentheses, so that we can make sure all are closed when the procedure is returned
     		if @andor like '%(%'
     		begin
     			select @numparens = @numparens + 1
     		end
     		if @andor like '%)%'
     		begin
     			select @numparens = @numparens - 1
     		end
     		
    
    		declare @datatype varchar(30)
    
    		select @datatype = type_name(xtype) from systypes where xusertype = (select xusertype from syscolumns where name=@columnname and id=object_id(@tablename))
    		
    		
    
    		--if comparing to a non numeric column, then make sure the value has quotes around it
    		if @datatype not in ('tinyint', 'smallint', 'int', 'bigint', 'decimal', 'numeric', 'money') and @typepc='C'
    		begin
    	 		select @checks = isnull(@checks,'') + isnull(@andor,'') + case @typepc when 'P' then  '  @' when 'C' then  ' [' end +  @param +  case @typepc when 'P' then  ' ' when 'C' then  ' ]' end + @operator + ' '  + case @type when 'V' then char(39) + @value + char(39) when 'C' then
     				 'convert(varchar(100),' + @columnname + ')' end + ' '
     		end	
    		else --otherwise, put quotes around it based on if its numeric or not.
    		begin
    			select @checks = isnull(@checks,'') + isnull(@andor,'') + 
    			case @typepc when 'P' then  '  @' when 'C' then  ' [' end
    			 +  @param +  
    			case @typepc when 'P' then  ' ' when 'C' then  '] ' end
    			 + @operator + ' ' + 
    			case @type when 'V' then 
    				case when isnumeric(@value)=1/*true*/ then @value else char(39) + @value + char(39) end
    			when 'C' then '[' + @columnname + ']' end + ' '
    		end
    		
    		
     		
     		
     	fetch next from checkcursor into @andor,@typepc,@param,@operator,@type,@columnname,@value,@notes,@comment
     	end
     	
     	close checkcursor
     	deallocate checkcursor
     	
     	
     	while @numparens > 0
     	begin
     		select @checks = @checks + ')'
     		select @numparens = @numparens - 1
     	end
     
     	select @numparens = 0
     
     	
     	if @checks is not null
     	begin
     		select @checkstring = '/**' +  isnull(@comment,'') + '**/' + char(13) + char(10) + 'if exists(select * from [' + @tablename + '] with (nolock) where ' + @checks
     	
     		select @msg = isnull(@msg,'') + @crlf + @crlf + @crlf + isnull(@checkstring,'') + ')' + @crlf +
     				'begin' + @crlf +
     				'select @msg = isnull(' + case when @desccolumn is not null then '[' + @desccolumn + ']' else 'null' end + ',@msg) from [' + @tablename + '] with (nolock) where ' + @checks + @crlf +
     				'end' + @crlf +
     				'else' + @crlf +
     				'begin' + @crlf +
     				'select @msg = ' + char(39) + isnull(@errmsg,'') + char(39)  + ', @rcode = 1' + @crlf + 
     				'goto spexit' + @crlf +
     				'end'
     
     	
     	select @checks = null
     	end
     	fetch next from tablecursor into @tablename,@errmsg,@desccolumn
     end
     
     
     
     close tablecursor
     deallocate tablecursor
     
     select @msg = @msg + @crlf + @crlf + 'spexit:' + @crlf + @crlf + 'return @rcode'

GO
GRANT EXECUTE ON  [dbo].[vspUDProcInit] TO [public]
GO
