SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************/
CREATE  view [dbo].[MSTBGrid]
/**************************************************
* Created: ??
* Modified:	GF 07/14/2004 - issue #24950 
*			GG 2/15/05 - #26761 - added comments, (nolock) hints, and 'order by' clause
*			GF 09/11/2008 - note that used via frmMSMassEdit form bound via form code.
*
*
* Provides a view of ticket information used to fill the grid on
* the MS Ticket Entry form.
*
***************************************************/
as
   
   select top 100 percent a.*,
     'TicketTotal' = isnull(a.MatlTotal,0) + isnull(a.HaulTotal,0) + isnull(a.TaxTotal,0) - isnull(a.DiscOff,0) - isnull(a.TaxDisc,0),
     'CoGrp'=
         case a.SaleType
             when 'C' then convert(varchar(3),a.CustGroup)
             when 'I' then convert(varchar(3),a.INCo)
             else convert(varchar(3),a.JCCo)
         end,
    
     'CustLocJob'=
         case a.SaleType
             when 'C' then convert(varchar(10),a.Customer)
             when 'I' then convert(varchar(10),a.ToLoc)
             when 'J' then convert(varchar(10),a.Job)
         end,
    
     'Description'=
         case a.SaleType
             when 'C' 
                 then (select Name from bARCM c with (nolock) where c.CustGroup=a.CustGroup and c.Customer=a.Customer)
             when 'I' 
                 then (select Description from bINLM l with (nolock) where l.INCo=a.INCo and l.Loc=a.ToLoc)
             when 'J' 
                 then (select Description from bJCJM j with (nolock) where j.JCCo=a.JCCo and j.Job=a.Job)
         end,
    
    'TruckEquip' = 
    	case a.HaulerType
    		when 'H' then convert(varchar(10), a.Truck)
    		when 'E' then convert(varchar(10), a. Equipment)
    		when 'N' then ''
    	end
    
   from MSTB a (nolock)
   order by a.Co, a.Mth, a.BatchId, a.BatchSeq


GO
GRANT SELECT ON  [dbo].[MSTBGrid] TO [public]
GRANT INSERT ON  [dbo].[MSTBGrid] TO [public]
GRANT DELETE ON  [dbo].[MSTBGrid] TO [public]
GRANT UPDATE ON  [dbo].[MSTBGrid] TO [public]
GRANT SELECT ON  [dbo].[MSTBGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSTBGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSTBGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSTBGrid] TO [Viewpoint]
GO
