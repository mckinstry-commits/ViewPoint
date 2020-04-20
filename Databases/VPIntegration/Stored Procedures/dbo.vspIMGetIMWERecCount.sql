SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMGetIMWERecCount]
   /************************************************************************
   * CREATED:   RT 03/14/2006
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Get count of records in IMWE for given import id and template.
   *    
   *           
   * Notes about Stored Procedure
   * returns 0 for success
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@importid varchar(20), @template varchar(10), @msg varchar(60) output)
   
   as
   set nocount on
   
    declare @rcode int
    select @rcode = 1
   
	select max(RecordSeq) as RecCount from IMWE 
	where ImportId = @importid and ImportTemplate = @template

	select @rcode = 0

   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMGetIMWERecCount] TO [public]
GO
