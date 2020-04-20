SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  View dbo.SLWIGrid    Script Date: 8/28/99 9:29:58 AM ******/
      CREATE     view [dbo].[SLWIGrid]
      /************************************************************
       * Created: ??
       * Modified: GG 05/31/00 - fixed PrevInvcd, ThisInvcd, ToDate, and PctBilled
       *           kb 9/25/1 - issue #14705
   	*			MV 01/21/05 - #26761 - with (nolock)
   	*			MV 02/23/05 - #26761 top 100 percent, order by
       *
       * Used by the SL Worksheet form to display Item info
       *
       ****************************************************************/
       as
       select top 100 percent w.SLCo, w.SL, w.SLItem, w.Description, w.ItemType, w.Phase, w.UM, w.CurUnits,
       w.CurUnitCost, w.CurCost,
      	w.PrevWCUnits, w.PrevWCCost, w.WCUnits, w.WCCost, w.WCRetPct, w.WCRetAmt,
        w.PrevSM, w.Purchased,
          w.Installed, w.SMRetPct, w.SMRetAmt, w.LineDesc, w.VendorGroup, w.Supplier,
      	  'PrevInvcd' = PrevWCCost + PrevSM,    -- pull from SLWI, because previous amts can be edited
          'ThisInvcd' = WCCost + Purchased - Installed,  -- removed PrevSM
      	'ToDate' = PrevWCCost + WCCost + PrevSM + Purchased - Installed, -- removed one instance of PrevSM
      	'PctBilled'= WCPctComplete,   -- removed one instance of PrevSM
          'SM' = PrevSM + Purchased - Installed,
          BillMonth, BillNumber
      from SLWI w with (nolock) 
   	order by w.SLCo, w.UserName, w.SL, w.SLItem

GO
GRANT SELECT ON  [dbo].[SLWIGrid] TO [public]
GRANT INSERT ON  [dbo].[SLWIGrid] TO [public]
GRANT DELETE ON  [dbo].[SLWIGrid] TO [public]
GRANT UPDATE ON  [dbo].[SLWIGrid] TO [public]
GO
