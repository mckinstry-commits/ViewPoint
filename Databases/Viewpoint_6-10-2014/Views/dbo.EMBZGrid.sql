SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************
   *Created : ?
   *
   *Modifed by TV 03/16/05
   *
   *
   * Controls grids that are in the Batch
   *
   *******************************************/
   
   
   CREATE   view [dbo].[EMBZGrid] as select top 100 percent h.Co, h.Mth, h.BatchId
    from HQBC h left join EMBF e
    	on h.Co=e.Co
     	and h.Mth = e.Mth
     	and h.BatchId = e.BatchId
    where h.Source = 'EMAdj' and e.EMTransType = 'Fuel'
    order by h.Co, h.Mth, h.BatchId

GO
GRANT SELECT ON  [dbo].[EMBZGrid] TO [public]
GRANT INSERT ON  [dbo].[EMBZGrid] TO [public]
GRANT DELETE ON  [dbo].[EMBZGrid] TO [public]
GRANT UPDATE ON  [dbo].[EMBZGrid] TO [public]
GRANT SELECT ON  [dbo].[EMBZGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMBZGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMBZGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMBZGrid] TO [Viewpoint]
GO
