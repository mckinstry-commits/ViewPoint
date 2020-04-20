SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE  View [dbo].[APLBPONotes]
   /*******************************************************
   *	Created:	02/23/09 MV
   * 	Modified:	
   *
   *  	Used in APEntryDetail to display PO header and line notes
   *		in a related grid tab
   * 
   *********************************************************/
   as
   select top 100 percent b.Co, b.Mth, b.BatchId, b.BatchSeq, b.APLine,p.PO, p.POItem,
		p.Notes 'POItemNotes', h.Notes 'PONotes'
   from dbo.bAPLB b (nolock)
   left outer join dbo.bPOIT p on b.Co=p.POCo and b.PO=p.PO and b.POItem=p.POItem
	join dbo.bPOHD h on p.POCo=h.POCo and p.PO=h.PO
	where b.PO is not null and b.POItem is not null and p.PO is not null    


    
    
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[APLBPONotes] TO [public]
GRANT INSERT ON  [dbo].[APLBPONotes] TO [public]
GRANT DELETE ON  [dbo].[APLBPONotes] TO [public]
GRANT UPDATE ON  [dbo].[APLBPONotes] TO [public]
GO
