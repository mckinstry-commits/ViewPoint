SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPIDesc    Script Date: 06/10/2005 ******/
CREATE       proc [dbo].[vspPMPIDesc]
/*************************************
 * Created By:	GF 06/10/2005
 * Modified by:
 *
 * called from PMPunchListItems to return project punch list item key description
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * PunchList	PM Punch List
 * Item			PM Punch List Item
 *
 * Returns:
 * Description
 *
 * Success returns:
 *	0 and Description from PMPI
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @punchlist bDocument, @item smallint = null, @msg varchar(30) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''


if @item is not null
	begin
	select @msg = substring(Description,1,30)
	from PMPI with (nolock) where PMCo=@pmco and Project=@project and PunchList=@punchlist and Item=@item
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPIDesc] TO [public]
GO
