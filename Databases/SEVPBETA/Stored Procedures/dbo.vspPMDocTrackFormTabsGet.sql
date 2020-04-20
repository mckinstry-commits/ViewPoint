SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************/
CREATE PROCEDURE [dbo].[vspPMDocTrackFormTabsGet]
/********************************
* Created By:	GF 03/23/2007 - 6.x
* Modified By:
*
* Called from the PM Document Tracking Form to get the tab page titles from PMVG
*
* Input:
* @pmvm_view	PM Document View
*
* Output:
* resultset - Tab Titles
*
* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@pmvm_view varchar(10) = null, @errmsg varchar(512) output)
as
set nocount on

declare @rcode int

select @rcode = 0

---- if @pmvm_view does not exist use 'Viewpoint' view
if not exists(select * from PMVM where ViewName=@pmvm_view)
	begin
	select @pmvm_view = 'Viewpoint'
	end


---- PMVG Tab Page titles for the document view
select g.Form as Form, isnull(g.GridTitle, t.Title) as Title, g.Hide as Hide
from dbo.PMVG g
left join DDFTShared t on t.Form='PMDocTrack' and t.GridForm=g.Form
where g.ViewName=@pmvm_view
order by t.LoadSeq



vspexit:
	if @rcode <> 0 select @errmsg = @errmsg
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocTrackFormTabsGet] TO [public]
GO
