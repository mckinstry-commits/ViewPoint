SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMGetRecordTypes]
   /************************************************************************
   * CREATED:   RT 03/14/2006
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Returns Record Types for given Template.
   *    
   *           
   * Notes about Stored Procedure
   * returns 0 for success
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@template varchar(10), @msg varchar(60) output)
   
   as
   set nocount on
   
    declare @rcode int
    select @rcode = 1
   
	SELECT d.DestTable, i.Form, i.RecordType, i.Skip 
	from IMTR i with (nolock) join DDUF d with (nolock) on i.Form=d.Form
    where i.ImportTemplate = @template order by d.BatchYN desc

	select @rcode = 0

   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMGetRecordTypes] TO [public]
GO
