SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMGetXMLRowTag]
   /************************************************************************
   * CREATED:   RT 03/14/2006
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Get XML Row Tag identifier from IMTH.
   *    
   *           
   * Notes about Stored Procedure
   * returns 0 for success
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@template varchar(10), @xmlrowtag varchar(30) output, @msg varchar(60) output)
   
   as
   set nocount on
   
    declare @rcode int
    select @rcode = 1
   
	select @xmlrowtag = XMLRowTag
	from IMTH with (nolock) where ImportTemplate = @template

	select @rcode = 0

   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMGetXMLRowTag] TO [public]
GO
