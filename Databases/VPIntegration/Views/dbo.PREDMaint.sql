SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     view [dbo].[PREDMaint]
   /***************************************
   *	Created by:		??
   *	Modified by:	EN 2/23/05 - added with (nolock)
   *	Used by:		form PRFileStat to return only deductions where method=Routine
   ****************************************/
    as select "PRCo" = e.PRCo, Employee, "DLCode" = e.DLCode, EmplBased, FileStatus, RegExempts,
     	AddExempts, OverMiscAmt, MiscAmt, MiscFactor, "GLCo" = e.GLCo, OverCalcs, OverLimit,
     	NetPayOpt, AddonType
     From PRED e with (nolock)
     join PRDL d with (nolock) on e.PRCo = d.PRCo and e.DLCode = d.DLCode
     where d.DLType = 'D' and d.Method = 'R'

GO
GRANT SELECT ON  [dbo].[PREDMaint] TO [public]
GRANT INSERT ON  [dbo].[PREDMaint] TO [public]
GRANT DELETE ON  [dbo].[PREDMaint] TO [public]
GRANT UPDATE ON  [dbo].[PREDMaint] TO [public]
GO
