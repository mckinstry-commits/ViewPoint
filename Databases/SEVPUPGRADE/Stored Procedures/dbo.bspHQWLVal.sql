SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspHQWLVal]
/***********************************************************
    * CREATED BY	:	GF 11/29/2001
    * MODIFIED BY	:
   			RM 03/26/04 - Issue# 23061 - Added IsNulls
    *
    * USAGE:
    *   validates HQ Document Template Location
    *
    *	PASS:
    *  Location
    *
    *	RETURNS:
    *  Path & ErrMsg if any
    * 
    * OUTPUT PARAMETERS
    *   @msg     Error message if invalid, 
    * RETURN VALUE
    *   0 Success
    *   1 fail
    *****************************************************/ 
(@location varchar(10), @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @location is null
   	begin
   	select @msg = 'Missing Document Template Location!', @rcode = 1
   	goto bspexit
   	end

--if @location = 'PMCustom'
--	begin
--	select @msg = '\Viewpoint Repository\Document Templates\Custom'
--	goto bspexit
--	end

if @location = 'PMStandard'
	begin
	select @msg = '\Viewpoint Repository\Document Templates\Standard'
	goto bspexit
	end

---- validate location
select @msg = Path from HQWL with (nolock) where Location = @location
if @@rowcount = 0
   	begin
   	select @msg = 'Invalid Template Location', @rcode = 1
   	goto bspexit
   	end

if isnull(@msg,'') = ''
   	begin
   	select @msg = 'Location has an invalid path', @rcode = 1
   	goto bspexit
   	end


bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWLVal] TO [public]
GO
