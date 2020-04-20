SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMVMDesc    Script Date: 04/26/2005 ******/
CREATE   proc [dbo].[vspPMVMDesc]
/*************************************
 * Created By:	GF 04/26/2005
 * Modified by:
 *
 * called from PMDocTrackingViewMaster to return DocTrack View key description
 *
 * Pass:
 * PM Document Tracking View
 * 
 * Returns:
 * Description
 *
 * Success returns:
 *	0 and Description from PMVM
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@viewname varchar(10), @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@viewname,'') <> ''
	begin
	select @msg = Description
	from PMVM with (nolock) where ViewName=@viewname
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMVMDesc] TO [public]
GO
