SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[JBIDGrid] as select JBCo, BillMonth, BillNumber, Line, Seq, Source, CostType,
           Category, Description, UM, Units, UnitPrice, ECM, Hours,
           SubTotal, MarkupTotal, Total
    from JBID


GO
GRANT SELECT ON  [dbo].[JBIDGrid] TO [public]
GRANT INSERT ON  [dbo].[JBIDGrid] TO [public]
GRANT DELETE ON  [dbo].[JBIDGrid] TO [public]
GRANT UPDATE ON  [dbo].[JBIDGrid] TO [public]
GO
