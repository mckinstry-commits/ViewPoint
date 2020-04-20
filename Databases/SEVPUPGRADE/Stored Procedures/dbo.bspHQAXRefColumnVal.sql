SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[bspHQAXRefColumnVal] 
   /******************************************************************
   	Created: 09/21/01 - RM
   
   	Modified:
   
   
   	Usage: Validate Master Column Name
   
   
   
   ******************************************************************/
   (@column varchar(20),@msg varchar(255) output)
   
   
   AS
   
   declare @rcode int
   
   select @rcode = 0
   
   
   select @msg = Description
   from HQAX
   where ParentColumn = @column
   
   if @@rowcount = 0
     	begin
   	    select @msg = 'Not a valid Master Column', @rcode = 1
   	   goto bspexit
   	end
   
   
   
   bspexit:
   
   	
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQAXRefColumnVal] TO [public]
GO
