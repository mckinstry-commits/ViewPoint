SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       View [dbo].[brvEMEquipCategory] as
     /* EMEquipRevBdown.rpt
     View combines EM Equipment and EM Category Info in the same view.--- Created By Aghaa 1/24/02
     */
     Select EMEM.EMCo, EMEM.Equipment, Type='C', EquipRateOR = (select count(*) From EMBE Where EMBE.RevCode=EMRR.RevCode and EMBE.EMCo=EMEM.EMCo and EMBE.Equipment=EMEM.Equipment),
     EMRR.RevCode,EMBG.RevBdownCode, EMBG.Rate,
     EMEM.Description,EMBG.EMGroup,EMBG.Category
     From EMEM
     Left Outer Join EMRR on EMEM.EMCo=EMRR.EMCo and EMEM.Category=EMRR.Category 
     Left Outer Join EMBG on EMRR.EMCo=EMBG.EMCo and EMRR.RevCode=EMBG.RevCode and
     EMRR.Category=EMBG.Category
     Union
     Select EMEM.EMCo, EMEM.Equipment, Type='E',1,EMRH.RevCode,EMBE.RevBdownCode, EMBE.Rate,
     EMEM.Description,EMRH.EMGroup,EMEM.Category
     From EMEM
     Left Outer Join EMRH on EMEM.EMCo=EMRH.EMCo and EMEM.Equipment=EMRH.Equipment  
     Left Outer Join EMBE on EMRH.EMCo=EMBE.EMCo and EMRH.RevCode=EMBE.RevCode and 
     EMRH.Equipment=EMBE.Equipment
    Where  EMRH.ORideRate='Y'

GO
GRANT SELECT ON  [dbo].[brvEMEquipCategory] TO [public]
GRANT INSERT ON  [dbo].[brvEMEquipCategory] TO [public]
GRANT DELETE ON  [dbo].[brvEMEquipCategory] TO [public]
GRANT UPDATE ON  [dbo].[brvEMEquipCategory] TO [public]
GO
