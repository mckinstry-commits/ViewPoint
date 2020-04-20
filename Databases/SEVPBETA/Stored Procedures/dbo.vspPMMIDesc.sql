SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMMIDesc    Script Date: 01/10/2006 ******/
CREATE  proc [dbo].[vspPMMIDesc]
/*************************************
 * Created By:	GF 01/10/2006
 * Modified by:
 *
 * called from PMMeetingMinutesItems to return meeting minute item key description
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * MeetingType	PM Meeting Type
 * Meeting		PM Meeting
 * MinutesType	PM Meeting Minutes Type
 * Item			PM Meeting Minutes Item
 *
 * Returns:
 * Description
 *
 * Success returns:
 *	0 and Description from PMMI
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @meetingtype bDocType, @meeting int = null,
 @minutestype tinyint = null, @item int = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if @meeting is not null and @item is not null
	begin
	select @msg = Description
	from PMMI with (nolock) where PMCo=@pmco and Project=@project and MeetingType=@meetingtype
	and Meeting=@meeting and MinutesType=@minutestype and Item=@item
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMMIDesc] TO [public]
GO
