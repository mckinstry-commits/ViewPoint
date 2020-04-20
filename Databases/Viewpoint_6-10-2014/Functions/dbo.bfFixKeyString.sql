SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* ALTER  bfFixKeyString */
  /* gf 04/07/04 - #24286 - expanded keyfield from 255 to 500. */
  /* gf 07/08/04 - # - Fix 'is' bug.  Problem with user named isoldebender. */
  /* RM 02/17/05 - #27158 - changed @columnname from varchar(20) to varchar(50)*/
  /* RM 03/12/07 - #123965 - Changed to allow <> operator in addition to 'is' and '='*/
  /* JVH 10/19/10 - #141299 - Changed @table to varchar(128)*/
  
  CREATE    function [dbo].[bfFixKeyString](@keystring varchar(500),@table varchar(128))
         returns varchar(500)
         as
         begin
     		declare @firstpos int, @secondpos int,@checkval varchar(30),@returnkeystring varchar(500)
     		declare @tmpcounter int,@columnname varchar(50), @value varchar(50),@fixcolpos int,
     				@datatype varchar(50),@count int
     
     		declare @ispos int, @equalpos int, @notequalpos int, @leastpos int, @operator varchar(4)
     
     		--remove and fix some characters
     		

  
			--Fix Equal
     		select @keystring = replace(@keystring,'= "','="')
   			select @keystring = replace(@keystring,'= ''','=''')
     		select @keystring = replace(@keystring,' =','=')
     		--Fix Not Equal
			select @keystring = replace(@keystring,'<> "','<>"')
   			select @keystring = replace(@keystring,'<> ''','<>''')
     		select @keystring = replace(@keystring,' <>','<>')
    		--Fix And
			select @keystring = replace(@keystring,'=AND','= AND')
     		select @keystring = replace(@keystring,'"','''')
     		--select @keystring = replace(@keystring,char(39),'')
     		
     
     
     		select @firstpos = 0,@secondpos = 0
     		
     		if upper(Left(ltrim(@keystring),3)) = 'AND'
     			select @keystring = Right(ltrim(@keystring),len(ltrim(@keystring)) - 3)
     
     NextCompare:
			select @leastpos = -1
			select @ispos = charindex(' is ',@keystring,@secondpos)
			select @equalpos = charindex('=',@keystring,@secondpos)
			select @notequalpos = charindex('<>', @keystring, @secondpos)
			
			
			if (@ispos < @leastpos or @leastpos=-1) and @ispos <> 0
				select @leastpos = @ispos, @operator=' is'
			if (@equalpos < @leastpos or @leastpos=-1) and @equalpos <> 0
				select @leastpos = @equalpos, @operator='='
			if (@notequalpos < @leastpos or @leastpos=-1) and @notequalpos <> 0
				select @leastpos = @notequalpos, @operator='<>'
				
			if @leastpos <= 0
				goto bfexit
			else
				select @firstpos = @leastpos

/*
     		if (charindex(' is ',@keystring,@secondpos) < charindex('=',@keystring,@secondpos)) and
     			charindex(' is ',@keystring,@secondpos) <> 0 and charindex(' is ',@keystring,@secondpos) > @firstpos
     		begin
     			select @firstpos = charindex(' is ',@keystring,@secondpos)
     		end
     		else
     		begin
     			select @firstpos = charindex('=',@keystring,@secondpos)
     		end
     		
     		
     
     		if @firstpos = 0
     			goto bfexit*/
     
     select @fixcolpos = 0
     		--FIX COLUMN NAME
     		select @columnname = substring(@keystring,@secondpos +1, @firstpos - @secondpos - 1)

     		select @fixcolpos = charindex(' ',@columnname)

     		select @columnname = right(@columnname,len(@columnname) - @fixcolpos)

     		select @fixcolpos = charindex(' ',@columnname)

     		select @columnname = left(@columnname,(len(@columnname) - @fixcolpos) + 1)

     		select @fixcolpos = charindex('.',@columnname)

     		select @columnname = right(@columnname,len(@columnname) - @fixcolpos)

  		select @columnname = replace(@columnname, '[', '')
  		select @columnname = replace(@columnname, ']', '')
  
     		--END FIX COLUMNNAME
     		
     		select @secondpos = charindex(' AND',upper(@keystring),@firstpos)
   
   		if @table = 'JCCB' and @columnname='JCTrans' 
   			select @columnname = 'CostTrans'
     		

     		--IF COLUMN IS NOT IN TABLE, THEN GOTO NEXT
     		select @count = count(*) from syscolumns where name=@columnname and id=object_id(@table)
     		if @count = 0 and @columnname = 'Co'
   		begin
   			select @count = count(*) from syscolumns where name=case left(@table,1) when 'b' then left(right(@table,len(@table)-1),2) else left(@table,2) end + @columnname and id=object_id(@table)
   			if @count <> 0 
   				select @columnname = case left(@table,1) when 'b' then left(right(@table,len(@table)-1),2) else left(@table,2) end + @columnname
   		end
   		if @count = 0 and right(@columnname,2) = 'Co' and @columnname <> 'Co'
   		begin
   			select @count = count(*) from syscolumns where name='Co' and id=object_id(@table)
   			if @count <> 0
   					select @columnname = 'Co'
   		end  		
   
   		if @count=0
     			goto EndLoop
     		
   		
     
     		--FIND VALUE
     		if @secondpos = 0
     			select @value = substring(@keystring,@firstpos + len(@operator),(len(@keystring) - @firstpos))
     		else
     			select @value = substring(@keystring,@firstpos + len(@operator),(@secondpos - @firstpos) - len(@operator))

     		if @value <> ''''''
  			select @value=replace(@value,char(39),'')
  			
     		--FIND DATATYPE,SCALE OF COLUMN
     		select @datatype = type_name(xtype) from systypes where xusertype = (select xusertype from syscolumns where name=@columnname and id=object_id(@table))
     		
     		--set value = null if nothing in it
     		if isnull(@value,'') = '' 
     			select @value = 'is null'
     
     		--APPEND, IF NOT NUMERIC, THEN PUT QUOTES
     		select @returnkeystring = isnull(@returnkeystring,'') + 
     			case when isnull(@returnkeystring,'') = '' then '[' else ' and [' end + 
     			@columnname + ']' + @operator + 
     			case when @operator=' is' then @value when @datatype not in ('tinyint', 'smallint', 'int', 'bigint', 'decimal', 'numeric', 'money') then '''' + @value + '''' else @value end
     			
     
     		
     EndLoop:
     		if @secondpos <> 0
     			goto NextCompare		
     
     bfexit:			
     --  return(@secondpos)
     	return(ltrim(@returnkeystring))
         end

GO
GRANT EXECUTE ON  [dbo].[bfFixKeyString] TO [public]
GO
