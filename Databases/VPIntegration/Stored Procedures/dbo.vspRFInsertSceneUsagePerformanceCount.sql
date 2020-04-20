SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE proc [dbo].[vspRFInsertSceneUsagePerformanceCount]  
     /**********************************************************  
     * Created:  RM 08/07/09
     *     
     * Usage:  
     *   Inserts Scene usage data from the Recording Framework.
     *  
     * Inputs:  
     *   columns for the vRFSceneUsagePerformanceCount table
	 *   
     *
     *  
     ************************************************************/  
       
 (  @SceneID bigint , 
	@CategorySeconds decimal(2) ,
	@CategoryCount int)  
        
 as        
    set nocount on   
  
    insert into vRFSceneUsagePerformanceCounts(SceneID, CategorySeconds, CategoryCount)
						values(@SceneID, @CategorySeconds, @CategoryCount)
	
	--Return the identity of the inserted record							
	select CAST(SCOPE_IDENTITY() AS int)
 

GO
GRANT EXECUTE ON  [dbo].[vspRFInsertSceneUsagePerformanceCount] TO [public]
GO
