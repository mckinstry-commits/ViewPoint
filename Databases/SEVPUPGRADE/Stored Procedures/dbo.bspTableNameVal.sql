SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspTableNameVal    Script Date: 8/28/99 9:33:43 AM ******/
   CREATE  proc [dbo].[bspTableNameVal]
   /* validates Table name entered in DDSL
    * pass in Table Name
    * returns Table Name Description or ErrMsg
   */
   	(@TableName varchar(30), @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   
   
   if @TableName is null
   
   	begin
   	select @msg = 'Missing Table Name!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = 'Table' from sysobjects
   	where name = @TableName
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Table Name is invalid!', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspTableNameVal] TO [public]
GO
