SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMDDHQMTDesc    Script Date: 08/02/2005 ******/
CREATE proc [dbo].[vspPMDDHQMTDesc]
/*************************************
 * Created By:	GF 08/25/2005
 * Modified by:
 *
 * called from PMDailyLogDeliveries to return matl desc if valid
 *
 * Pass:
 * MatlGroup		HQ Material Group
 * Material			HQ Material
 * 
 * Returns:
 * Description
 *
 * Success returns:
 *	0 and Description from HQMT
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@matlgroup bGroup, @material bMatl, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@material,'') <> ''
	begin
	select @msg = Description
	from HQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDDHQMTDesc] TO [public]
GO
