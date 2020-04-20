SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[HRBIMAIN] as
     /******************************************
     * Used by HR BenefitCodes to fill grid
     * by ae 11/17/99
     *
     *******************************************/
   Select 'EDLType' = d.EDLType, 'EDLCode' = d.EDLCode, 'PRDLDesc1' = c1.Description, 'PRDLDesc2' = c2.Description,'PREDDesc' = c3.Description
   from HRBI d
   Left Join PRDL c1 on d.HRCo = c1.PRCo and d.EDLCode = c1.DLCode and   d.EDLType = 'D'
   Left Join PRDL c2 on d.HRCo = c2.PRCo and d.EDLCode = c2.DLCode and   d.EDLType = 'L'
   Left Join PREC c3 on d.HRCo = c3.PRCo and d.EDLCode = c3.EarnCode and d.EDLType = 'E'

GO
GRANT SELECT ON  [dbo].[HRBIMAIN] TO [public]
GRANT INSERT ON  [dbo].[HRBIMAIN] TO [public]
GRANT DELETE ON  [dbo].[HRBIMAIN] TO [public]
GRANT UPDATE ON  [dbo].[HRBIMAIN] TO [public]
GO
