SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.POIBGrid
AS
SELECT     TOP (100) PERCENT dbo.POIB.*
FROM         dbo.POIB WITH (nolock)
ORDER BY Co, Mth, BatchId, BatchSeq, POItem

GO
GRANT SELECT ON  [dbo].[POIBGrid] TO [public]
GRANT INSERT ON  [dbo].[POIBGrid] TO [public]
GRANT DELETE ON  [dbo].[POIBGrid] TO [public]
GRANT UPDATE ON  [dbo].[POIBGrid] TO [public]
GO
