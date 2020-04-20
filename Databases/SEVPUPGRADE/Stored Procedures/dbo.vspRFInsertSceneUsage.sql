SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE proc [dbo].[vspRFInsertSceneUsage]  
     /**********************************************************  
     * Created:  RM 08/07/09
     *     
     * Usage:  
     *   Inserts Scene usage data from the Recording Framework.
     *  
     * Inputs:  
     *   columns for the vRFSceneUsage table
	 *   
     *
     *  
     ************************************************************/  
       
 (  @EpisodeID bigint , 
	@Module varchar(2) ,
	@SceneName varchar(256) ,
	@ActivationCount int ,
	@ShownSeconds decimal(2) ,
	@ActiveSeconds decimal(2) ,
	@IdleSeconds decimal(2),
	@MaxStartupSeconds decimal(2),
	@AllStartupSeconds decimal(2) )  
        
 as        
    set nocount on   
  
    insert into vRFSceneUsage(EpisodeID, Module, SceneName, ActivationCount, ShownSeconds,
							  ActiveSeconds, IdleSeconds, MaxStartupSeconds, AllStartupSeconds)
						values(@EpisodeID, @Module, @SceneName, @ActivationCount, @ShownSeconds,
							   @ActiveSeconds, @IdleSeconds, @MaxStartupSeconds, @AllStartupSeconds)
	
	--Return the identity of the inserted record							
	select CAST(SCOPE_IDENTITY() AS int)
 

GO
GRANT EXECUTE ON  [dbo].[vspRFInsertSceneUsage] TO [public]
GO
