SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspDDMOActiveMod]
   /************************************************************************
   * CREATED:    MH 9/29/00
   * MODIFIED:   
   *
   * Purpose of Stored Procedure
   *
   *    Determine if a module is active    
   *    
   *           
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@module varchar(2), @active int output, @msg varchar(80) = '' output)
   
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
GRANT EXECUTE ON  [dbo].[bspDDMOActiveMod] TO [public]
GO
