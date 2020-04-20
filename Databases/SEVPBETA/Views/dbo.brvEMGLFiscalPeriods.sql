SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvEMGLFiscalPeriods] as select EMCO.EMCo, EMCO.GLCo, GLMth=GLFP.Mth, GLFP.FiscalPd, GLFP.FiscalYr, GLFY.BeginMth, GLFY.FYEMO
     from EMCO
     join GLFP on GLFP.GLCo=EMCO.GLCo
     join GLFY on GLFY.GLCo=GLFP.GLCo and GLFP.Mth between GLFY.BeginMth and GLFY.FYEMO

GO
GRANT SELECT ON  [dbo].[brvEMGLFiscalPeriods] TO [public]
GRANT INSERT ON  [dbo].[brvEMGLFiscalPeriods] TO [public]
GRANT DELETE ON  [dbo].[brvEMGLFiscalPeriods] TO [public]
GRANT UPDATE ON  [dbo].[brvEMGLFiscalPeriods] TO [public]
GO
