SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspDBCols]

(@table varchar(100)='%', @useronly varchar(1)='Y', @Summary varchar(1)='Y', @ColName varchar(100)='%')
as
set nocount on

declare @objid     int,
        @rowcnt    int,
        @output    varchar(255),
        @length    int,
        @varlength int,
        @tables    int,
        @columns   int,
        @pagelen   int

 select @output    = '',
        @rowcnt    = 0,
        @objid     = object_id(@table),
        @length    = 0,
        @varlength = 0,
        @tables    = 0,
        @columns   = 0,
        @pagelen   = (1024 * 8) - 96


-- CHECK IF TABLE EXISTS
select @rowcnt = count(*) 
  from sysobjects 
 where name like @table
IF (@rowcnt <1)
BEGIN
  set @output = 'The table ''' + @table + ''' could not be found in the current database.'
  print @output
END
ELSE
BEGIN
  -- USERONLY = Y
  IF (upper(@useronly) = 'Y')
  BEGIN
    select 'TableName'  = convert(varchar(55),SO.name),
           'ColumnName' = convert(varchar(55),SC.name),
           'Type'       = convert(varchar(16),type_name(xusertype)),
           'Bytes'      = length,
           'Nulls'      = case when isnullable = 0 then 'N' else 'Y' end
      from syscolumns SC
      join sysobjects SO on  SC.id     = SO.id 
                         and SO.name   like @table
                         and SC.name   like @ColName
                         and SO.name   not like 'conflict_%'
                         and SO.name   not like 'MSReplication_%'
                         and SO.name   not like 'MSSubscription%'
                         and SO.name   not like 'sys%'
                         and SC.number = 0
                         and SO.xtype  in ('U','V')
     order by SO.name, SC.colid

     select @columns = count(*)
       from syscolumns SC
       join sysobjects SO on  SC.id     = SO.id 
                         and SO.name   like @table
                         and SC.name   like @ColName
                         and SO.name   not like 'conflict_%'
                         and SO.name   not like 'MSReplication_%'
                         and SO.name   not like 'MSSubscription%'
                         and SO.name   not like 'sys%'
                         and SC.number = 0
                         and SO.xtype  = 'U'


    select @length = sum(length)
      from syscolumns SC
      join sysobjects SO on  SC.id     = SO.id 
                         and SO.name   like @table
                         and SC.name   like @ColName
                         and SO.name   not like 'conflict_%'
                         and SO.name   not like 'MSReplication_%'
                         and SO.name   not like 'MSSubscription%'
                         and SO.name   not like 'sys%'
                         and SC.number = 0
                         and convert(varchar(16),type_name(SC.xusertype)) not in ('text','image')
                         and SO.xtype  = 'U'

    select @varlength = isnull(sum(length),0)
      from syscolumns SC
      join sysobjects SO on  SC.id     = SO.id 
                         and SO.name   like @table
                         and SC.name   like @ColName
                         and SO.name   not like 'conflict_%'
                         and SO.name   not like 'MSReplication_%'
                         and SO.name   not like 'MSSubscription%'
                         and SO.name   not like 'sys%'
                         and SC.number = 0
                         and convert(varchar(16),type_name(SC.xusertype)) not in ('text','image')
                         and SO.xtype  in ('U','V')
                         and type_name(SC.xusertype) in ('varchar','char','nvarchar','nchar')
                      
    select @tables = count(*) 
      from sysobjects 
     where name like @table
       and name not like 'conflict_%'
       and name not like 'MSReplication_%'
       and name not like 'MSSubscription%'
       and name not like 'sys%'
       and xtype = 'U'


  END
  ELSE
  BEGIN
    -- ALL TABLE TYPES
    select 'TableName'  = convert(varchar(55),SO.name),
           'ColumnName' = convert(varchar(55),SC.name),
           'Type'       = convert(varchar(16),type_name(xusertype)),
           'Bytes'      = length,
           'Nulls'      = case when isnullable = 0 then 'N' else 'Y' end
      from syscolumns SC
      join sysobjects SO on  SC.id     = SO.id 
                         and SO.name   like @table
                         and SC.name   like @ColName
                         and SO.xtype  in ('U','V')
                         and SC.number = 0
     order by SO.name, SC.colid

     select @columns = COUNT(*)
      from syscolumns SC
      join sysobjects SO on  SC.id     = SO.id 
                         and SO.name   like @table
                         and SC.name   like @ColName
                         and SO.xtype  = 'U'
                         and SC.number = 0


    select @length = sum(length)
      from syscolumns SC
      join sysobjects SO on  SC.id     = SO.id 
                         and SO.name   like @table
                         and SC.name   like @ColName
                         and SC.number = 0
                         and convert(varchar(16),type_name(SC.xusertype)) not in ('text','image')
                         and SO.xtype = 'U'

    select @varlength = isnull(sum(length),0)
      from syscolumns SC
      join sysobjects SO on  SC.id     = SO.id 
                         and SO.name   like @table
                         and SC.name   like @ColName
                         and SO.name   not like 'conflict_%'
                         and SO.name   not like 'MSReplication_%'
                         and SO.name   not like 'MSSubscription%'
                         and SO.name   not like 'sys%'
                         and SC.number = 0
                         and convert(varchar(16),type_name(SC.xusertype)) not in ('text','image')
                         and SO.xtype  = 'U'
                         and type_name(SC.xusertype) in ('varchar','char','nvarchar','nchar')

  select @tables = count(*) 
    from sysobjects 
   where name like @table
     and xtype  = 'U'

  END  

   IF (@ColName = '%') --> Don't print summary if looking for specific columns
   BEGIN
     IF (@Summary = 'Y')
     BEGIN
       IF (@tables = 1)
       BEGIN
         print 'Total Length:  ' + convert(char(8),@length)
         print 'Var Length:    ' + convert(char(8),@varlength)
         print 'Min Recs/Page: ' + convert(char(8),@pagelen / @length)
         print 'Max Recs/Page: ' + convert(char(8),@pagelen / (@length - @varlength))

       END
       ELSE
       BEGIN
         print 'Tables:       ' + convert(char(8),@tables)
         print 'Columns:      ' + convert(char(8),@columns)
         print 'Cols/Table:   ' + convert(char(8),(@columns / @tables))
         print 'Total Length: ' + convert(char(8),@length)
         print 'Var Length:   ' + convert(char(8),@varlength)
       END
     END
   END
END

GO
GRANT EXECUTE ON  [dbo].[vspDBCols] TO [public]
GO
