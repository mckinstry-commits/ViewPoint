SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMImportProcessXML]
   /************************************************************************
   * CREATED:   DANF 01/04/2007
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *   copy data for import xml data .
   *    
   *           
   * Notes about Stored Procedure
   * 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@ImportTbl varchar(255), @ColumnNames varchar(max), @Values varchar(max), @msg varchar(255) output)
   
   as
   set nocount on
   
    declare @rcode int, @AlterString NVARCHAR(max)
   
    select @rcode=0

    If @ImportTbl is null
       begin
       select @msg='Missing Import Table.', @rcode=1
       goto bspexit
       end

    If @Values is null
       begin
       select @msg='Missing Values.', @rcode=1
       goto bspexit
       end

    If @ColumnNames is null
       begin
       select @msg='Missing Column Names.', @rcode=1
       goto bspexit
       end

	Set @AlterString = 'INSERT INTO [' + @ImportTbl + '](' + @ColumnNames + ') values(' + @Values + ')'
   
	EXEC sp_executesql @AlterString
   
   bspexit:
        if @rcode<>0 select @msg=isnull(@msg,'') + char(13) + char(10) + '[vspIMImportCreateTable]'
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMImportProcessXML] TO [public]
GO
