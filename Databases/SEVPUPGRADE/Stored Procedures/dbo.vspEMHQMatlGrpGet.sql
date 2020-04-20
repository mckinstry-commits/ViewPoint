SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMatlGrpGet    Script Date: 8/28/99 9:34:52 AM ******/
CREATE    proc [dbo].[vspEMHQMatlGrpGet]
/********************************************************
* CREATED BY: 	SE 2/6/97
* MODIFIED BY:
*				RM 02/13/04 = #23061, Add isnulls to all concatenated strings
*				GF 01/25/2008 - issue #125204 added output parameter for EMCo.MatlValid
*
*
* USAGE:
* 	Retrieves the Material Group from HQCO and Material Valid from from EMCO.
*
* INPUT PARAMETERS:
*	HQ Company number
*
* OUTPUT PARAMETERS:
*	Material Group from HQCO
*   Material Valid Flag from EMCO
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@emco bCompany = 0, @MatlGroup tinyint = null output, @matlvalid varchar(1) = 'Y' output,
 @msg varchar(255) output)
as 
set nocount on

declare @rcode int

select @rcode = 0

if @emco is null
	begin
	select @msg = 'Missing EM Company', @rcode = 1
	goto vspexit
	end

---- validate EM company
select @matlvalid=MatlValid
from dbo.EMCO with (nolock) where EMCo = @emco
if @@rowcount = 0
	begin
	select @msg = 'EM Company: ' + convert(varchar,@emco) + ' not setup in EM.', @rcode = 1
	goto vspexit
	end

---- get material groupd
select @MatlGroup = MatlGroup 
from dbo.HQCO with (nolock) where HQCo = @emco
if @@rowcount  = 0
	begin
	select @msg = 'HQ company does not exist.', @rcode=1
	goto vspexit
	end

if @MatlGroup is Null 
	begin
	select @msg = 'Material group not setup for company ' + isnull(convert(varchar(3),@emco),''), @rcode=1
	goto vspexit
	end



vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMHQMatlGrpGet] TO [public]
GO
