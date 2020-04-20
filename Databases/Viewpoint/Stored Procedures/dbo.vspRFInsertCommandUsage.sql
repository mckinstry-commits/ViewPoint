SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE proc [dbo].[vspRFInsertCommandUsage]  
     /**********************************************************  
     * Created:  RM 08/07/09
     *     
     * Usage:  
     *   Inserts Command usage data from the Recording Framework.
     *  
     * Inputs:  
     *   columns for the vRFCommandUsage table
	 *   
     *
     *  
     ************************************************************/  
       
 (  @SceneID bigint ,
	@CommandName varchar(256) ,
	@AllExecutionsSeconds decimal(2) ,
	@MaximumExecutionSeconds decimal(2) )  
        
 as        
    set nocount on   
  
	insert into vRFCommandUsage(SceneID, CommandName, AllExecutionsSeconds, MaximumExecutionSeconds)
	                     values(@SceneID, @CommandName, @AllExecutionsSeconds, @MaximumExecutionSeconds)

	--Return the identity of the inserted record								
	select CAST(SCOPE_IDENTITY() AS int)
 

GO
GRANT EXECUTE ON  [dbo].[vspRFInsertCommandUsage] TO [public]
GO
