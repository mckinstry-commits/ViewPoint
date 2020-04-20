SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspDefaultGLAcct]
   /* Finds Default Gl Account
    * pass in IN Location 
    * returns GL Account number
    *
    *Created by TV 03/09/01
   */
   	(@loc bLoc, @glacct bGLAcct output, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   
   if not exists (select * from APLB where Loc = @loc)
   	begin
   	select @msg = 'No Default GL Account for Location ' + @loc, @rcode = 1
   	goto bspexit
   	end 
   
   select @glacct = (select distinct GLAcct from APLB where Loc = @loc)
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspDefaultGLAcct] TO [public]
GO
