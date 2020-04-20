SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[brvPRDL_APCO] as select PRDL.*,APCo=PRCO.APCo From PRDL
      left outer join PRCO on
         PRDL.PRCo = PRCO.PRCo

GO
GRANT SELECT ON  [dbo].[brvPRDL_APCO] TO [public]
GRANT INSERT ON  [dbo].[brvPRDL_APCO] TO [public]
GRANT DELETE ON  [dbo].[brvPRDL_APCO] TO [public]
GRANT UPDATE ON  [dbo].[brvPRDL_APCO] TO [public]
GO
