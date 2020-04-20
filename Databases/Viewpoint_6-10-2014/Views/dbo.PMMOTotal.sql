SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE view [dbo].[PMMOTotal] as
/*****************************************
* Created: ??
* Modified: GG 04/10/08 - added top 100 percent and order by
*			GF 04/29/2010 - issue #138434 added PCO to PM totals
*
*
* Provides a view of PM Material detail for
* Material order with totals. Used in PM MO Header.
*
*****************************************/

-- OLD
----select top 100 percent a.INCo, a.MO, 'MOTotal' = isnull(sum(b.TotalPrice),0), 'PMMOAmt'=isnull(sum(PMMOAmt),0),
----		'PMMOExists' =  case when exists(select 1 from bPMMF x with (nolock) where x.INCo=a.INCo
----						and x.MO=a.MO and x.MOItem is not null and x.InterfaceDate is null
----						and x.MaterialOption='M') then 'Y' else 'N' end,
----		'SortOrder' = case when a.Status=3 then 'A' when a.Status=0 then 'B' when a.Status=1 then 'C' else 'D' end,
----		'TotalMO' = isnull(sum(b.TotalPrice),0) + isnull(sum(PMMOAmt),0)

----from bINMO a
----left join bINMI b on b.INCo=a.INCo and b.MO=a.MO
----left join (select c.INCo, c.MO, c.SendFlag, c.InterfaceDate, c.RecordType, c.MaterialOption,
----    			c.ACO, PMMOAmt=isnull(sum(c.Amount),0)
----    			from bPMMF c where c.SendFlag='Y' and c.InterfaceDate is null and c.MaterialOption='M'
----    			and ((c.RecordType='O' and c.ACO is null) or (c.RecordType='C' and (c.ACO is not null OR c.PCO is not null)))
----    			group by c.INCo, c.MO, c.SendFlag, c.InterfaceDate, c.RecordType, c.MaterialOption, c.ACO) pm on pm.INCo=a.INCo and pm.MO=a.MO
----group by a.INCo, a.MO, a.Status
----order by a.INCo, a.MO

-- NEW
select top 100 percent a.INCo, a.MO, 'MOTotal' = isnull(sum(b.TotalPrice),0),
		'SortOrder' = case when a.Status=3 then 'A' 
						   when a.Status=0 then 'B'
						   when a.Status=1 then 'C' else 'D' end,
		cast(isnull(pm.PMMOExists,'N') as char(1)) as PMMOExists,		   
		cast(isnull(pm.PMMOAmt,0) as numeric(20,2)) as PMMOAmt,
		cast(isnull(sum(b.TotalPrice),0) + isnull(pm.PMMOAmt,0) as numeric(20,2)) as TotalMO

from dbo.bINMO a
left join dbo.bINMI b on b.INCo=a.INCo and b.MO=a.MO
OUTER
APPLY
dbo.vfPMMaterialOrderTotal (a.INCo, a.MO) pm
group by a.INCo, a.MO, a.Status, pm.PMMOAmt, pm.PMMOExists
order by a.INCo, a.MO








GO
GRANT SELECT ON  [dbo].[PMMOTotal] TO [public]
GRANT INSERT ON  [dbo].[PMMOTotal] TO [public]
GRANT DELETE ON  [dbo].[PMMOTotal] TO [public]
GRANT UPDATE ON  [dbo].[PMMOTotal] TO [public]
GRANT SELECT ON  [dbo].[PMMOTotal] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMMOTotal] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMMOTotal] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMMOTotal] TO [Viewpoint]
GO
