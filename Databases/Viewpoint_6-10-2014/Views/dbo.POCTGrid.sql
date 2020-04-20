SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    view [dbo].[POCTGrid] 
   /*************************************
   *	Created by:		??
   *	Modfied by:		01/21/05 MV - #26761 comments, with (nolock)
   *					02/23/05 MV - #26761 top 100 percent, order by
   *	Used by Form PO Compliance
   **************************************/
   as
    select top 100 percent POCo, PO, CompCode, Seq, Vendor, Description, Verify, ExpDate,
    Complied=Case
      when Complied='Y' then 'Y'
         else 'N'
      end
    
    from POCT with (nolock)
    order by POCo,PO, CompCode, Seq

GO
GRANT SELECT ON  [dbo].[POCTGrid] TO [public]
GRANT INSERT ON  [dbo].[POCTGrid] TO [public]
GRANT DELETE ON  [dbo].[POCTGrid] TO [public]
GRANT UPDATE ON  [dbo].[POCTGrid] TO [public]
GRANT SELECT ON  [dbo].[POCTGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POCTGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POCTGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POCTGrid] TO [Viewpoint]
GO
