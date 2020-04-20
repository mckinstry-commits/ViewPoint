SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* The following is the actual STANDARDS query used to fill this related grid.  The "WHERE" clause is created by and
   uses the inherited EMCo and Equipment values from the parent form.  As setup by this VIEW'S code below
   the queries "WHERE" clause uses this VIEW'S defined (EMCo - redirected to EMEM.EMCo) and (Equipment - redirected to EMEM.CompOfEquip)
   to generated the desired recordset.  Note that the 'Equipment' value from the parent form has been redirected to the
   EMEM.CompOfEquip column and therefore generates a recordset based upon EMCo and CompOfEquip.  
		See VPForm_GetFormDatasetQueryforRelated */

--select EMEMCompOfEquip.EMCo as [EMCo],EMEMCompOfEquip.Component as [Component],EMEMCompOfEquip.Description as [Description],
--	EMEMCompOfEquip.CompTypeCode as [CompTypeCode],EMEMCompOfEquip.CompTypeDesc as [CompTypeDesc] 
--from EMEMCompOfEquip 
--left join EMTY on EMTY.EMGroup = EMEMCompOfEquip.EMGroup and EMTY.ComponentTypeCode = EMEMCompOfEquip.CompTypeCode 
--where EMEMCompOfEquip.EMCo=14 and EMEMCompOfEquip.EMCo=14 and EMEMCompOfEquip.Equipment='10102'

CREATE view [dbo].[EMEMCompOfEquip] as
select 'EMCo' = dbo.EMEM.EMCo, 'Equipment' = dbo.EMEM.CompOfEquip,					--Redirected to use the EMEM.CompOfEquip column
	'Component' = dbo.EMEM.Equipment, 'Description' = dbo.EMEM.Description,			--Returned values
	'CompTypeCode' = dbo.EMEM.ComponentTypeCode, 'EMGroup' = dbo.EMEM.EMGroup, 'CompTypeDesc' = dbo.EMTY.Description
from dbo.EMEM
left join dbo.EMTY on dbo.EMTY.EMGroup = dbo.EMEM.EMGroup and dbo.EMTY.ComponentTypeCode = dbo.EMEM.ComponentTypeCode

GO
GRANT SELECT ON  [dbo].[EMEMCompOfEquip] TO [public]
GRANT INSERT ON  [dbo].[EMEMCompOfEquip] TO [public]
GRANT DELETE ON  [dbo].[EMEMCompOfEquip] TO [public]
GRANT UPDATE ON  [dbo].[EMEMCompOfEquip] TO [public]
GRANT SELECT ON  [dbo].[EMEMCompOfEquip] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMEMCompOfEquip] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMEMCompOfEquip] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMEMCompOfEquip] TO [Viewpoint]
GO
