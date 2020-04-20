SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[vrvPRCanT4Ver] AS   
  
Select src = 'EE'  
, EES.PRCo  
, EES.TaxYear  
, EES.Employee  
, EES.FirstName  
, EES.LastName  
, EEP.Province  
, EEP.Wages  
, EEP.Tax  
, Null as PRGroup  
, '12/31/2050' as PREndDate  
, Null as PaySeq  
, EDLType = case when EEP.Wages is not null then 'E' else 'D' end
, '9999' as EDLCode  
, Null as EDLDescription 
, EER.Province as DLProv 
, EER.DednCode as ProvDLCode  
, EER.Description as ProvDLCodeDescription  
, Null as Amount  
, Null as EligibleAmt
, '12/31/2050' as PaidDate 
, Null as CMRef 
FROM PRCAEmployees EES  
  
JOIN PRCAEmployeeProvince EEP  
 on EES.PRCo=EEP.PRCo  
 and EES.TaxYear=EEP.TaxYear  
 and EES.Employee=EEP.Employee  
JOIN PRCAEmployerProvince EER
 on EES.PRCo=EER.PRCo
 and EES.TaxYear=EER.TaxYear
 and EEP.Province=EER.Province
  
UNION  
  
Select src = 'PR'  
, PRDT.PRCo  
, TaxYear = Year(PRSQ.PaidDate)  
, PRDT.Employee  
, EES.FirstName  
, EES.LastName  
, Null as Province  
, Null as Wages  
, Null as Tax  
, PRDT.PRGroup  
, PRDT.PREndDate  
, PRDT.PaySeq  
, PRDT.EDLType  
, PRDT.EDLCode  
, EDLDescription = case when PRDT.EDLType in ('D') then PRDL.Description else PREC.Description end
, EER.Province as DLProv   
, EER.DednCode as ProvDLCode  
, EER.Description as ProvDLCodeDescription  
, PRDT.Amount  
, PRDT.EligibleAmt
, PRSQ.PaidDate 
, PRSQ.CMRef 
FROM PRDT  
  
left outer JOIN PRSQ PRSQ  
 on PRDT.PRCo=PRSQ.PRCo  
 and PRDT.PRGroup=PRSQ.PRGroup  
 and PRDT.PREndDate=PRSQ.PREndDate   
 and PRDT.Employee=PRSQ.Employee  
 and PRDT.PaySeq=PRSQ.PaySeq  
JOIN PRCAEmployees EES  
 on PRDT.PRCo=EES.PRCo  
 and PRDT.Employee=EES.Employee 
left outer Join PRCAEmployerProvince EER
 on PRDT.PRCo = EER.PRCo
 and PRDT.EDLCode=EER.DednCode
left outer join PRDL PRDL  
 on PRDT.PRCo=PRDL.PRCo  
 and PRDT.EDLType=PRDL.DLType  
 and PRDT.EDLCode=PRDL.DLCode  
left outer JOIN PREC PREC  
 on PRDT.PRCo=PREC.PRCo  
 and PRDT.EDLCode=PREC.EarnCode  
 
where 
PRSQ.PaidDate is not null 
and ((PRDT.EDLType='D' and EER.DednCode=PRDT.EDLCode))
--or (PRDT.EDLType='E'))


--Select src = 'EProv'  
--, EES.PRCo  
--, EES.TaxYear  
--, EES.Employee  
--, EES.FirstName  
--, EES.LastName  
--, EEP.Province  
--, EEP.Wages  
--, Null as Tax --EEP.Tax  
--, Null as PRGroup  
--, '12/31/2050' as PREndDate  
--, Null as PaySeq  
--, 'E' as EDLType 
--, Null as EDLCode  
--, Null as EDLDescription 
--, EER.Province as DLProv 
--, EER.DednCode as ProvDLCode  
--, EER.Description as ProvDLCodeDescription  
--, Null as Amount  
--, '12/31/2050' as PaidDate 
--, Null as CMRef 
--FROM PRCAEmployees EES  
  
--JOIN PRCAEmployeeProvince EEP  
-- on EES.PRCo=EEP.PRCo  
-- and EES.TaxYear=EEP.TaxYear  
-- and EES.Employee=EEP.Employee  
--JOIN PRCAEmployerProvince EER
-- on EES.PRCo=EER.PRCo
-- and EES.TaxYear=EER.TaxYear
-- and EEP.Province=EER.Province
  
--UNION  
  
--Select src = 'D'  
--, PRDT.PRCo  
--, TaxYear = Year(PRSQ.PaidDate)  
--, PRDT.Employee  
--, EES.FirstName  
--, EES.LastName  
--, Null as Province  
--, Null as Wages  
--, EEP.Tax 
--, PRDT.PRGroup  
--, PRDT.PREndDate  
--, PRDT.PaySeq  
--, PRDT.EDLType  
--, PRDT.EDLCode  
--, EDLDescription = case when PRDT.EDLType in ('D') then PRDL.Description else PREC.Description end
--, EER.Province as DLProv   
--, EER.DednCode as ProvDLCode  
--, EER.Description as ProvDLCodeDescription  
--, PRDT.Amount  
--, PRSQ.PaidDate 
--, PRSQ.CMRef 
--FROM PRDT  
  
--left outer JOIN PRSQ PRSQ  
-- on PRDT.PRCo=PRSQ.PRCo  
-- and PRDT.PRGroup=PRSQ.PRGroup  
-- and PRDT.PREndDate=PRSQ.PREndDate   
-- and PRDT.Employee=PRSQ.Employee  
-- and PRDT.PaySeq=PRSQ.PaySeq  
--JOIN PRCAEmployees EES  
-- on PRDT.PRCo=EES.PRCo  
-- and PRDT.Employee=EES.Employee 
--left outer Join PRCAEmployerProvince EER
-- on PRDT.PRCo = EER.PRCo
-- and PRDT.EDLCode=EER.DednCode
--left outer join PRDL PRDL  
-- on PRDT.PRCo=PRDL.PRCo  
-- and PRDT.EDLType=PRDL.DLType  
-- and PRDT.EDLCode=PRDL.DLCode  
--left outer JOIN PREC PREC  
-- on PRDT.PRCo=PREC.PRCo  
-- and PRDT.EDLCode=PREC.EarnCode  
 
--where 
--PRSQ.PaidDate is not null 
--and ((PRDT.EDLType='D' and EER.DednCode=PRDT.EDLCode)
--or (PRDT.EDLType='E'))

GO
GRANT SELECT ON  [dbo].[vrvPRCanT4Ver] TO [public]
GRANT INSERT ON  [dbo].[vrvPRCanT4Ver] TO [public]
GRANT DELETE ON  [dbo].[vrvPRCanT4Ver] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRCanT4Ver] TO [public]
GRANT SELECT ON  [dbo].[vrvPRCanT4Ver] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPRCanT4Ver] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPRCanT4Ver] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPRCanT4Ver] TO [Viewpoint]
GO
