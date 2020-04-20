SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVAUDGetValProcs]
   /*******************************************
   	Created: 07/11/2007 JRK
   	
   
   	Selects a list of validation stored proc names and their descriptions.
   
   ******************************************/
   (@msg varchar(255) output)
   AS
   
   declare @rcode int
   select @rcode = 0
   
   if not exists(select * from sysobjects where name = 'UDVH' and xtype='V')
   begin
   	select @msg = 'View UDVH does not exist.',@rcode = 1
   	goto bspexit
   end
   -- The view exists so let's query it.
	Select ValProc, [Description] from UDVH
    
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVAUDGetValProcs] TO [public]
GO
