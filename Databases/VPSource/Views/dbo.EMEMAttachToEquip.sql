SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* The following is the actual STANDARDS query used to fill this related grid.  The "WHERE" clause is created by and
   uses the inherited EMCo and Equipment values from the parent form.  As setup by this VIEW'S code below
   the queries "WHERE" clause uses this VIEW'S defined (EMCo - redirected to EMEM.EMCo) and (Equipment - redirected to EMEM.AttachToEquip)
   to generated the desired recordset.  Note that the 'Equipment' value from the parent form has been redirected to the
   EMEM.AttachToEquip column and therefore generates a recordset based upon EMCo and AttachToEquip.  
		See VPForm_GetFormDatasetQueryforRelated */

--select EMEMAttachToEquip.EMCo as [EMCo],EMEMAttachToEquip.Attachments as [Attachments],EMEMAttachToEquip.Description as [Description] 
--from EMEMAttachToEquip 
--where EMEMAttachToEquip.EMCo=14 and EMEMAttachToEquip.EMCo=14 and EMEMAttachToEquip.Equipment='10102'

CREATE view [dbo].[EMEMAttachToEquip] as
select 'EMCo' = dbo.EMEM.EMCo, 'Equipment' = dbo.EMEM.AttachToEquip,			--Redirected to use the EMEM.AttachToEquip column
	'Attachments' = dbo.EMEM.Equipment, 'Description' = dbo.EMEM.Description	--Returned values
from dbo.EMEM

GO
GRANT SELECT ON  [dbo].[EMEMAttachToEquip] TO [public]
GRANT INSERT ON  [dbo].[EMEMAttachToEquip] TO [public]
GRANT DELETE ON  [dbo].[EMEMAttachToEquip] TO [public]
GRANT UPDATE ON  [dbo].[EMEMAttachToEquip] TO [public]
GO
