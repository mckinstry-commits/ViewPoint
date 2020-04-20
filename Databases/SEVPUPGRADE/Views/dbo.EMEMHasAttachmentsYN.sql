SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view  [dbo].[EMEMHasAttachmentsYN] as
/* Created by TRL 10/20/08 Issue 130202

Usage:  Replace function - vfEMEquipHasAttachments

*/
select e.EMCo,e.Equipment,HasAttachments = case when count(m.Equipment)> 0 then'Y'else 'N'end
From dbo.EMEM e with(nolock)
Left Join dbo.EMEM m with(nolock)on m.EMCo=e.EMCo and m.AttachToEquip = e.Equipment
Group by e.EMCo,e.Equipment

GO
GRANT SELECT ON  [dbo].[EMEMHasAttachmentsYN] TO [public]
GRANT INSERT ON  [dbo].[EMEMHasAttachmentsYN] TO [public]
GRANT DELETE ON  [dbo].[EMEMHasAttachmentsYN] TO [public]
GRANT UPDATE ON  [dbo].[EMEMHasAttachmentsYN] TO [public]
GO
