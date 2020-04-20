SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspAPHoldRelPhaseList]
  /************************************************************************
  * CREATED: 	MV 06/02/05   
  * MODIFIED:    
  *
  * Purpose of Stored Procedure:	To return a list of phases and descriptions
  *									to fill the Phase ListBox in APHoldRel
  *    
  * 
  *
  * returns 0 if successfull 
  * returns 1 and error msg if failed
  *
  *************************************************************************/
          
      (@jcco int, @job bJob, @phasegrp bGroup)
  
  as
  set nocount on
  
    declare @rcode int
  
    select @rcode = 0
  
  	Select Phase, Description from JCJP Where JCCo=@jcco and
				 Job=@job and PhaseGroup=@phasegrp
  	if @@rowcount = 0
		begin
		select @rcode=1
		end

  bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPHoldRelPhaseList] TO [public]
GO
