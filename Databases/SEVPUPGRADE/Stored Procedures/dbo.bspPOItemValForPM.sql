SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPOItemValForPM    Script Date: 8/28/99 9:33:10 AM ******/
CREATE  proc [dbo].[bspPOItemValForPM]
/***********************************************************
* CREATED BY:	cjw
* MODIFIED BY:	cjw
*				GF 09/10/2008 - issue #129323 check for duplicate items
*				GF 04/21/2009 - issue #133288 return error if not numeric
*				GF 7/27/2011 - TK-07144 changed to varchar(30) 
*
*
* USED BY
*
* USAGE:
* validates PO item
*
* INPUT PARAMETERS
*   POCo  PO Co to validate against
*   PO to validate
*   PO Item to validate
*
* OUTPUT PARAMETERS
*   @itemtype The Purchase orders Item Type
*   @msg      error message if error occurs otherwise Description of PO, Vendor,

* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@poco bCompany = 0, @po VARCHAR(30) = null, @poitem varchar(8) = null,
 @msg varchar(100) output)
as
set nocount on
   
declare @rcode int

set @rcode = 0

if @poco is null
	begin
	select @msg = 'Missing PO Company!', @rcode = 1
	goto bspexit
	end

if @po is null
	begin
	select @msg = 'Missing PO!', @rcode = 1
	goto bspexit
	end

if @poitem is null
	begin
	select @msg = 'Missing PO Item#!', @rcode = 1
	goto bspexit
	end
	
---- po item must be numeric
if dbo.bfIsInteger(@poitem) = 0
	begin
	select @msg = 'Invalid PO Item, must be numeric.', @rcode = 1
	goto bspexit
	end

---- check if item exists
if exists(select TOP 1 1 from bPOIT with (nolock) where POCo=@poco and PO=@po and POItem=@poitem)
	begin
	select @msg='Item already exists. ', @rcode=1
	goto bspexit
	end

if exists(select top 1 1 from bPMMF with (nolock) where POCo=@poco and PO=@po and POItem=@poitem)
	begin
	select @msg='Item already exists. ', @rcode=1
	goto bspexit
	end
	


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOItemValForPM] TO [public]
GO
