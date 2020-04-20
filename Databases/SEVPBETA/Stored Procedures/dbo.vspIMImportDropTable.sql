SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMImportDropTable]
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
   
   (@TableName varchar(255), @msg varchar(255) output)
   
   as
   set nocount on
   
    declare @rcode int, @AlterString NVARCHAR(500)
   
    select @rcode=0

    If @TableName is null
       begin
       select @msg='Missing Import Table.', @rcode=1
       goto bspexit
       end

---- check to see if table really exists in temp database
if exists(select * from tempdb.sys.tables where name = @TableName)
	begin
	set @AlterString = 'Drop Table ' + quotename(@TableName)  
	EXEC sp_executesql @AlterString
	end




bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode



----select * from sys.tables where name like 'PM%'

GO
GRANT EXECUTE ON  [dbo].[vspIMImportDropTable] TO [public]
GO
