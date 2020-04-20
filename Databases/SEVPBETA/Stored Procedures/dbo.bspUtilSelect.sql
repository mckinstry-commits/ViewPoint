SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspUtilSelect] (@tablename1 varchar(30), @tablename2 varchar(30), @tablename3 varchar(30))
   as
   /* author JE 3/16/02 */
   /* pass in upto three table names and this procedure will generate the select statements with */
   /* computes for numeric values with a datatype od bHrs, bUnits, or bDollar */
   declare @tname varchar(30), @iname varchar(60), @cname varchar(60) , @t1 varchar(256), @t2 varchar(256)
   declare @prec int, @length int, @xusertype int, @t varchar(256), @compute varchar(256),@compute2 varchar(256),
    @tablename varchar(60), @jointable varchar(60),  @count tinyint, @selectflag tinyint
   
   select @tablename1=isnull(@tablename1,''),@tablename2=isnull(@tablename2,''),@tablename3=isnull(@tablename3,'')
   select @t='', @compute='', @compute2='', @selectflag=0
   select @count=1
   while @count<=3 
   begin
   if @count=1 select @tablename=@tablename1
   if @count=2 select @tablename=@tablename2
   if @count=3 select @tablename=@tablename3
   if @tablename='' goto nexttable 
   declare ccols cursor for 
   select c.name, t.name from syscolumns c
   join systypes t on c.xusertype=t.xusertype
    where object_name(c.id) =@tablename 
      and t.name like 'b%' 
      order by colid
   
   open ccols
   colloop:
   fetch next from ccols into @cname,@iname
   if @@fetch_status <> 0 goto cloopend
   if (select @selectflag)=0 select @t='select ' else select @t=@t + ', '
   select @selectflag=1
   if datalength(@t)>120 
   begin
   print @t
   select @t='    '
   end
   select @t=@t + rtrim(@tablename)+'.'+@cname
   if (@iname in ('bDollar','bHrs','bUnits'))
   begin
   if datalength(@compute)<120
   begin
   if @compute='' select @compute='compute ' else select @compute=@compute+', '
   select @compute=@compute+'sum('+rtrim(@tablename)+'.'+rtrim(@cname)+')'
   end
   else
   begin
   select @compute2=@compute2+', sum('+rtrim(@tablename)+'.'+rtrim(@cname)+')'
   end
   end
           goto colloop
   cloopend:
       Close ccols
       deallocate ccols
   nexttable:
   print @t
   select @t='    '
   
   select @count=@count+1
   end
   
   
   select @t=''
   select @t2=''
   
   select @count=1
   while @count<=2 
   begin
   select @selectflag=0
   if @count=1 select @tablename=@tablename1, @jointable=@tablename2
   if @count=2 select @tablename=@tablename2, @jointable=@tablename3
   if @count=3 select @tablename=@tablename3, @jointable=''
   if @count=1 print 'from '+@tablename
   if @jointable='' goto nextctable 
   select @t='join '+rtrim(@jointable) + ' on' 
   
       declare cindex cursor for
       select substring(object_name(k.id),1,30),substring(c.name,1,60),c.xprec,c.length,t.xusertype
           from sysindexkeys k
           join sysindexes  i on k.id=i.id and k.indid=i.indid
           join syscolumns c on c.id=k.id and c.colid=k.colid
           join systypes t on c.xusertype=t.xusertype
       where object_name(k.id) =@tablename and i.name like 'bi%' and i.indid=1
       open cindex
   Loop:
           fetch next from cindex into @tname,@cname,@prec,@length,@xusertype
           if @@fetch_status <> 0 goto cend
   
   	--select @tname, @iname, @cname, @prec, @length, @xusertype
   	select top 1 @iname= name from syscolumns where object_name(id)=@jointable and xusertype=@xusertype and length=@length
           if datalength(@t)>120
   	begin
   	   print @t
   	   select @t='   '
           end
           if @selectflag=1 select @t=@t + ' and'
   	select @selectflag=1
           select @t=@t + ' ' + rtrim(@tablename)+'.'+@cname+' = '+@jointable+'.'+rtrim(@iname) 
           goto Loop
   cend:
       Close cindex
       deallocate cindex
   
   nextctable:
   print @t
   select @t='    '
   
   select @count=@count+1
   end
   
   print @compute
   print @compute2

GO
GRANT EXECUTE ON  [dbo].[bspUtilSelect] TO [public]
GO
