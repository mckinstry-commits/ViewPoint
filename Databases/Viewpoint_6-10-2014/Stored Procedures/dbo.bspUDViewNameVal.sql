SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspUDViewNameVal]
   /*******************************************
   	Created: 10/30/01 RM
   	
   
   	Checks for valid table.
   
   ******************************************/
   (@tablename varchar(50),@msg varchar(255) output)
   AS
   
   declare @rcode int
   select @rcode = 0
   
   if not exists(select * from sysobjects where name = @tablename and xtype='V')
   begin
   	select @msg = 'Table does not exist.',@rcode = 1
   	goto bspexit
   end
   
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspUDViewNameVal] TO [public]
GO
