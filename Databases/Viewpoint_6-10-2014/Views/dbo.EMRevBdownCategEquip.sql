SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMRevBdownCategEquip] as
/* Created:  TRL Issue 130856 02/12/09
*
Usage: EM Revenue Rate Update
* 1.  Used as view for a Lookup that will list both
* Category and Equipment RevBdown Rates.
* 2.  Used to fill update grids on the EM Revenue Rate Update form
*/
Select b.Rate,b.RevBdownCode,[Description]=IsNull(b.Description,t.Description),
b.Category,[CatDesc]=c.Description,[Type]='C',b.RevCode,[RevCodeDesc]=r.Description,
[Equipment]=null,[EquipDesc]=Null,b.EMCo,b.EMGroup
From dbo.EMBG b with(nolock)
Inner join dbo.EMRT t with(nolock)on t.EMGroup=b.EMGroup and t.RevBdownCode=b.RevBdownCode
Inner join dbo.EMRC r with(nolock)on r.EMGroup=b.EMGroup and r.RevCode=b.RevCode
Inner Join dbo.EMCM c with(nolock)on c.EMCo=b.EMCo and c.Category=b.Category

Union All

Select e.Rate,e.RevBdownCode,IsNull(e.Description,t.Description),
m.Category,c.Description,'E',e.RevCode,r.Description,
e.Equipment,m.Description,e.EMCo,e.EMGroup
From EMBE e with(nolock)
Inner join dbo.EMRT t with(nolock)on t.EMGroup=e.EMGroup and t.RevBdownCode=e.RevBdownCode
Inner join dbo.EMEM m with(nolock)on e.EMCo=m.EMCo and e.Equipment=m.Equipment
Left Join dbo.EMCM c with(nolock)on m.EMCo=c.EMCo and m.Category=c.Category
Inner join dbo.EMRC r with(nolock)on r.EMGroup=e.EMGroup and r.RevCode=e.RevCode
Where IsNull(m.Category,'') <> ''
GO
GRANT SELECT ON  [dbo].[EMRevBdownCategEquip] TO [public]
GRANT INSERT ON  [dbo].[EMRevBdownCategEquip] TO [public]
GRANT DELETE ON  [dbo].[EMRevBdownCategEquip] TO [public]
GRANT UPDATE ON  [dbo].[EMRevBdownCategEquip] TO [public]
GRANT SELECT ON  [dbo].[EMRevBdownCategEquip] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMRevBdownCategEquip] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMRevBdownCategEquip] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMRevBdownCategEquip] TO [Viewpoint]
GO
