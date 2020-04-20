SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE      view [dbo].[DDFTShared]
/****************************************
 * Created: GG 06/09/03
 * Modified: GG 09/22/04 - added vDDFTc.LoadSeq
 *	     	kb 7/18/5 - added IsStandard flag, This is true when the tab is custom but was
 *				originally a standard tab, added to handle our users ability to move tabs around
 *			GG 07/19/05 - added vDDFT.LoadSeq
 *			CC	07/16/09 - #129922 - Added TitleID column
 * 
 * Combines standard and custom Form Tab information
 * from vDDFT and vDDFTc.  
 *
 ****************************************/
as
select isnull(c.Form,d.Form) as Form,
	isnull(c.Tab,d.Tab) as Tab,
	isnull(c.Title,d.Title) as Title,
	isnull(c.GridForm, d.GridForm) as GridForm,
	QueryName,
	isnull(c.Type, 0) as Type,
	case when c.Form is null then 'N' when c.Form like 'ud%' and isnull(c.Tab,d.Tab) < 100 then 'N' else 'Y' end as Custom,
	--case when c.LoadSeq is null then isnull(c.Tab,d.Tab) else c.LoadSeq end as LoadSeq,
	isnull(c.LoadSeq, d.LoadSeq) as LoadSeq,
	case when isnull(c.Tab,d.Tab) <100 then 'Y' else 'N' end as IsStandard, 
	case when c.IsVisible is null then 'Y' else c.IsVisible end as IsVisible,
	d.TitleID
from dbo.vDDFTc c
full outer join dbo.vDDFT d on  d.Form = c.Form  and d.Tab = c.Tab



GO
GRANT SELECT ON  [dbo].[DDFTShared] TO [public]
GRANT INSERT ON  [dbo].[DDFTShared] TO [public]
GRANT DELETE ON  [dbo].[DDFTShared] TO [public]
GRANT UPDATE ON  [dbo].[DDFTShared] TO [public]
GRANT SELECT ON  [dbo].[DDFTShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDFTShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDFTShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDFTShared] TO [Viewpoint]
GO
