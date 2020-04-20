SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE    proc [dbo].[vspPMPFListViewFormGet]
/****************************************************************************
 * Created By:	GF 02/03/2006
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Returns project firm information for position, size, and list view column widths.
 *
 * INPUT PARAMETERS:
 * PM Project Firm ListView Form name
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@form varchar(30) = null)
as
set nocount on

declare @rcode int

select @rcode = 0

-- -- -- return Form Header
select s.Form, s.Title, s.HelpKeyword, u.Options, isnull(u.GridRowHeight,0) as GridRowHeight
from dbo.DDFHShared s with (nolock)
left outer join dbo.vDDFU u with (nolock) on u.VPUserName = suser_sname() and u.Form = s.Form
where s.Form = @form



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPFListViewFormGet] TO [public]
GO
