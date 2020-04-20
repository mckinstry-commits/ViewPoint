SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[vspDDMOActiveMod]
  /************************************************************************
  * CREATED:    MH 9/29/00
  * MODIFIED:   EN 6/10/05 handle change in DDMO Active field for 6x ... it changed from int to bYN
  *
  * Purpose of Stored Procedure
  *
  *    Determine if a module is active ... used by vspPRDedLiabCodeVal 
  *    
  *           
  * returns 0 if successfull 
  * returns 1 and error msg if failed
  *
  *************************************************************************/
  
      (@module varchar(2), @active bYN output, @msg varchar(80) = '' output)
  
  as
  set nocount on
  
      declare @rcode int
  
      select @rcode = 0
  
      exec @rcode = bspDDMOVal @module, @msg output
  
      if @rcode = 0
          select @active = Active from DDMO where Mod = @module
  
  bspexit:
  
       return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspDDMOActiveMod] TO [public]
GO
