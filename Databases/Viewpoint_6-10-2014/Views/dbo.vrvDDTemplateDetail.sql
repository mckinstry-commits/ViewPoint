SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view  [dbo].[vrvDDTemplateDetail]
as
select DDTF.FolderTemplate, DDTF.Title, DDTF.Mod, DDTD.MenuItem, FormName = RPRT.Title,DDTD.MenuSeq, Type ='Report'

from DDTF 
left outer join DDTD on DDTF.FolderTemplate = DDTD.FolderTemplate 
left outer join RPRT on DDTD.MenuItem = RPRT.ReportID
where DDTD.ItemType = 'R' 


UNION ALL

select DDTF.FolderTemplate, DDTF.Title, DDTF.Mod, DDTD.MenuItem,  FormName = DDFH.Title, DDTD.MenuSeq, Type ='Form'
	
from DDTF 
 join DDTD on DDTF.FolderTemplate = DDTD.FolderTemplate 
 join DDFH on DDTD.MenuItem = DDFH.Form
where DDTD.ItemType = 'F' 





GO
GRANT SELECT ON  [dbo].[vrvDDTemplateDetail] TO [public]
GRANT INSERT ON  [dbo].[vrvDDTemplateDetail] TO [public]
GRANT DELETE ON  [dbo].[vrvDDTemplateDetail] TO [public]
GRANT UPDATE ON  [dbo].[vrvDDTemplateDetail] TO [public]
GRANT SELECT ON  [dbo].[vrvDDTemplateDetail] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvDDTemplateDetail] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvDDTemplateDetail] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvDDTemplateDetail] TO [Viewpoint]
GO
