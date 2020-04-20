SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************/
CREATE   proc [dbo].[bspINMOItemValForPM]
/***********************************************************
* CREATED BY	:	GF 02/18/2002
* MODIFIED BY	:	GF 09/10/2008 - issue #129323 check for duplicate items
*
*
* USAGE:
* validates MO item for PM MO Items
*
* INPUT PARAMETERS
*  INCo		IN Company to validate against
*  MO			MO to validate
*  MOItem		MO Item to validate
*
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description

* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@inco bCompany = null, @mo varchar(10) = null, @moitem bItem = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @inco is null
	begin
	select @msg = 'Missing IN Company!', @rcode = 1
	goto bspexit
	end

if @mo is null
	begin
	select @msg = 'Missing MO!', @rcode = 1
	goto bspexit
	end

if @moitem is null
	begin
	select @msg = 'Missing MO Item!', @rcode = 1
	goto bspexit
	end


if exists(select TOP 1 1 from INMI with (nolock) where INCo=@inco and MO=@mo and MOItem=@moitem)
	begin
	select @msg='Item already exists. ', @rcode=1
	goto bspexit
	end

if exists(select top 1 1 from PMMF with (nolock) where INCo=@inco and MO=@mo and MOItem=@moitem)
	begin
	select @msg='Item already exists. ', @rcode=1
	goto bspexit
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOItemValForPM] TO [public]
GO
