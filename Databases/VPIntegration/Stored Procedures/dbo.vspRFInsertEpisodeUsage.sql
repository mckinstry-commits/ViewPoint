SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE proc [dbo].[vspRFInsertEpisodeUsage]  
     /**********************************************************  
     * Created:  RM 08/07/09
     *     
     * Usage:  
     *   Inserts episode usage data from the Recording Framework.
     *  
     * Inputs:  
     *   columns for the vRFEpisodeUsage table
	 *   
     *
     *  
     ************************************************************/  
       
 (  @Application varchar(256) ,
	@ApplicationVersion varchar(256) ,
	@FrameworkVersion varchar(256) ,
	@OSCaption varchar(256) ,
	@OSVersion varchar(256) ,
	@ProcessorName varchar(256) ,
	@ProcessorID varchar(256) ,
	@ProcessorCount tinyint ,
	@Organization varchar(256) , --May go away, not sure how we will determine this
	@StartDateTime datetime ,
	@EndDateTime datetime)  
        
 as        
    set nocount on   
  
	insert into vRFEpisodeUsage(Application, ApplicationVersion, FrameworkVersion, OSCaption, OSVersion,
								ProcessorName, ProcessorID, ProcessorCount, Organization, StartDateTime,
								EndDateTime)
						values(@Application, @ApplicationVersion, @FrameworkVersion, @OSCaption, @OSVersion,
								@ProcessorName, @ProcessorID, @ProcessorCount, @Organization, @StartDateTime,
								@EndDateTime)
								
	--Return the identity of the inserted record								
	select CAST(SCOPE_IDENTITY() AS int)
 

GO
GRANT EXECUTE ON  [dbo].[vspRFInsertEpisodeUsage] TO [public]
GO
