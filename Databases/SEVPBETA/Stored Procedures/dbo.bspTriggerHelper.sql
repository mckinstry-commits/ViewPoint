SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspTriggerHelper    Script Date: 8/28/99 9:33:43 AM ******/
    CREATE   proc [dbo].[bspTriggerHelper] (@tablename varchar(30)=null, @triggertype varchar(1), @cursorYN varchar(1))
    as
    set nocount on
    /*helps in creating declare statement for a cursor */
    begin
        declare @m varchar(200), @k int, @type varchar(20), @dim int,
    
        @typeword varchar(10),@cursor varchar(30),@t varchar(30),@itype int,
         @totcols int
        if @tablename is null
        begin
            select 'You must supply a tablename'
            return 1
        End
        select @m=null
        
        if @triggertype not in ('i','d','u')
        begin
            select 'Type must be i,d,u'
            return (1)
        End
        select @typeword=case @triggertype
            when 'i' then 'insert'
            when 'd' then 'delete'
            when 'u' then 'update'
            End
        select @cursor=null
        if @cursorYN in ('Y','y')
        begin
            select @cursor=@tablename + '_' + @typeword
        End
        set nocount on
        set rowcount 1
        
        select @m='create trigger bt' + substring(@tablename,2,10)  + @triggertype  + ' on '+@tablename+ ' for '+@typeword +' as'
        print @m
        Print '/*-----------------------------------------------------------------'
        select @m=' *   This trigger rejects '+ @typeword +' in ' + @tablename
        print @m
        Print ' *    if the following error condition exists:'
        Print ' *'
        select @m=' *   Author: ????  ' + convert(varchar(30),getdate())
        print @m
        Print ' *-----------------------------------------------------------------*/'
        Print ''
        Print 'declare @errmsg varchar(255), @validcnt int, @errno int,'
        Print '   @numrows int, @nullcnt int,'
        select @m=null
     
        select @totcols=max(a.colid) from syscolumns a
            join systypes b on a.usertype=b.usertype
            where a.id=object_id(@tablename)
    
            and b.name<>'bNotes'
        if @cursor is not null
        begin
           Print '   @date smalldatetime, @user varchar(30),@rowsprocessed int,'
           Print '   @tablename varchar(10), @opencursor tinyint,@field varchar(30),'
           Print '   @old varchar(30), @new varchar(30),@key varchar(30),@rectype char(1),'
           select @k=0,@m='  '
           while @k<999
           begin
            select @m=@m+' @'+a.name + ' ' + b.name , @type=b.name,
            @dim=a.length
            from syscolumns a join systypes b on a.usertype=b.usertype
            where a.id=object_id(@tablename) and b.name<>'bNotes'
            and a.colid>@k
            order by colid
            if @@rowcount=0
            break
            if @type='varchar' or @type='char'
               select @m=@m+'('+convert(varchar(3),@dim)+')'
    
            if @k+1<>@totcols or @triggertype='u'
                select @m=@m + ','
            
            select @k=@k+1
            
            if datalength(@m)>60
            begin
                print @m
                select @m='  '
            End
            continue
          End
          print @m
          select @m='  '
    
          select @k=0
      if @triggertype='u'
      begin
          while @k<999
          begin
            select @m=@m+' @old'+a.name + ' ' + b.name , @type=b.name,
            @dim=a.length
            from syscolumns a
            join systypes b on a.usertype=b.usertype
            where a.id=object_id(@tablename) and b.name<>'bNotes'
            and a.colid>@k
            order by colid
            if @@rowcount=0
                break
            if @type='varchar' or @type='char'
                select @m=@m+'('+convert(varchar(3),@dim)+')'
            if @k+1<>@totcols 
              select @m=@m + ','
            if datalength(@m)>60
            begin
                print @m
                select @m='  '
            End
            select @k=@k+1
            continue
          End
        end
    
        print @m
      end
    
        Print 'select @numrows = @@rowcount'
        Print 'if @numrows = 0 return'
        Print ''
        if @cursor is not null
        begin
            Print 'select @date = getdate(), @user = SUSER_SNAME(), @tablename=' + CHAR(39) + 'bJCCM' + CHAR(39) + ',@rectype=' + CHAR(39) + 'C' + CHAR(39)
            Print 'select @opencursor = 0, @rowsprocessed=0'
            Print ''
            Print 'if @numrows = 1'
            
            /* select into */
            select @k=0, @m=null
            while @k<999
            begin
                if @m is null
                select @m='   select '
                select @m=@m+' @'+a.name + ' = ' + a.name
                    from syscolumns a
                    where a.id=object_id(@tablename)
                    and a.colid>@k
                    order by colid
                if @@rowcount=0 break
                if @k+1<>@totcols select @m=@m + ','
                 select @k=@k+1
                if datalength(@m)>60
                begin
                    print @m
                    select @m='      '
                End
                continue
            End
            print @m
            select @k=0, @m=null
            if @triggertype='d'
               print '   from deleted'
            else
               Print '   from inserted'
            Print 'else'
            Print 'begin   /* use a cursor to process each updated row */'
            select @m= '   declare ' + @cursor + ' cursor for'
            print @m
            select @m=null
            while @k<999
            begin
                if @m is null
                select @m='   select '
                select @m=@m+a.name
                from syscolumns a
                where a.id=object_id(@tablename)
                and a.colid>@k
                order by colid
                if @@rowcount=0 break
                if @k+1<>@totcols select @m=@m + ','
                select @k=@k+1
                if datalength(@m)>60
                begin
                    print @m
                    select @m='      '
                End
                continue
            End
            print @m
            if @triggertype='d'
               print '   from deleted'
            else
               Print '   from inserted'
            select @m='   open '+@cursor
            print @m
            print '   select @opencursor=1'
            print 'end'
            print 'NEXTROW:'
            /* select into */
            select @k=0, @m=null
            print @m
            print 'if @opencursor=1'
            print '   begin'
            while @k<999
            begin
                if @m is null
                    select @m='      fetch next from '+ @cursor + ' into '
                select @m=@m+ '@'+a.name from syscolumns a
                    where a.id=object_id(@tablename)
                    and a.colid>@k
                if @@rowcount=0 break
                if @k+1<>@totcols select @m=@m + ','
                select @k=@k+1
                if datalength(@m)>60
                begin
                    print @m
                    select @m='      '
                End
                continue
            End
            print @m
    
            Print '   if @@fetch_status = 0 goto update_check'
            Print '   if @rowsprocessed=0'
            print '      begin'
            Print '        select @errmsg = (Cursor error)'
            Print '        goto error'
            Print '      end'
            Print '    else'
            Print '       goto TRIGGEREXIT'
      
            Print 'end'
            print ''
            Print 'update_check:'
            print '/*---------------*/'
        End
    print ''
    
    print '/* Audit inserts */'
    if @triggertype='u'
    begin
    
    print 'if (select AUDITFIELD from COMPANYTABLE where COMPANYFIELD = @COMPANYFIELD) = ''Y'''
    print 'begin'
    print '  select @key=''KEYDESC: @KEYFIELD'''
    print '/* get old values */'
            select @k=0, @m=null
            while @k<999
            begin
                if @m is null
                select @m='   select '
                select @m=@m+' @old'+a.name + ' = ' + a.name
                    from syscolumns a
                    where a.id=object_id(@tablename)
                    and a.colid>@k
                    order by colid
                if @@rowcount=0 break
                select @m=@m + ','
   
                select @k=@k+1
    
                if datalength(@m)>60
                begin
                    print @m
                    select @m='      '
                End
                continue
            End
            print @m
    print'   from deleted'
    print'   where JOIN WITH PRIMARY KEYS'
            select @k=0, @m=null
            while @k<999
            begin
                select @m = '   if @'+a.name + ' <> @old' + a.name, @t=a.name, @itype=b.type, @dim=b.prec
                 from syscolumns a join systypes b on a.usertype=b.usertype
            	where a.id=object_id(@tablename) and b.name<>'bNotes'
            	and a.colid>@k
            	order by colid
                if @@rowcount=0
                    break
                select @k=@k+1
                print @m
                print '   begin'
                
    
                if @itype in (37,39,47,58,61)  
                  begin
                    select @m= '      exec @errno = bspHQMAInsert @tablename, @key, @JCCo,''C'','''+@t+''','
                    print @m     
                    select @m='           @old'+@t + ',@'+@t+',@date, @user, @errmsg output'
                    print @m
                  end
                else
                  begin
                    select @m='       select @old=convert(varchar('+convert(varchar(4),@dim+2)+'),@old'+@t + '), '
                    select @m=@m+'@new=convert(varchar('+convert(varchar(4),@dim+2)+'),@'+@t + ')'
                    print @m
                    select @m= '      exec @errno = bspHQMAInsert @tablename, @key, @JCCo,''C'','''+@t+''','
                    print @m
                    select @m='           @old,@new,@date,@user,@errmsg output'
                    print @m 
                  end           
        	    print '      if @errno <> 0 goto error'
                print '   end'
    
               /* continue*/
            End
    end
    if @triggertype='i'
    begin
      print 'insert into bHQMA '
      print '   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)'
     -- select @m='   select '''+@tablename+''',''KEYFIELD: ' + inserted.KEYFIELD + ''','
      print @m
      print ' inserted.COMPANY, ''I''' + ','
      select @m= '          null, null, null, getdate(), SUSER_SNAME() from inserted, ' + @tablename
     print @m
      select @m = '   where inserted.COMPANY='+@tablename+'.COMPANY and COMPANYTABLE.AuditFIELD=''Y'''
     print @m
    end 
    if @triggertype='d'
    begin
      print 'insert into bHQMA '
      print '   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)'
     -- select @m='   select '''+@tablename+''',''KEYFIELD: ' + inserted.KEYFIELD + ''','
      print @m
      print '          deleted.COMPANY, ''D'','
    
      select @m= '          null, null, null, getdate(), SUSER_SNAME() from inserted, ' + @tablename
      print @m
      select @m='	where deleted.COMPANY='+@tablename+'.COMPANY and COMPANYTABLE.AuditFIELD=''Y'''
      print @m
    end  
    if @cursorYN in ('Y','y')
    begin
    print 'if @opencursor = 1'
    print '   begin'
    print '     select @rowsprocessed=@rowsprocessed+1'
    print '     goto NEXTROW'
    print '   end'
    print ''
      print 'TRIGGEREXIT:'
      print 'if @opencursor = 1'
      print '  begin'
      select @m= '   close '+@cursor
      print @m
      select @m='   deallocate '+@cursor
      print @m
      print '  end'
    end
    print 'return'
    print ''
    print 'error:'
    if @cursorYN in ('Y','y')
    begin
      print 'if @opencursor = 1'
      print 'begin'
      select @m= '   close '+@cursor
      print @m
      select @m='   deallocate '+@cursor
      print @m
      print 'end'
    end
    select @m = 'select @errmsg = @errmsg + '' - cannot update ' + @tablename +'!'''
    print @m
    print 'RAISERROR(@errmsg, 11, -1);'
    print 'rollback transaction'
                                
    
    
        set rowcount 0
        set nocount off
    
    
    End

GO
GRANT EXECUTE ON  [dbo].[bspTriggerHelper] TO [public]
GO
