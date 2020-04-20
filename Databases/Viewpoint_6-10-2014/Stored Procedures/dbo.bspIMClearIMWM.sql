SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMClearIMWM]
   /************************************************************************
   * CREATED:  RBT 08/12/03 - Created for issue #22133   
   * MODIFIED: 
   *
   * Purpose of Stored Procedure
   *
   *  Delete all IMWM records for the given ImportId.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successful
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@importid varchar(20) = null, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
       if @importid is null
           begin
               select @msg = 'Missing ImportId', @rcode = 1
               goto bspexit    
           end
   
   	delete IMWM where ImportId = @importid
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMClearIMWM] TO [public]
GO
