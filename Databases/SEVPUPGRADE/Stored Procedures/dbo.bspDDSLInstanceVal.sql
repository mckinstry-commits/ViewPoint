SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDSLInstanceVal    Script Date: 8/28/99 9:32:38 AM ******/
   CREATE  proc [dbo].[bspDDSLInstanceVal]
   /***********************************************************
    * CREATED BY: LM 01/29/97
    * MODIFIED By : LM 01/29/97
    *
    * USAGE:
    * validates Instance column on DDSL Form
    *
    * INPUT PARAMETERS
   
    *   Table, Instance Column Name
    * INPUT PARAMETERS
    *   @msg        error message if something went wrong
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
   	(@table varchar(30) = null, @instancecolumn varchar(30) = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   
   if @table is null
   	begin
   	select @msg = 'Missing Table!', @rcode = 1
   	goto bspexit
   	end
   
   if @instancecolumn is null
   	begin
   	select @msg = 'Missing Instance Column!', @rcode = 1
   	goto bspexit
   	end
   
   select * from sysobjects o JOIN syscolumns c on o.id=c.id where o.name=@table
   	and c.name=@instancecolumn
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Instance not on file!', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspDDSLInstanceVal] TO [public]
GO
