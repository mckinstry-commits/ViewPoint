SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspHQWOVal]
/*************************************
* CREATED BY:	GF 01/08/2001
* Modfified By:	GF 01/26/2003 - issue #18841 - added WordTable flag as output parameter for validation
*				RM 03/26/04 - Issue# 23061 - Added IsNulls
*
*
* validates HQ Document Objects
*
* Pass:
*	HQ Template Type
*	HQ Document Object
* 
* Returns:
*	Object
*	Alias
*	Table
*   Description
*
* Success returns:
*	0 and Description from HQWO
*
* Error returns:
*	1 and error message
*
**************************************/
(@templatetype varchar(10), @docobject varchar(30), @alias varchar(2) output, 
 @joinorder tinyint output, @objecttable varchar(30) output, @wordtable bYN output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

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

---- validate document object
select @alias=Alias, @joinorder=JoinOrder, @objecttable=ObjectTable, @wordtable=WordTable
from bHQWO with (nolock) where TemplateType=@templatetype and DocObject=@docobject
if @@rowcount = 0
   	begin
   	select @msg = 'Invalid Document Object', @rcode = 1
   	goto bspexit
   	end

select @msg = 'Alias: ' + isnull(@alias,'') + '  Join Order: ' + isnull(convert(varchar(3),@joinorder),'')


bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWOVal] TO [public]
GO
