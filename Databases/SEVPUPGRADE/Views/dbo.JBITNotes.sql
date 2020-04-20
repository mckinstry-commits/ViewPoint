SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************************************
   * Created: ?? ??/??/??: Issue #_____, Unknown
   * Modified: TJL 03/01/05:  Issue #26761, Add this Remarks area
   *		
   *
   * Provides a view for JB Progress Bill Items (JBIT) that fills a grid on
   * the JB Progress Bill Items form.
   *
   *
   **************************************************************************/ 
    
   CREATE view [dbo].[JBITNotes] as select JBIT.JBCo, JBIT.BillMonth, JBIT.BillNumber, JBIT.Item, JBIT.Notes
   from JBIT

GO
GRANT SELECT ON  [dbo].[JBITNotes] TO [public]
GRANT INSERT ON  [dbo].[JBITNotes] TO [public]
GRANT DELETE ON  [dbo].[JBITNotes] TO [public]
GRANT UPDATE ON  [dbo].[JBITNotes] TO [public]
GO
