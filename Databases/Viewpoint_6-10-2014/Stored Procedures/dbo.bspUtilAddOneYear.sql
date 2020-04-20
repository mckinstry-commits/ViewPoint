SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspUtilAddOneYear]
    as
    /* bspUtilAddOneYear - creates a sql script to add 1 year to all dates */
    /* Author: JRE 4/16/99 */
    /*    Mod  JRE 2/4/00 - fixed bug where sometimes 2 years were added */
    /* should never be run at a customers site !!! */
    
    begin
    set nocount on
   --- safety check make sure we only run on certain databases
    if (select db_name())<>'VisTestData'
    	return
    
    declare @name varchar(30),@colname varchar(30), @id int, @msg varchar(255)
    select @name=min(o.name)
    from sysobjects o where o.type='U'
    while @name is not null
    begin
    select @id=object_id(@name)
    select @colname=min(name) 
    from syscolumns c
    where c.id=@id and  c.type in
     (select type from systypes where name in ('datetime','smalldatetime'))
    while @colname is not null
    begin
    print 'set nocount on'
    Print ''
    select @msg= 'print ''updating ' + @name + '  column: '+@colname+''''
    print @msg
    PRINT ''
    select @msg='alter table ' + @name + ' disable trigger ALL'
    print @msg
   
    print 'declare @date datetime'
    select @msg='select @date=max(' + @colname + ') from ' + @name
    print @msg
    print 'while @date is not null'
    print 'begin'
    print '    begin tran'
    select @msg='   update '+@name+' set '+@colname+'=DateAdd(year,1,'+@colname+') where '+@colname+' is not null'
   print @msg
   
    select @msg=' and '+@colname+'=@date'
    print @msg
    print '    select @@rowcount'
    print '    commit tran'
   
   
    select @msg='   select @date=max(' + @colname + ') from ' + @name + '  where '+@colname+'<@date'
    print @msg
   
    print '    checkpoint'
    print 'end'
    print 'select getdate()'
    select @msg='alter table ' + @name + ' enable trigger ALL'
    print @msg
    print 'go'
    print ''
    
    -- get next column
    select @colname=min(name) 
    from syscolumns c
    where c.id=@id and name>@colname and c.type in
     (select type from systypes where name in ('datetime','smalldatetime'))
    end
    -- get next table
   
    select @name=min(o.name)
    from sysobjects o where o.type='U' and name>@name
    end
    end

GO
GRANT EXECUTE ON  [dbo].[bspUtilAddOneYear] TO [public]
GO
