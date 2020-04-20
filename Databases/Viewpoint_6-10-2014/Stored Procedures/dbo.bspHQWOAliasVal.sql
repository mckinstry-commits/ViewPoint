SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspHQWOAliasVal]
   /*************************************
   * CREATED BY    : GF 12/18/2001
   * LAST MODIFIED : GF 01/26/2004 - issue #18841 added word table flag to validation
   			RM 03/26/04 - Issue# 23061 - Added IsNulls
   *
   * validates HQ Document Objects Alias
   *
   * Pass:
   *	HQ Template Type
   *	HQ Document Object
   *	HQ Document Object Alias
   * 
   * Returns:
   *   Description
   *
   * Success returns:
   *	0 and Description from HQWO
   *
   * Error returns:
   *	1 and error message
   *
   **************************************/
   (@templatetype varchar(10), @docobject varchar(30), @alias varchar(2), @wordtable bYN, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @validcnt int
   
   select @rcode = 0, @msg = ''
   
   if @templatetype is null
   	begin
   	select @msg = 'Missing Template Type!', @rcode = 1
   	goto bspexit
   	end
   
   if @docobject is null
   	begin
   	select @msg = 'Missing document object!', @rcode = 1
   	goto bspexit
   	end
   
   if @alias is null
   	begin
   	select @msg = 'Missing document object alias!', @rcode = 1
   	goto bspexit
   	end
   
   -- validate that alias does not exist in any other Document Object for the template type.
   select @validcnt = count(*) from HQWO with (nolock) where DocObject=@docobject and TemplateType=@templatetype
   and exists(select b.Alias from HQWO b with (nolock) where b.TemplateType=@templatetype and b.Alias=@alias 
   			and b.WordTable=@wordtable and b.DocObject<>@docobject)
   if @validcnt <> 0
   	begin
   	select @msg = 'Invalid alias, used in another document object for this template type', @rcode = 1
   	goto bspexit
   	end
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWOAliasVal] TO [public]
GO
