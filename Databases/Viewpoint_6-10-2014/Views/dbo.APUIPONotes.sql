SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE  View [dbo].[APUIPONotes]
   /*******************************************************
   *	Created:	03/06/09 MV
   * 	Modified:	
   *
   *  	Used in APUnapprovedItems to display PO header and line notes
   *		in a related grid tab
   * 
   *********************************************************/
   as
   select top 100 percent b.APCo, b.UIMth, b.UISeq, b.Line,p.PO, p.POItem,
		p.Notes 'POItemNotes', h.Notes 'PONotes'
   from bAPUL b (nolock)
   left outer join bPOIT p on b.APCo=p.POCo and b.PO=p.PO and b.POItem=p.POItem
		join dbo.bPOHD h on p.POCo=h.POCo and p.PO=h.PO
	where b.PO is not null and b.POItem is not null and p.PO is not null    





    
    
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[APUIPONotes] TO [public]
GRANT INSERT ON  [dbo].[APUIPONotes] TO [public]
GRANT DELETE ON  [dbo].[APUIPONotes] TO [public]
GRANT UPDATE ON  [dbo].[APUIPONotes] TO [public]
GRANT SELECT ON  [dbo].[APUIPONotes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APUIPONotes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APUIPONotes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APUIPONotes] TO [Viewpoint]
GO
