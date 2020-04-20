SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   VIEW [dbo].[UDVHLookup]
    AS
    SELECT DISTINCT ValProc
    FROM         dbo.UDVH

GO
GRANT SELECT ON  [dbo].[UDVHLookup] TO [public]
GRANT INSERT ON  [dbo].[UDVHLookup] TO [public]
GRANT DELETE ON  [dbo].[UDVHLookup] TO [public]
GRANT UPDATE ON  [dbo].[UDVHLookup] TO [public]
GO
