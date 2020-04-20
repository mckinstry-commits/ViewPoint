SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMUpdateStatsIMWE]
   /************************************************************************
   * CREATED: DANF
   * MODIFIED: 
   *
   * Purpose of Stored Procedure
   *
   * Update Stats 
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successful
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   UPDATE STATISTICS bIMWE
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMUpdateStatsIMWE] TO [public]
GO
