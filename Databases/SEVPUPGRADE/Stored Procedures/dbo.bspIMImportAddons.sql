SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspIMImportAddons]
 /************************************************************************
 * CREATED:    DANF 02/13/01
 * MODIFIED:   danf 1/24/05 - issue #119669 (SQL 9.0 2005)
 *			   CC 3/12/2008 - issue #127389 increased @importtbl to varchar(128), increase @updatestatment,@insertstatment,@insertwhere,@setstatement, and @clearstatement to varchar(max)
 *
 * Purpose of Stored Procedure
 *
 *    To Create additional imported records based on Setting in IMTA
 *
 *
 * returns 0 if successfull
 * returns 1 and error msg if failed
 *
 *************************************************************************/
 
         --Parameter list goes here
 (@importid varchar(10), @importtemplate varchar(10), @form varchar(30), @importtbl varchar(128), @msg varchar(80) = '' output)
 
 as
 set nocount on
 
         --Local variable declarations list goes here
 
 declare @complete int, @updatestatment varchar(max), @insertstatment varchar(max), @insertwhere varchar(max),
         @setstatement varchar(max), @rcode int, @lastaddon int, @rowcount int, @Column varchar(60),
         @ColList varchar(500), @clearstatement varchar (max)
 
         --cursor variables
 declare @FromCol int, @ToCol int, @addon int, @AddColumn bYN
 
         --validation of input parameters usually goes here
 select @rcode = 0
 
 if @importid is null
     begin
         select @msg = 'Missing ImportId', @rcode = 1
         goto bspexit
     end
 
 if @importtemplate is null
     begin
         select @msg = 'Missing Import Template'
         goto bspexit
     end
 
 if @form is null
     begin
         select @msg = 'Missing Form Name'
         goto bspexit
     end
 
 select @rowcount=COUNT(*) from bIMTA a
 where a.ImportTemplate = @importtemplate
 if @rowcount = 0 goto bspexita
 
 select @updatestatment = 'alter table ' + @importtbl + ' add KeyColVal NUMERIC(18,0) NULL'
 exec (@updatestatment)
 print @updatestatment
 
 select @updatestatment = 'Update ' + @importtbl + ' Set KeyColVal = KeyCol'
 exec (@updatestatment)
 print @updatestatment
 
 select @updatestatment = 'alter table ' + @importtbl + ' drop column KeyCol'
 exec (@updatestatment)
 print @updatestatment
 
 select @updatestatment = 'alter table ' + @importtbl + ' add AddonCol NUMERIC(18,0) NULL'
 exec (@updatestatment)
 print @updatestatment
 
 select @updatestatment = 'Update ' + @importtbl + ' Set AddonCol = 0'
 exec (@updatestatment)
 print @updatestatment
 
 declare column_curs cursor
 for
 select c.name from syscolumns c
 left join systypes t
 on  c.usertype = t.usertype
 where c.id = object_id(@importtbl) 
 
 open column_curs
 
 fetch next from column_curs into @Column
 
     nxt_column:
     if @@fetch_status = 0
         begin
                if @Column <>'AddonCol' select @ColList = @ColList + @Column + ', '
 
                fetch next from column_curs into @Column
                goto nxt_column
         end
 
 print @ColList
 
 
 declare addon_curs cursor
 for
 select a.RecColumn, d.RecColumn, a.AddonNumber, a.AddColumn from IMTA a
 Join bIMTD d on a.ImportTemplate= d.ImportTemplate and a.RecordType=d.RecordType and a.Identifier=d.Identifier
 where a.ImportTemplate = @importtemplate
 order by a.AddonNumber, d.RecColumn
 
 open addon_curs
 
 fetch next from addon_curs into @FromCol, @ToCol, @addon, @AddColumn
 
 select @complete = 0, @lastaddon = Null, @updatestatment = Null
 
 -- while cursor is not empty
 while @complete = 0
 
 begin
     nxt_rec:
     if @@fetch_status = 0
         begin
             If @lastaddon is not null and @lastaddon<>@addon
                begin
 
                  select @insertstatment = 'Insert into ' + @importtbl + ' (' + @ColList + 'AddonCol) select ' + @ColList + 'Null from ' + @importtbl + ' where ' + @insertwhere + ' and AddonCol = 0'
                  print @insertstatment
                  exec (@insertstatment)
                  print @insertstatment
 
 
                  select @updatestatment = 'Update ' + @importtbl + ' Set ' + @setstatement + ' where AddonCol is null'
                  print @updatestatment
                  exec (@updatestatment)
                  print @updatestatment
 
 
                  if @clearstatement is not null
                    begin
                      select @updatestatment = 'Update ' + @importtbl + ' Set ' + @clearstatement + ' where AddonCol is null'
                    print @updatestatment
                      exec (@updatestatment)
                      print @updatestatment
                    end
 
                  select @updatestatment = 'Update ' + @importtbl + ' Set AddonCol = ' + convert(varchar(3),@lastaddon) +  ' where AddonCol is null'
                  print @updatestatment
                  exec (@updatestatment)
                  print @updatestatment
 
 
                  select @insertwhere = Null, @setstatement = Null, @clearstatement = Null
 
                end
 
                If @AddColumn ='Y'
                   begin
                      if @insertwhere is not null select @insertwhere = @insertwhere + ' and '
                      if @setstatement is not null select @setstatement = @setstatement + ', '
 
                     select @insertwhere = @insertwhere + ' Col' + convert(varchar(4),@FromCol) + ' is not null '
 
                     select @setstatement = @setstatement + ' Col' + convert(varchar(4),@ToCol) + ' = ' + ' Col' + convert(varchar(4),@FromCol)
                   end
                else
                  begin
                    if @clearstatement is not null select @clearstatement = @clearstatement + ', '
                    select @clearstatement = @clearstatement + ' Col' + convert(varchar(4),@ToCol) + ' = ' + ' Null'
                  end
                select @lastaddon = @addon
 
                fetch next from addon_curs into @FromCol, @ToCol, @addon, @AddColumn
                goto nxt_rec
         end
      else
 
         select @insertstatment = 'Insert into ' + @importtbl + ' (' + @ColList + 'AddonCol) select ' + @ColList + 'Null from ' + @importtbl + ' where ' + @insertwhere + ' and AddonCol = 0'
         print @insertstatment
         exec (@insertstatment)
         print @insertstatment
 
         select @updatestatment = 'Update ' + @importtbl + ' Set ' + @setstatement + ' where AddonCol is null'
         print @updatestatment
         exec (@updatestatment)
         print @updatestatment
 
         if @clearstatement is not null
            begin
              select @updatestatment = 'Update ' + @importtbl + ' Set ' + @clearstatement + ' where AddonCol is null'
              print @updatestatment
              exec (@updatestatment)
              print @updatestatment
            end
 
         select @updatestatment = 'Update ' + @importtbl + ' Set AddonCol = ' + convert(varchar(3),@lastaddon) +  ' where AddonCol is null'
         print @updatestatment
         exec (@updatestatment)
         print @updatestatment
 
         select @complete = 1
 end
 
 
 select @updatestatment = 'if exists (select * from sysobjects where id = object_id(N'''+ @importtbl +'i'') and OBJECTPROPERTY(id, N''IsTable'') = 1) Drop TABLE ' + @importtbl + 'i'
 print @updatestatment
 exec (@updatestatment)
 select @msg = @updatestatment
 
 select @updatestatment = 'Select * INTO ' + @importtbl + 'i FROM ' + @importtbl + ' Order By KeyColVal, AddonCol'
 exec (@updatestatment)
 print @updatestatment
 select @msg = @updatestatment
 
 select @updatestatment = 'Drop TABLE ' + @importtbl
 exec (@updatestatment)
 print @updatestatment
 select @msg = @updatestatment
 
 select @updatestatment = 'Select * INTO ' + @importtbl + ' FROM ' + @importtbl + 'i Order By KeyColVal, AddonCol'
 exec (@updatestatment)
 print @updatestatment
 select @msg = @updatestatment
 
 select @updatestatment = 'alter table ' + @importtbl + ' add KeyCol NUMERIC(18,0) NOT NULL IDENTITY'
 exec (@updatestatment)
 print @updatestatment
 
 
 bspexit:
 
     --poss error and clean up code, such as closing a cursor, goes here
 
 close addon_curs
 deallocate addon_curs
 
 close column_curs
 deallocate column_curs
 
 bspexita:
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMImportAddons] TO [public]
GO
