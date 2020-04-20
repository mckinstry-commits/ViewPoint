SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE proc [dbo].[vspRFInsertCommandUsagePerformanceCount]  
     /**********************************************************  
     * Created:  RM 08/07/09
     *     
     * Usage:  
     *   Inserts Command usage data from the Recording Framework.
     *  
     * Inputs:  
     *   columns for the vRFCommandUsagePerformanceCount table
	 *   
     *
     *  
     ************************************************************/  
       
 (  @CommandID bigint , 
	@CategorySeconds decimal(2) ,
	@CategoryCount int)  
        
 as        
    set nocount on   
  
    insert into vRFCommandUsagePerformanceCounts(CommandID, CategorySeconds, CategoryCount)
						values(@CommandID, @CategorySeconds, @CategoryCount)
	
	--Return the identity of the inserted record							
	select CAST(SCOPE_IDENTITY() AS int)
 

GO
GRANT EXECUTE ON  [dbo].[vspRFInsertCommandUsagePerformanceCount] TO [public]
GO
