SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* The following is the actual STANDARDS query used to fill this related grid.  The "WHERE" clause is created by and
   uses the inherited JBCo, Template, and Seq values from the parent form.  As setup by this VIEW'S code below
   the queries "WHERE" clause uses this VIEW'S defined (JBCo - redirected to JBTA.JBCo) and (Template - redirected to JBTA.Template)
   and (Seq - redirected to JBTA.AddonSeq) to generated the desired recordset. Note that the 'Seq' value from the parent 
   form has been redirected to the JBTA.AddonSeq column and therefore generates a recordset based upon 
   JBCo, Template and AddonSeq.  
		See VPForm_GetFormDatasetQueryforRelated */

--select JBTA.JBCo as [JBCo],JBTA.AddonSeq as [AddonSeq],JBTS.Type as [Type],JBTS.Description as [Description],
--	JBTS.GroupNum as [Group #],JBTS.MarkupOpt as [Markup Opt],JBTS.MarkupRate as [Markup Rate],JBTS.AddonAmt as [Addon Amount] 
--from JBTA 
--left join JBTS with (nolock) on JBTS.JBCo = JBTA.JBCo and JBTS.Template = JBTA.Template and JBTS.Seq = JBTA.AddonSeq

CREATE view [dbo].[JBTATempAddonSeqs] as
select 'JBCo' = JBCo, 'Template' = Template, 'Seq' = AddonSeq,		--Redirected to use the JBTA.AddonSeq column
	'ActualSeq' = Seq												--Returned values
from dbo.JBTA

GO
GRANT SELECT ON  [dbo].[JBTATempAddonSeqs] TO [public]
GRANT INSERT ON  [dbo].[JBTATempAddonSeqs] TO [public]
GRANT DELETE ON  [dbo].[JBTATempAddonSeqs] TO [public]
GRANT UPDATE ON  [dbo].[JBTATempAddonSeqs] TO [public]
GO
