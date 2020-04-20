SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[brvPREC_PhsGrp] as select PREC.*, HQCO.PhaseGroup from PREC
      left outer join HQCO 
        on PREC.PRCo = HQCO.HQCo

GO
GRANT SELECT ON  [dbo].[brvPREC_PhsGrp] TO [public]
GRANT INSERT ON  [dbo].[brvPREC_PhsGrp] TO [public]
GRANT DELETE ON  [dbo].[brvPREC_PhsGrp] TO [public]
GRANT UPDATE ON  [dbo].[brvPREC_PhsGrp] TO [public]
GRANT SELECT ON  [dbo].[brvPREC_PhsGrp] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPREC_PhsGrp] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPREC_PhsGrp] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPREC_PhsGrp] TO [Viewpoint]
GO
