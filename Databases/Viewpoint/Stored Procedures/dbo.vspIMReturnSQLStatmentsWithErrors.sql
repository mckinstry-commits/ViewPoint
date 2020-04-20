SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspIMReturnSQLStatmentsWithErrors]
   /************************************************************************
   * CREATED:   DANF 12/19/06
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Return sql statements that failed in the upload process and sql was not able to capture the error.
   *    
   *
   *************************************************************************/
   
   (@importid varchar(20), @msg varchar(60) output)
   
   as
   set nocount on
	declare @rcode int
	select @rcode = 0
   
   Select RecordSeq, SQLStatement from IMWM where ImportId = @importid and Error = 9999

   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMReturnSQLStatmentsWithErrors] TO [public]
GO
