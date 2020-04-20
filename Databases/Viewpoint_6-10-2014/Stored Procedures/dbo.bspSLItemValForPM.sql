SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLItemValForPM    Script Date: 8/28/99 9:33:41 AM ******/
CREATE proc [dbo].[bspSLItemValForPM]
/***********************************************************
* CREATED BY:	LM 05/11/99
* MODIFIED BY:	GF 09/10/2008 - issue #129323 check for duplicate items
*				GF 04/21/2009 - issue #133288 return error if not numeric
*				DC 06/25/10 - #135813 - expand subcontract number
*				GF 07/12/2010 - issue #140504 SLIT output parameters for validation
*
*
* USAGE:
* validates SL item to make sure it doesn't already exist in SLIT
*
* INPUT PARAMETERS
*   SLCo  SL Co to validate against
*   SL to validate
*   SL Item to validate

*
* OUTPUT PARAMETERS
*
*   @msg      error message if error occurs otherwise Description of SL

* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@slco bCompany = 0, @sl VARCHAR(30) = NULL, --bSL = null, DC #135813
 @slitem smallint = null, @ItemType tinyint = null output,
 @ItemPhase bPhase = null output, @ItemCostType bJCCType = null output,
 @ItemUM bUM = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

set @rcode = 0

if @slco is null
	begin
	select @msg = 'Missing SL Company!', @rcode = 1
	goto bspexit
	end

if @sl is null
	begin
	select @msg = 'Missing SL!', @rcode = 1
	goto bspexit
	end

if @slitem is null
	begin
	select @msg = 'Missing SL Item#!', @rcode = 1
	goto bspexit
	end

---- sl item must be numeric
if dbo.bfIsInteger(@slitem) = 0
	begin
	select @msg = 'Invalid SL Item, must be numeric.', @rcode = 1
	goto bspexit
	end

---- #140504
---- get SLIT information if exists
select @ItemType = ItemType, @ItemPhase = Phase, @ItemCostType = JCCType,
		@ItemUM = UM
from dbo.SLIT where SLCo=@slco and SL=@sl and SLItem=@slitem
----if @@rowcount = 0
----	begin
----	select @msg='Item already exists. ', @rcode=1
----	goto bspexit
----	end
	
if exists(select TOP 1 1 from SLIT with (nolock) where SLCo=@slco and SL=@sl and SLItem=@slitem)
	begin
	select @msg='Item already exists. ', @rcode=1
	goto bspexit
	end

if exists(select top 1 1 from PMSL with (nolock) where SLCo=@slco and SL=@sl and SLItem=@slitem)
	begin
	select @msg='Item already exists. ', @rcode=1
	goto bspexit
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLItemValForPM] TO [public]
GO
