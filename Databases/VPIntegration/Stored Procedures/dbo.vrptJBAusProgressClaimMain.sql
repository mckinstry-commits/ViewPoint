SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
--==========================================================                                              
--Author:  Mike Brewer                                              
--Create date: 10/08/2010                                              
--Issue:133404   AU Progress Claim Certificate                                        
--This procedure is used by ***** report.                                      
                                    
--==========================================================                                                        
CREATE PROCEDURE  [dbo].[vrptJBAusProgressClaimMain]                                                           
                                                          
        
--Declare Parameters          
          
(@Company bCompany,          
@ProcessingGroup Varchar (20),          
          
@BegBillNumber int,          
@EndBillNumber int,          
          
@BegInvoice varchar(10),          
@EndInvoice varchar(10),          
          
@BegBillMonth bMonth,          
@EndBillMonth bMonth)          
          
  as         
------------------------------------------------------------          
--declare @Company bCompany          
--declare @ProcessingGroup Varchar (20)          
--          
--declare @BegBillNumber int          
--declare @EndBillNumber int          
--          
--declare @BegInvoice varchar(10)          
--declare @EndInvoice varchar(10)          
--          
--declare @BegBillMonth bMonth          
--declare @EndBillMonth bMonth      
--      
--      
--      
----Set Parameter Values          
--          
--Set @Company = 204          
--          
----set @ProcessingGroup = Null          
--set @ProcessingGroup = ''          
--          
--set @BegBillNumber = 1          
--set @EndBillNumber = 1          
--          
--set @BegInvoice = ' '          
--set @EndInvoice = 'zzzzzzzzz'          
--          
--set @BegInvoice = '       103'          
--set @EndInvoice = '       103'          
--          
--set @BegBillMonth = '2010-05-01'          
--set @EndBillMonth = '2010-05-01'          
          
------------------------------------------------------------          
--Update empty params          
Begin              
 if  @ProcessingGroup = '' set @ProcessingGroup = Null                
End              
          
Begin              
 if  @BegBillNumber is Null set @BegBillNumber = 0             
End            
--          
Begin              
 if  @EndBillNumber is Null set @EndBillNumber = 999999999             
End            
          
Begin          
     if @BegInvoice is null set @BegInvoice = ' '---???          
end          
          
Begin          
     if @EndInvoice is null set @EndInvoice = 'zzzzzzzzz'          
end;          
        
SELECT        
HQCO.HQCo,        
HQCO.Name,        
JBIN.JBCo,        
JBIN.ProcessGroup,        
JBIN.BillNumber,        
JBIN.Invoice,      
JCJMPM.Job,      
JBIN.BillMonth,        
LTrim(RTrim(JBIN.Invoice)) as 'Invoice No',--38        
JCCM.Contract + ' ' + JCCM.Description as 'Project',  --5        
JBIN.Application as 'Application No',--1        
JCCM.Contract as 'Contract',--4        
ARCM.Name as 'Application To',--2        
JBIN.InvDate as 'Application Date',--5        
'We hereby Blah blah blah ' + Convert(varchar,(JBIN.InvDue - JBIN.InvTax + JBIN.InvTax),2) + ' blah blah blah' as 'We Herby',--16        
JBIN.InvTotal + JBIN.PrevAmt as 'Value of Contract',--9        
(JBIN.PrevRetg - JBIN.PrevRRel) +  (JBIN.InvRetg - JBIN.RetgRel) as 'Less Retention', --10        
(JBIN.InvTotal + JBIN.PrevAmt) - ((JBIN.PrevRetg - JBIN.PrevRRel) +  (JBIN.InvRetg - JBIN.RetgRel)) as 'Total', --11        
JBIN.PrevDue - JBIN.PrevTax as 'Less Previous Payments', --12        
JBIN.InvDue - JBIN.InvTax as 'Grand Total',--13        
JBIN.InvTax as 'GST',--14        
JBIN.InvDue - JBIN.InvTax + JBIN.InvTax as 'Amount Now Applied for',--16        
(JBIN.CurrContract + JBIN.ChgOrderAmt)- ((JBIN.InvTotal + JBIN.PrevAmt)- ((JBIN.PrevRetg - JBIN.PrevRRel) +  (JBIN.InvRetg - JBIN.RetgRel))) as 'Balance to Finish'        
FROM   dbo.JBIN JBIN         
INNER JOIN dbo.ARCM ARCM         
 ON JBIN.CustGroup=ARCM.CustGroup         
 AND JBIN.Customer=ARCM.Customer         
--INNER JOIN dbo.brvJCContrMinJob brvJCContrMinJob         
-- ON JBIN.JBCo=brvJCContrMinJob.JCCo         
-- AND JBIN.Contract=brvJCContrMinJob.Contract         
LEFT OUTER JOIN dbo.HQCO HQCO         
 ON JBIN.JBCo=HQCO.HQCo         
--LEFT OUTER JOIN dbo.JBCC JBCC         
-- ON JBIN.JBCo=JBCC.JBCo         
-- AND JBIN.BillMonth=JBCC.BillMonth         
-- AND JBIN.BillNumber=JBCC.BillNumber         
LEFT OUTER JOIN dbo.JCCM JCCM         
 ON JBIN.JBCo=JCCM.JCCo         
 AND JBIN.Contract=JCCM.Contract         
--LEFT OUTER JOIN dbo.PMFM PMFM         
-- ON brvJCContrMinJob.VendorGroup=PMFM.VendorGroup         
-- AND brvJCContrMinJob.ArchEngFirm=PMFM.FirmNumber       
left join JCJMPM              
 on  JCCM.JCCo = JCJMPM.JCCo              
 and JCCM.Contract = JCJMPM.Contract       
where JBIN.JBCo = @Company          
and (JBIN.ProcessGroup = @ProcessingGroup or @ProcessingGroup IS NULL)          
and (JBIN.BillNumber >= @BegBillNumber AND JBIN.BillNumber <= @EndBillNumber)           
and (JBIN.Invoice >= @BegInvoice and JBIN.Invoice <= @EndInvoice)          
--and ((isnull(JBIN.BillMonth,'1950-01-01') >= @BegBillMonth and isnull(JBIN.BillMonth,'2050-12-31') <= @EndBillMonth) ) 
and (JBIN.BillMonth >= isnull(@BegBillMonth, '1950-01-01') and JBIN.BillMonth <= isnull(@EndBillMonth,'2050-12-31')	)     
GO
GRANT EXECUTE ON  [dbo].[vrptJBAusProgressClaimMain] TO [public]
GO
