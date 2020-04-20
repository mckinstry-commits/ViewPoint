SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      View [dbo].[brvJBTemplateInfo]
     --Drop view brvJBTemplateInfo
     /***********************************************
       JB Template Info View 
       Created 8/22/2002 AA
     
      View performs two separate select statements for both the
      Cost types and Add-on information. 
     
     Reports:  JB Template Info
     
     *************************************************/
     
     as
     
     
    --Select Cost type information
     
     select JBTC.JBCo, JBTC.Template, JBTC.Seq, JBTC.PhaseGroup, JBTC.CostType, JBTC.APYN,
      JBTC.EMYN, JBTC.INYN, JBTC.JCYN, JBTC.MSYN, JBTC.PRYN, JBTC.Category, JBTC.LiabilityType,
      JBTC.EarnType, AddonSeq=null, SortType='CT' 
     From JBTC
     
     
     union all
     
     --Select Add-on information
     
     select JBTA.JBCo, JBTA.Template, JBTA.Seq,null, null,null,null,null,null,null,null,
      null,null,null,JBTA.AddonSeq, SortType='TA'
     From JBTA
     
     
     union all
      --Select Add-on information
     
     select JBTA.JBCo, JBTA.Template, JBTA.AddonSeq,null, null,null,null,null,null,null,null,
      null,null,null,JBTA.Seq, SortType='TS'
     From JBTA

GO
GRANT SELECT ON  [dbo].[brvJBTemplateInfo] TO [public]
GRANT INSERT ON  [dbo].[brvJBTemplateInfo] TO [public]
GRANT DELETE ON  [dbo].[brvJBTemplateInfo] TO [public]
GRANT UPDATE ON  [dbo].[brvJBTemplateInfo] TO [public]
GO
