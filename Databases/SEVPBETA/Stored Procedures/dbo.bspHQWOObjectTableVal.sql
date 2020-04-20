SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[bspHQWOObjectTableVal]
   /*************************************
   * CREATED BY    : GF 12/18/2001
   * LAST MODIFIED : GF 07/18/2002 - Added validation for UDTH - User Tables
   			RM 03/26/04 - Issue# 23061 - Added IsNulls
   *
   * validates HQ Document Object ObjectTable (view)
   *
   * Pass:
   *	HQ Document Object Table
   * 
   * Returns:
   *   Description
   *
   * Success returns:
   *	0 and Description from DDTH or UDTH
   *
   * Error returns:
   *	1 and error message
   *
   **************************************/
   (@objecttable varchar(30), @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @msg = ''
   
   if @objecttable is null
   	begin
   	select @msg = 'Missing document object table!', @rcode = 1
   	goto bspexit
   	end
   
   if substring(@objecttable,1,2) = 'ud'
   	begin
   	select @msg = Description
   	from bUDTH with (nolock) where TableName=@objecttable
   	if @@rowcount = 0
   		begin
   		select @msg = 'User-defined object table not found in UDTH.', @rcode = 1
   		goto bspexit
   		end
   	end
   else
   	begin
   	-- validate Object Table to views in sysobjects
   	if not exists(select * from sysobjects where name = @objecttable and xtype='V')
   		begin
   		select @msg = 'Object Table does not exist!',@rcode = 1
   		goto bspexit
   		end
   
   	-- get description from DDTH
   	select @msg = Description
   	from DDTH with (nolock) where TableName=@objecttable
   	end
   
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWOObjectTableVal] TO [public]
GO
