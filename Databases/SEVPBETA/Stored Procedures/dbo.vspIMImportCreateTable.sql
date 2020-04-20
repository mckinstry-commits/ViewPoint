SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMImportCreateTable]
   /************************************************************************
   * CREATED:   DANF 01/04/2007
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *   drop import temp table.
   *    
   *           
   * Notes about Stored Procedure
   * 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@TempString varchar(max), @msg varchar(255) output)
   
   as
   set nocount on
   
    declare @rcode int, @AlterString NVARCHAR(max)
   
    select @rcode=0

    If @TempString is null
       begin
       select @msg='Missing Temp String.', @rcode=1
       goto bspexit
       end

	Set @AlterString = @TempString
   
	EXEC sp_executesql @AlterString
   
   bspexit:
        if @rcode<>0 select @msg=isnull(@msg,'') + char(13) + char(10) + '[vspIMImportCreateTable]'
        return @rcode

/*
create table clients (i int)
insert into clients values (10)
insert into clients values (13)
go

declare @tn sysname
set @tn = 'clients'
declare @TotalRecords int
declare @sql nvarchar(600)
set @sql = N'
     select @TotalRecords = count(*) from '+ quotename(@tn)
   + ' where i > @param'
exec sp_executesql
  @sql,
  N'@param int, @TotalRecords int OUTPUT',
  @TotalRecords = @TotalRecords OUTPUT,
  @param = 11

select @TotalRecords
go
*/

GO
GRANT EXECUTE ON  [dbo].[vspIMImportCreateTable] TO [public]
GO
