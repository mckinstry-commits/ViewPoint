SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMImportAlter]
   /************************************************************************
   * CREATED:   DANF 01/04/2007
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Alter import table to add key column
   *    
   *           
   * Notes about Stored Procedure
   * 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@importtable varchar(255), @msg varchar(255) output)
   
   as
   set nocount on
   
    declare @rcode int, @AlterString NVARCHAR(500)
   
    select @rcode=0

    If @importtable is null
       begin
       select @msg='Missing Import Template.', @rcode=1
       goto bspexit
       end

	Set @AlterString = 'ALTER TABLE [' + @importtable + '] ADD KeyCol NUMERIC(18,0) NOT NULL IDENTITY'
   
	EXEC sp_executesql @AlterString
   
   bspexit:
        if @rcode<>0 select @msg=isnull(@msg,'') + char(13) + char(10) + '[vspIMImportAlter]'
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMImportAlter] TO [public]
GO
