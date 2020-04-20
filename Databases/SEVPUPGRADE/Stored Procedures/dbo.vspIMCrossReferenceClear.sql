SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMCrossReferenceClear]
   /************************************************************************
   * CREATED:   DANF 05/11/2006
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *   Delete records from IMDX ( Cross Reference Detail )
   *    
   *           
   * Notes about Stored Procedure
   * returns 0 for success
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@crossreference varchar(30), @template varchar(30), @msg varchar(60) output)
   
   as
   set nocount on
   
    declare @rcode int
    select @rcode = 1
   
	Delete IMXD 
	where XRefName = @crossreference  and ImportTemplate = @template

	select @rcode = 0

   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMCrossReferenceClear] TO [public]
GO
