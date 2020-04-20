SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   View [dbo].[brvMSQuotes] As
     select MSCo, Quote, Type='D',Seq, LocGroup, Loc, MatlGroup, Category, UM, PayDiscRate
     From MSDX
     union
     select MSCo, Quote, Type='H', FromLoc, Zone, NULL, NULL, NULL, NULL, NULL From MSZD

GO
GRANT SELECT ON  [dbo].[brvMSQuotes] TO [public]
GRANT INSERT ON  [dbo].[brvMSQuotes] TO [public]
GRANT DELETE ON  [dbo].[brvMSQuotes] TO [public]
GRANT UPDATE ON  [dbo].[brvMSQuotes] TO [public]
GRANT SELECT ON  [dbo].[brvMSQuotes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvMSQuotes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvMSQuotes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvMSQuotes] TO [Viewpoint]
GO
