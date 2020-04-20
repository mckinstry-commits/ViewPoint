SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspUDColumnNameVal]
   /*******************************************
   	Created: 10/30/01 RM
   	
   
   	Checks for valid table.
   
   ******************************************/
   (@tablename varchar(50),@columnname varchar(50),@msg varchar(255) output)
   AS
   
   declare @rcode int
   select @rcode = 0
   
   if not exists(select * from syscolumns where name = @columnname and id=object_id(@tablename))
   begin
   	select @msg = 'Column does not exist for this table.',@rcode = 1
   	goto bspexit
   end
   
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspUDColumnNameVal] TO [public]
GO
