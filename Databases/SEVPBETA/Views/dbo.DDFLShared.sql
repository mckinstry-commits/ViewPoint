SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  view [dbo].[DDFLShared]
/****************************************
* Created: 06/10/03 GG
* Modified:
*
* Combines standard and custom Form Item Lookups
* from vDDFL and vDDFLc
*
*
****************************************/
as

select isnull(c.Form,l.Form) as Form,
	isnull(c.Seq,l.Seq) as Seq,
	isnull(c.Lookup,l.Lookup) as Lookup, 
	isnull(c.LookupParams,l.LookupParams) as LookupParams,
	isnull(c.Active, 'Y') as Active,
	isnull(c.LoadSeq,l.LoadSeq) as LoadSeq,
	case when c.Form is null and l.Form is not null then 'Standard' 
		when c.Form is not null and l.Form is not null THEN 'Override' 
		when c.Form is not null and l.Form is null THEN 'Custom' 
		else 'Unknown' end AS [Status]
from dbo.vDDFLc c
full outer join dbo.vDDFL l on  l.Form = c.Form and l.Seq = c.Seq and l.Lookup = c.Lookup 






GO
GRANT SELECT ON  [dbo].[DDFLShared] TO [public]
GRANT INSERT ON  [dbo].[DDFLShared] TO [public]
GRANT DELETE ON  [dbo].[DDFLShared] TO [public]
GRANT UPDATE ON  [dbo].[DDFLShared] TO [public]
GO
