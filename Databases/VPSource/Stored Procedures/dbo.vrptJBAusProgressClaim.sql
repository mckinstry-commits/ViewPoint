SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
--==========================================================                                                
--Author:  Mike Brewer                                                
--Create date: 10/08/2010                                                
--Issue:133404   AU Progress Claim Certificate                                          
--This procedure is used by ***** report.   updated 10/13/2010  5:46                                     
                                      
--==========================================================                                                          
CREATE PROCEDURE  [dbo].[vrptJBAusProgressClaim]                                                             
                                                            
--Declare Parameters            
            
(@Company bCompany,            
@ProcessingGroup Varchar (20),            
            
@BegBillNumber int,            
@EndBillNumber int,            
            
@Invoice varchar(10),            
            
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
--declare @Invoice varchar(10)            
--            
--declare @BegBillMonth bMonth            
--declare @EndBillMonth bMonth         
           
--Set Parameter Values            
            
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
----set @BegInvoice = '       105'            
----set @EndInvoice = '       105'            
--            
--set @BegBillMonth = '2010-06-01'            
--set @EndBillMonth = '2010-06-01'            
            
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
End;            
            
--Begin            
--     if @BegInvoice is null set @BegInvoice = ' '---???            
--end            
--            
--Begin            
--     if @EndInvoice is null set @BegInvoice = 'zzzzzzzzz'            
--end;            
------------------------------------------------------------            
--Items            
            
          
            
with JBItems_CTE            
as            
(select            
JBIN.JBCo,            
JBIN.BillMonth,            
JBIN.ProcessGroup,            
JBIS.Contract,            
JBIS.Job,            
JBIN.Invoice,            
JBIN.Application,            
JBIN.ToDate,            
JBIN.InvDate,            
JBIN.BillNumber,            
JBIS.ACO,            
JBIS.ACOItem,            
JBIS.Item,            
Sum(JBIS.CurrContract) as 'CurrContract',            
Sum(JBIS.PrevWC) as 'PrevWC',            
Sum(JBIS.PrevAmt) as 'PrevAmt',             
Sum(JBIS.WC) as 'WC',            
Sum(JBIS.PrevSM + JBIS.SM) as 'StoredMaterial',            
Sum(JBIS.SM) as 'ThisClaimSM',            
Sum(JBIS.AmtBilled) as 'AmtBilled',             
Sum(JBIS.ChgOrderAmt) as 'ChgOrderAmt',            
Sum(JBIS.AmtBilled + JBIS.PrevAmt) as 'WorkInPlace',            
Sum(JBIS.WCRetg + JBIS.SMRetg) as 'Retain',            
Sum(   (JBIS.PrevRetg - JBIS.PrevRetgReleased)   +   (JBIS.RetgBilled - JBIS.RetgRel)   ) as 'RetainfromAIA'            
from JBIN--JB Bill Header            
INNER JOIN  JBIS--JB Items and Change Orders        
     ON JBIS.JBCo=JBIN.JBCo            
     AND JBIS.BillMonth=JBIN.BillMonth            
     AND JBIS.BillNumber=JBIN.BillNumber            
where             
--params            
JBIN.JBCo = @Company            
and (JBIN.ProcessGroup = @ProcessingGroup or @ProcessingGroup IS NULL)            
and (JBIN.BillNumber >= @BegBillNumber AND JBIN.BillNumber <= @EndBillNumber)             
and (JBIN.Invoice = @Invoice)            
and (JBIN.BillMonth >= isnull(@BegBillMonth, '1950-01-01') and JBIN.BillMonth <= isnull(@EndBillMonth,'2050-12-31') )          
--check            
and (isnull(JBIS.ACO, '') = '' and isnull(JBIS.ACOItem,'') = '')--Item will not have ACO or ACO Item values            
Group by JBIN.JBCo, JBIN.BillMonth, JBIN.ProcessGroup, JBIS.Contract, JBIS.Job,            
JBIN.Invoice, JBIN.Application, JBIN.ToDate, JBIN.InvDate,            
JBIN.BillNumber, JBIS.ACO, JBIS.ACOItem, JBIS.Item ),            
            
Items            
as            
             
(select             
'ContractItems' as 'RecordType',            
JBItems_CTE.ProcessGroup,            
JBItems_CTE.Invoice,            
JBItems_CTE.Contract,            
JBItems_CTE.Job,            
JCJMPM.Project,            
JBItems_CTE.Application,            
JBItems_CTE.ToDate,            
JBItems_CTE.InvDate,            
JBItems_CTE.BillNumber,            
JBItems_CTE.ACO,            
JBItems_CTE.ACOItem,            
JBItems_CTE.BillMonth,            
JCCI.Item as 'Item No.',            
JCCI.Description,            
JCCI.ContractAmt  as 'Contract Value',            
JBItems_CTE.PrevWC as 'Previously Claimed',--D            
case when JCCI.ContractAmt = 0 then 0 else ((JBItems_CTE.PrevWC/JCCI.ContractAmt) * 100 )end as 'Previous %',            
JBItems_CTE.WC as 'Work Complete This Claim',--E            
--JBItems_CTE.WC + JBItems_CTE.ThisClaimSM as ''            
JBItems_CTE.StoredMaterial as 'Material Presently Stored',--F            
JBItems_CTE.WorkInPlace as 'Total Completed and Stored to Date',--G            
case when JCCI.ContractAmt = 0 then 0 else (((JBItems_CTE.AmtBilled + JBItems_CTE.PrevAmt)/ JCCI.ContractAmt) * 100 )end as 'Total % Complete',            
JBItems_CTE.ThisClaimSM as 'This Claim SM',            
--JBItems_CTE.WorkInPlace - JBItems_CTE.PrevWC as 'This Claim',--10  old 
JBItems_CTE.WC +  JBItems_CTE.ThisClaimSM as 'This Claim',         
JBItems_CTE.Retain as 'Retainage',            
JBItems_CTE.AmtBilled as 'AmtBilled',            
JBItems_CTE.PrevAmt as 'PrevAmt'            
from JCCI--Contract Items            
join JBItems_CTE            
     ON JCCI.JCCo=JBItems_CTE.JBCo             
     AND JCCI.Item=JBItems_CTE.Item             
     AND JCCI.Contract=JBItems_CTE.Contract             
left join JCJMPM            
 on  JCCI.JCCo = JCJMPM.JCCo            
 and JCCI.Contract = JCJMPM.Contract            
WHERE              
--params            
JCCI.JCCo=@Company            
and (JBItems_CTE.ProcessGroup = @ProcessingGroup or @ProcessingGroup IS NULL)            
and (JBItems_CTE.BillNumber >= @BegBillNumber AND JBItems_CTE.BillNumber <= @EndBillNumber)            
and (JBItems_CTE.Invoice = @Invoice)             
and (JBItems_CTE.BillMonth >= isnull(@BegBillMonth, '1950-01-01') and JBItems_CTE.BillMonth <= isnull(@EndBillMonth,'2050-12-31') )          
--check            
and JCCI.OrigContractAmt > 0--Item will have Orig Contract Amount, ACO will not            
),            
            
            
-------------------------------------------------------------------            
-------------------------------------------------------------------            
-------------------------------------------------------------------            
-------------------------------------------------------------------            
-------------------------------------------------------------------            
--Change Orders            
            
JBACO_CTE            
as            
(select             
JBIN.JBCo,            
JBIN.BillMonth,            
JBIN.ProcessGroup,            
JBIS.Contract,            
JBIN.Invoice,            
JBIS.Job,            
JBIN.Application,            
JBIN.ToDate,             
JBIN.InvDate,            
JBIN.BillNumber,            
JBIS.ACO,            
JBIS.ACOItem,            
JBIS.Item,            
Sum(JCCI.ContractAmt) as 'CurrContract',            
Sum(JBIS.PrevWC) as 'PrevWC',            
Sum(JBIS.PrevAmt) as 'PrevAmt',             
Sum(JBIS.WC) as 'WC',            
Sum(JBIS.PrevSM + JBIS.SM) as 'StoredMaterial',            
Sum(JBIS.SM) as 'ThisClaimSM',            
Sum(JBIS.AmtBilled) as 'AmtBilled',             
Sum(JBIS.ChgOrderAmt) as 'ChgOrderAmt',            
Sum(JBIS.AmtBilled + JBIS.PrevAmt) as 'WorkInPlace',            
Sum(JBIS.WCRetg + JBIS.SMRetg) as 'Retain'            
from JBIN--JB Bill Header            
INNER JOIN  JBIS--JB Items and Change Orders            
     ON JBIS.JBCo=JBIN.JBCo            
     AND JBIS.BillMonth=JBIN.BillMonth            
     AND JBIS.BillNumber=JBIN.BillNumber            
join JCCI--Job Cost Contract Item            
     on JBIS.JBCo = JCCI.JCCo            
     and JBIS.Contract = JCCI.Contract            
     and JBIS.Item = JCCI.Item              
where             
--params            
JBIN.JBCo = @Company            
and (JBIN.ProcessGroup = @ProcessingGroup or @ProcessingGroup IS NULL)            
and (JBIN.BillNumber >= @BegBillNumber AND JBIN.BillNumber <= @EndBillNumber)             
and (JBIN.Invoice = @Invoice)        
and (JBIN.BillMonth >= isnull(@BegBillMonth, '1950-01-01') and JBIN.BillMonth <= isnull(@EndBillMonth,'2050-12-31') )          
--Check            
and JCCI.OrigContractAmt = 0 -- if 0 then Change Order, if > 0 then it is Contract Item            
Group by JBIN.JBCo, JBIN.BillMonth, JBIN.ProcessGroup, JBIS.Contract,             
JBIN.Invoice, JBIS.Job, JBIN.Application, JBIN.ToDate, JBIN.InvDate,            
JBIN.BillNumber, JBIS.ACO, JBIS.ACOItem, JBIS.Item)            
            
            
select            
RecordType,            
ProcessGroup,            
Invoice,      
RTrim(LTrim(Invoice)),        
Contract,            
Job as 'Job No.',            
Project,            
Application as 'Application No.',            
ToDate as 'Application To',             
InvDate as 'Application Date',            
BillNumber,            
ACO,            
ACOItem,            
BillMonth,            
RTrim(LTrim([Item No.])) as 'Item No.',--1            
Description,--2            
[Contract Value],--3            
[Previously Claimed],--4            
[Previous %],--5            
[Work Complete This Claim],--6            
[Material Presently Stored],--7            
[Total Completed and Stored to Date],--8            
[Total % Complete],--9            
[This Claim SM],--10            
[This Claim],--11            
Retainage,--12            
AmtBilled,            
PrevAmt            
from Items            
            
Union All            
            
select             
'ChangeOrders' as 'RecordType',            
JBACO_CTE.ProcessGroup,            
JBACO_CTE.Invoice,    
JBACO_CTE.Invoice as 'Invoice No.',          
JBACO_CTE.Contract,            
JBACO_CTE.Job as 'Job No.',            
JCJMPM.Project,            
JBACO_CTE.Application as 'Application No.',            
JBACO_CTE.ToDate as 'Application To',            
JBACO_CTE.InvDate as 'Application Date',            
JBACO_CTE.BillNumber,            
JBACO_CTE.ACO,            
JBACO_CTE.ACOItem,            
JBACO_CTE.BillMonth,            
RTrim(LTrim(JCCI.Item)) as 'Item No.',--1            
JCCI.Description,--2            
JBACO_CTE.CurrContract  as 'Contract Value',--3            
JBACO_CTE.PrevWC as 'Previously Claimed',--4            
case when JBACO_CTE.CurrContract = 0 then 0 else ((JBACO_CTE.PrevWC/JBACO_CTE.CurrContract) * 100 ) end as 'Previous %',--5            
JBACO_CTE.WC as 'Work Completed This Claim',--6            
JBACO_CTE.StoredMaterial as 'Material Presently Stored',--7            
JBACO_CTE.WorkInPlace as 'Total Completed and Stored to Date',--8            
case when JBACO_CTE.CurrContract = 0 then 0 else (((JBACO_CTE.AmtBilled + JBACO_CTE.PrevAmt)/ JBACO_CTE.CurrContract) * 100) end as 'Total % Complete',--9            
JBACO_CTE.ThisClaimSM as 'This Claim SM',--10  
--JBACO_CTE.WorkInPlace - JBACO_CTE.PrevWC as 'This Claim',--11   old
JBACO_CTE.WC +  JBACO_CTE.ThisClaimSM as 'This Claim SM',--10  
JBACO_CTE.Retain as 'Retainage',--12            
JBACO_CTE.AmtBilled as 'AmtBilled',            
JBACO_CTE.PrevAmt as 'PrevAmt'            
--JBACO_CTE.CurrContract - (JBACO_CTE.AmtBilled + JBACO_CTE.PrevAmt) as 'Balance To Finish'            
from JCCI--Contract Items            
join JBACO_CTE            
     ON JCCI.JCCo=JBACO_CTE.JBCo             
     AND JCCI.Item=JBACO_CTE.Item             
     AND JCCI.Contract=JBACO_CTE.Contract             
left join JCJMPM            
 on  JCCI.JCCo = JCJMPM.JCCo            
 and JCCI.Contract = JCJMPM.Contract            
WHERE              
--Params            
JCCI.JCCo=@Company            
and (JBACO_CTE.ProcessGroup = @ProcessingGroup or @ProcessingGroup IS NULL)            
and (JBACO_CTE.BillNumber >= @BegBillNumber AND JBACO_CTE.BillNumber <= @EndBillNumber)            
and (JBACO_CTE.Invoice = @Invoice)        
and (JBACO_CTE.BillMonth >= isnull(@BegBillMonth, '1950-01-01') and JBACO_CTE.BillMonth <= isnull(@EndBillMonth,'2050-12-31') )           
--check            
and (isnull(JBACO_CTE.ACO, '') = '' and isnull(JBACO_CTE.ACOItem,'') = '')--Change Order will have values for ACO and ACO Item   
GO
GRANT EXECUTE ON  [dbo].[vrptJBAusProgressClaim] TO [public]
GO
