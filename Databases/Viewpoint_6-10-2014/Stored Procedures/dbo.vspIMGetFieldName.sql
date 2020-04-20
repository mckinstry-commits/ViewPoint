SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMGetFieldName]
   /************************************************************************
   * CREATED:   RT 03/08/2006
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Returns column name for given identifier, table, and template.
   *    
   *           
   * Notes about Stored Procedure
   * 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@identifier int, @tablename varchar(30), @template varchar(10), @msg varchar(60) output)
   
   as
   set nocount on
   
    declare @rcode int
    select @rcode = 1
   
	SELECT a.ColumnName, a.Description FROM DDUD a JOIN IMTH b on a.Form = b.Form
    WHERE a.TableName = @tablename and a.Identifier = @identifier and b.ImportTemplate = @template

   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMGetFieldName] TO [public]
GO
