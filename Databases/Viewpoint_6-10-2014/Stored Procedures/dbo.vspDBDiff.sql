SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspDBDiff]
-----------------------------------------------------------------------------------------
--               
-- Description:  This script is used to find the table/column differences between 
--               two databases.  This is especially useful when trying to determine
--               the structural differences between a production and development databse.
--               
-- Usage:        exec sp_DBDiff 'OldDatabase','NewDatabase'
--               
-- Special Note: Before running this script, make sure you have the latest copy of              
--               vspDBCols stored procedure in the master database.
--               
-----------------------------------------------------------------------------------------
-- Date Revised: 
-- Author:       
-- Reason:       
-----------------------------------------------------------------------------------------
(@OldDB sysname, @NewDB sysname)
as
set nocount on

declare @sql   varchar(1000)

select  @sql   = ''

-- OLD DATABASE TABLES
IF (object_id('tempdb.dbo.#OLD')) is not null
  DROP TABLE #OLD
CREATE TABLE #OLD
(TableName varchar(55), ColumnName varchar(55), Type varchar(16), Bytes smallint, Nulls char(3))

-- NEW DATABASE TABLES
IF (object_id('tempdb.dbo.#NEW')) is not null
  DROP TABLE #NEW
CREATE TABLE #NEW
(TableName varchar(55), ColumnName varchar(55), Type varchar(16), Bytes smallint, Nulls char(3))

-- NEW TABLES
IF (object_id('tempdb.dbo.#NewTables')) is not null
  DROP TABLE #NewTables
CREATE TABLE #NewTables
(TableName varchar(55))

-- DROPPED TABLES
IF (object_id('tempdb.dbo.#DroppedTables')) is not null
  DROP TABLE #DroppedTables
CREATE TABLE #DroppedTables
(TableName varchar(55))

-- NEW COLUMNS
IF (object_id('tempdb.dbo.#NewColumns')) is not null
  DROP TABLE #NewColumns
CREATE TABLE #NewColumns
(TableName varchar(55), ColumnName varchar(55), Type varchar(16), Bytes smallint)

-- DROPPED COLUMNS
IF (object_id('tempdb.dbo.#DroppedColumns')) is not null
  DROP TABLE #DroppedColumns
CREATE TABLE #DroppedColumns
(TableName varchar(55), ColumnName varchar(55), Type varchar(16), Bytes smallint)

-- CHANGED COLUMNS
IF (object_id('tempdb.dbo.#ChangedColumns')) is not null
  DROP TABLE #ChangedColumns
CREATE TABLE #ChangedColumns
(TableName varchar(55), ColumnName varchar(55), OldType varchar(16), OldBytes smallint, NewType varchar(16), NewBytes smallint)


-- INFORMATION_SCHEMA.Columns and COL_LENGTH exhibit strange behavior when you are in one database, peeking into another
-- Because of this, I am referring to an old proc I wrote, called vspDBCols.  Make sure it exists in your master database.

-- GET OLD TABLES AND COLUMNS
select @sql = '[' + @OldDB + '].dbo.vspDBCols @Summary = ''N'', @useronly = ''N'''
--select @SQL = 'select Table_Name, Column_Name, Data_Type , COL_LENGTH(Table_Name, Column_Name), Is_Nullable from ' + @OldDB + '.INFORMATION_SCHEMA.COLUMNS '
--print @sql
insert into #OLD
execute(@sql)

-- GET NEW TABLES AND COLUMNS
select @sql = '[' + @NewDB + '].dbo.vspDBCols @Summary = ''N'', @useronly = ''N'''
--select @SQL = 'select Table_Name, Column_Name, Data_Type , COL_LENGTH(Table_Name, Column_Name), Is_Nullable from ' + @NewDB + '.INFORMATION_SCHEMA.COLUMNS '
--print @sql
insert into #NEW
execute (@sql)

-- New Tables
insert into #NewTables
select distinct 
       'NewTables' = N.TableName
  from #NEW N
  left join  #OLD O  on O.TableName  = N.TableName
 where O.TableName IS NULL
order by 1

-- Dropped Tables
insert into #DroppedTables
select distinct 
       'DroppedTables' = O.TableName
  from #OLD O
  left join  #NEW N  on N.TableName  = O.TableName
 where N.TableName IS NULL
order by 1

-- New Columns
insert into #NewColumns
select  N.TableName,
       'NewColumn' = N.ColumnName,
       'Type'      = N.Type,
       'Bytes'     = N.Bytes
  from #NEW N
  left join  #OLD O  on O.TableName  = N.TableName
                    and O.ColumnName = N.ColumnName
 where O.TableName IS NULL
   and N.TableName NOT IN (select TableName from #NewTables)
order by 1,2

-- Dropped Columns
insert into #DroppedColumns
select  O.TableName,
       'DroppedColumn' = O.ColumnName,
       'Type'          = O.Type,
       'Bytes'         = O.Bytes
  from #OLD  O
  left join  #NEW N  on N.TableName  = O.TableName
                    and N.ColumnName = O.ColumnName
 where N.TableName IS NULL
   and O.TableName NOT IN (select TableName from #DroppedTables)
order by 1,2


-- Changed Columns
insert into #ChangedColumns
select  O.TableName,
        O.ColumnName,
        'OldType'  = O.Type,
        'OldBytes' = O.Bytes,
        'NewType'  = N.Type,
        'NewBytes' = N.Bytes
   from #OLD  O
   join #NEW N  on N.TableName  = O.TableName
               and N.ColumnName = O.ColumnName
 where (N.Type  <> O.Type)
    or (N.Bytes <> O.Bytes)


print 'OLD Database: ' + @OldDB
print 'NEW Database: ' + @NewDB
print ' '
print '=============='
print '= NEW TABLES ='
print '=============='
print ' '
select * from #NewTables      order by 1

print ' '
print '=================='
print '= DROPPED TABLES ='
print '=================='
print ' '
select * from #DroppedTables  order by 1

print ' '
print '=================================='
print '= NEW COLUMNS IN EXISTING TABLES ='
print '=================================='
print ' '
select * from #NewColumns     order by 1,2

print ' '
print '========================================'
print '= COLUMNS REMOVED FROM EXISTING TABLES ='
print '========================================'
print ' '
select * from #DroppedColumns order by 1,2

print ' '
print '=================================='
print '= COLUMNS TYPE OR LENGTH CHANGED ='
print '=================================='
print ' '
select * from #ChangedColumns order by 1,2

GO
GRANT EXECUTE ON  [dbo].[vspDBDiff] TO [public]
GO
