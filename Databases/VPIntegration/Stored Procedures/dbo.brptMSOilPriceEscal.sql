SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================  
-- Author:   Mike Brewer  
-- Create date: 3/25/09  
-- Modified:    3/30/09  
-- Description: Used for MS Oil Price Esculation Report, Issue #132416  
--
--Maintenace Log
--	Date		ChangedBy	Issue	Description
--	11/22/09	C. Wirtz	135558	Change User Defined Data Type field definition from bDesc to bItemDesc
--									becasuse HQMT.Description expanded to 60 characters						
-- =============================================  
CREATE PROCEDURE [dbo].[brptMSOilPriceEscal]  
--   
  (@JCCo bCompany = 1,  
  @MSCo bCompany = 1,  
  @Customer bCustomer = 0,   
  @Job bJob ='',   
  @BeginDate bDate = '01/01/1950',  
  @EndDate bDate = '01/01/2050',  
  @CustomerJob varchar(20)= '',  
  @SaleType Varchar(1) = 'C')  
  
  
AS  
BEGIN  
--  SET NOCOUNT ON added to prevent extra result sets from  
--  interfering with SELECT statements.  
 SET NOCOUNT ON;  
--  
--DECLARE @JCCo bCompany   
--SET @JCCo = 1  
--  
--Declare @Job bJob   
--set @Job =''  
--  
--Declare @MSCo bCompany  
--set @MSCo = 1  
--  
--Declare @Customer bCustomer   
--set @Customer = 0  
--  
--declare @BeginDate bDate   
--set @BeginDate = '01/01/1950'  
--  
--declare @EndDate bDate   
--set @EndDate= '01/01/2050'  
--  
--Declare @CustomerJob varchar(20)  
--set @CustomerJob = ''  
--  
--Declare @SaleType Varchar(1)  
--set @SaleType = 'C'  
  
  
  
--Customer Job  
---------- ---  
--1   2  
--2   6  
--3   3  
--Null  4  
--Null  5  
  
  
--The report is set up this way so the end user can   
--select a range of Customers for the report, i.e. 1-2   
--and get just Customer 1 and 2. But if they leave blank   
--it should return all records (all jobs), even where Customer is Null.  
--Solution----  
--and (Customer = @Customer or @Customer =@defaultCustomer)  
--and (Job = @Job or @Job = @defaultJob)  
  
-----------------------------------------------------  
  
declare @defaultCustomer bCustomer   
set @defaultCustomer = 0  
  
  
declare @defaultJob bJob  
set @defaultJob = ''  
  
  
declare @defaultCustomerJob varchar(20)  
set @defaultCustomerJob = ''  
  
------------------------------------------------------  
  
---------------------------------------------------  
  
--Step 1  
--INBO Search  
--Make List of Matls common to both INBO and HQPM;   
--these are materials subject to Price Escalation,  
--insert them into @T1  
  
  
declare @T1 table  
(RN int IDENTITY(1,1),  
[%Weight]  decimal (10,4),  
FinMatl dbo.bMatl,  
CompMatl dbo.bMatl,  
[Description] dbo.bItemDesc,  
MatlGroup dbo.bMatl,  
[State] varchar(20),  
PriceIndex varchar(20))  
  
insert @T1  
select   
Case HQMT.WeightConv  
  When 0 then 0  
  When HQMTTwo.WeightConv     then INBO.Units*100  
  Else ((INBO.Units*HQMTTwo.WeightConv)/HQMT.WeightConv)*100  
End as '%Weight',    
INBO.FinMatl,   
INBO.CompMatl,  
--HQMTTwo.Description,   
HQMT.Description,   
HQMT.MatlGroup,  
H.State,   
H.PriceIndex  
FROM   INBO INBO   
left outer join HQMT HQMTTwo   
 ON INBO.MatlGroup=HQMTTwo.MatlGroup   
 AND INBO.CompMatl=HQMTTwo.Material   
inner join HQMT HQMT   
 ON INBO.MatlGroup=HQMT.MatlGroup   
 AND INBO.FinMatl=HQMT.Material   
inner join HQPM H  
 on  INBO.MatlGroup = H.MatlGroup  
 and INBO.FinMatl  =  H.FinishedMatl  
 and INBO.CompMatl =  H.ComponentMatl  
where INBO.INCo = @MSCo
  
------------------------------------------------------  
--INBM Search  
--Make List of Matls common to both INBM and HQPM;   
--these are materials subject to Price Escalation,  
--insert them into @T1  
  
insert @T1  
select   
Case HQMT.WeightConv  
  When 0 then 0  
  When HQMTTwo.WeightConv     then INBM.Units*100  
  Else ((INBM.Units*HQMTTwo.WeightConv)/HQMT.WeightConv)*100  
End as '%Weight',    
INBM.FinMatl,   
INBM.CompMatl,  
--HQMTTwo.Description,   
HQMT.Description,   
HQMT.MatlGroup,  
H.State,   
H.PriceIndex  
FROM   INBM INBM   
left outer join HQMT HQMTTwo   
 ON INBM.MatlGroup=HQMTTwo.MatlGroup   
 AND INBM.CompMatl=HQMTTwo.Material   
inner join HQMT HQMT   
 ON INBM.MatlGroup=HQMT.MatlGroup   
 AND INBM.FinMatl=HQMT.Material   
inner join HQPM H  
 on  INBM.MatlGroup = H.MatlGroup  
 and INBM.FinMatl  =  H.FinishedMatl  
 and INBM.CompMatl =  H.ComponentMatl 
where INBM.INCo = @MSCo 
  
  
------------------------------------------------------  
--Delete duplicate records from @T1  
--Since INBO is inserted first ( delete Not In, Min(RN) ) IMBM records will be deleted, leaving INBO  
DELETE  
FROM @T1  
WHERE RN NOT IN  
(  
SELECT MIN(RN)  
FROM @T1  
GROUP BY FinMatl, CompMatl, MatlGroup, [State],PriceIndex)  
  
------  
--select '@T1', * from @T1  
--End Step 1  
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
--Step 2  
--Build upon @T1  
--Find Sales of Materials subject to Price Esculation  
--  
  
if @SaleType = 'J'  
    Begin  
     declare @T2J table  
     (SaleType varchar(5),  
     Customer bCustomer Null,  
     CustomerName varchar (60) NULL,  
     MSCo int,  
     Job varchar(20),  
     SaleDate datetime,  
     Units decimal (15,4) NULL,  
     UM varchar(20) NULL,  
     [%Weight]  decimal (15,4) NULL,  
     FinMatl dbo.bMatl NULL,  
     CompMatl dbo.bMatl Null,  
     [Description] dbo.bItemDesc Null,  
     [State] varchar(20) NULL,  
     PriceIndex varchar(20) ,  
     BidIndexDate datetime)  
  
--J     --Find all Job MS Sales(SaleType = 'J' for Job) of materials   
     --that are subject to Price Escalation, materials listed in @T1  
     insert @T2J  
     SELECT   
     'Job',  
     CM.Customer as 'Customer',  
     ARCM.Name as 'CustomerName',  
     M.MSCo,  
     M.Job,  
     M.SaleDate,  
     M.MatlUnits,  
     M.UM,   
     T1.[%Weight],  
     T1.FinMatl,  
     T1.CompMatl,  
     T1.[Description],  
     T1.State,  
     T1.PriceIndex,  
     CM.StartMonth  
     FROM   dbo.MSTD M  
     join @T1 T1  
      on M.Material = T1.FinMatl  
      and M.MatlGroup = T1.MatlGroup  
      and (select ShipState from dbo.JCJM where JCCo = @JCCo and Job = M.Job) = T1.[State]  
     join JCJM J  
      on M.JCCo = J.JCCo  
      and M.Job = J.Job  
     join JCCM CM  
      on CM.JCCo = J.JCCo  
      and CM.Contract = J.Contract  
     left join ARCM ARCM  
      on CM.CustGroup = ARCM.CustGroup  
      and CM.Customer = ARCM.Customer  
     where M.SaleType = 'J'  
      and J.ApplyEscalators = 'Y'  
     and (M.SaleDate >= @BeginDate and M.SaleDate <= @EndDate)  
     and J.JCCo=@JCCo   
     and M.MSCo = @MSCo  
--J    
     --select '@T2', * from  @T2  
     ------------------------------------------------------  
     --Find all Customer MS Sales(SaleType = 'C' for Customer) of materials   
     --that are subject to Price Escalation, materials listed in @T1  
  
     --End Step 2  
     --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
     --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
     --Step 3  
     --Build on @T2  
     --Gather info about contracts involved, lookup PI and BI and calculate PIBI Ratio  
--J  
     declare @T3J table  
     (SaleType varchar(5),  
     Customer bCustomer Null,  
     CustomerName varchar (60) NULL,  
     MSCo int,  
     Job varchar(20),  
     [Contract] varchar (20),  
     Units decimal (15,4),  
     UM varchar(20),  
     [%Weight]  decimal(15,4),  
     FinMatl dbo.bMatl,  
     CompMatl dbo.bMatl,  
     [Description] dbo.bItemDesc,  
     [State] Varchar (2),  
     PriceIndex varchar(20),  
     SaleDate datetime,  
     BidIndexMonth datetime,  
     BidIndexDate datetime,  
     BI decimal (15,4),  
     [PI] decimal (15,4),  
     PIBIRatio decimal (15,4),  
     IncreaseOrDecrease varchar(15),  
     FactorToUse decimal(15,4),  
     PriceIndexDescrip varchar (15))  
--J  
     --Gather Data for Jobs  
     insert @T3J  
     select   
     T.SaleType,  
     T.Customer,  
     T.CustomerName,  
     T.MSCo,  
     JM.Job,   
     CM.Contract,  
     T.Units,  
     T.UM,  
     T.[%Weight],  
     T.FinMatl,  
     T.CompMatl,  
     T.[Description],  
     T.State,  
     T.PriceIndex,  
     T.SaleDate,  
     DateName( mm,T.BidIndexDate)+ ', ' + DateName(yy, T.BidIndexDate) as 'BidIndexMonth',  
     T.BidIndexDate as 'BidIndexDate',  
     H.EnglishPrice as 'BI',  
     H2.EnglishPrice as 'PI',  
     H2.EnglishPrice / H.EnglishPrice as 'PIBIRatio',  
     case when H2.EnglishPrice / H.EnglishPrice >= 1 then 'Increase' else 'Decrease' end as 'IncreaseOrDecrease',  
     CASE WHEN (H2.EnglishPrice / H.EnglishPrice) > (1 + H.Factor) THEN  (1 + H.Factor)  
       WHEN  (H2.EnglishPrice / H.EnglishPrice) < (1 - H.Factor) THEN (1 - H.Factor)  
     Else 0 End as 'FactorToUse',--0 if does not meet   
     (select left(HQPO.Description, 15) from HQPO where Country = H.Country and State = H.State and PriceIndex = H.PriceIndex) as 'PriceIndexDescrip'  
     from @T2J T  
     join JCJM JM   
      on T.MSCo = JM.JCCo  
      and T.Job = JM.Job  
      and T.SaleType = 'Job'  
     join JCCM CM  
      on CM.JCCo = JM.JCCo  
      and CM.Contract = JM.Contract  
     join dbo.HQPD  H   
      on T.State = H.State  
      and T.PriceIndex = H.PriceIndex  
      and CM.StartMonth Between H.FromDate and H.ToDate  
     left join dbo.HQPD  H2   
      on T.State = H2.State  
      and T.PriceIndex = H2.PriceIndex  
      and T.SaleDate Between H2.FromDate and H2.ToDate  
     where JM.JCCo=@JCCo   
       
--J     ----End Step 3  
     ----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
     ----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
     ----Step 4  
     ----Calculate PA, Contract days, Liquid Tons, ect  
     ----filter out records that don't meet MinDays and MinAmount requirements  
     declare @T4J table  
     (SaleType varchar(5),  
     MSCo int,  
     Customer bCustomer Null,  
     CustomerName varchar (60) NULL,  
     COName varchar(60),  
     Job varchar(20),  
     [Contract] varchar (20),  
     Units decimal (15,4),  
     UM varchar(20),  
     LiquidTons decimal(15,4),  
     [%Weight]  decimal(15,4),  
     FinMatl dbo.bMatl,  
     CompMatl dbo.bMatl,  
     [Description] dbo.bItemDesc,   
     [State] Varchar (2),  
     PriceIndex varchar(20),  
     SaleDate datetime,  
     SaleMonth varchar (20),  
     BidIndexMonth datetime,  
     BidIndexDate datetime,  
     BI decimal (15,4),  
     [PI] decimal (15,4),  
     PA decimal (20,4),  
     ContractDays decimal(15,4),  
     Mindays int,  
     MinAmt decimal(15,4),  
     PriceIndexDescrip varchar (15))  
--J    ------  
     insert @T4J  
     select   
     T3.SaleType,  
     T3.MSCo,  
     T3.Customer,  
     T3.CustomerName,  
     (select [Name] from HQCO where HQCo = T3.MSCo) as 'COName',  
     T3.Job,   
     T3.Contract,  
     T3.Units,  
     T3.UM,  
     T3.Units * T3.[%Weight]/100 as 'LiquidTons',  
     T3.[%Weight],  
     T3.FinMatl,  
     T3.CompMatl,  
     T3.[Description],  
     T3.State,  
     T3.PriceIndex,  
     T3.SaleDate,  
     DateName( mm,T3.SaleDate)+ ', ' + DateName(yy, T3.SaleDate) as 'SaleMonth',  
     T3.BidIndexMonth,  
     T3.BidIndexDate,  
     T3.BI,  
     T3.[PI],  
     --PA = (PI/BI - 1 + factor) * C * Q  
     --PA = (PI/BI -  factor) * C * Q  
     --C = ((T3.BI*T3.[%Weight])/100)  
     (T3.PIBIRatio - T3.FactorToUse) * (( T3.BI  *  T3.[%Weight]) /100) * (T3.Units) as 'PA',  
     Datediff(d, T3.BidIndexDate,T3.SaleDate) as 'Contractdays',  
     H.MinDays,   
     H.MinAmt,  
     T3.PriceIndexDescrip  
     from @T3J T3  
     join HQPD H  
      on T3.State = H.State  
      and T3.PriceIndex = H.PriceIndex  
      and T3.BidIndexDate >= H.FromDate and T3.BidIndexDate <= H.ToDate  
  
--J    --select '@T4', * from @T4   
  
     select    
     T4.SaleType,  
     T4.MSCo,  
     T4.Customer,  
     T4.CustomerName,  
     T4.COName,  
     T4.Job,   
     T4.Contract,  
     T4.Units,  
     T4.UM,  
     T4.LiquidTons,  
     T4.[%Weight],  
     T4.FinMatl,  
     T4.CompMatl,  
     T4.[Description],  
     T4.State,  
     T4.PriceIndex,  
     T4.SaleDate,  
     DATEADD(dd,-(DAY(T4.SaleDate)-1),T4.SaleDate) as 'SaleMonthDT',  
     T4.SaleMonth,  
     --T4.BidIndexMonth,  
     --T4.BidIndexDate,  
     T4.BI,  
     T4.[PI],  
     T4.PA,  
	 case when T4.Units = 0 then 0 else T4.PA/T4.Units end as 'Esculator',
     T4.ContractDays,  
     T4.Mindays,   
     T4.MinAmt,  
     T4.PriceIndexDescrip  
      from @T4J T4  
     where T4.ContractDays >= T4.Mindays   
     and ABS(T4.PA) >= MinAmt  
     and T4.SaleDate >= @BeginDate and T4.SaleDate <= @EndDate  
     and (Customer = @Customer or @Customer =@defaultCustomer)  
     and (Job = @Job or @Job = @defaultJob)  
--J  
    End  
 Else  
    Begin  
--C  
     declare @T2C table  
     (SaleType varchar(5),  
     Customer bCustomer Null,  
     CustomerName varchar (60) NULL,  
     MSCo int,  
     Job varchar(20),  
     SaleDate datetime,  
     Units decimal (15,4) NULL,  
     UM varchar(20) NULL,  
     [%Weight]  decimal (15,4) NULL,  
     FinMatl dbo.bMatl NULL,  
     CompMatl dbo.bMatl Null,  
     [Description] dbo.bItemDesc Null,   
     [State] varchar(20) NULL,  
     PriceIndex varchar(20) ,  
     BidIndexDate datetime)  
  
    --select '@T2', * from  @T2  
  
     ------------------------------------------------------  
     --Find all Customer MS Sales(SaleType = 'C' for Customer) of materials   
--C     --that are subject to Price Escalation, materials listed in @T1  
  
     insert @T2C  
     select   
     'MST',  
     MC.Customer as 'Customer',  
     ARCM.Name as 'CustomerName',  
     MC.MSCo,  
     MC.CustJob,  
     MC.SaleDate,  
     MC.MatlUnits,  
     MC.UM,   
     T1.[%Weight],  
     T1.FinMatl,  
     T1.CompMatl,  
     T1.[Description],  
     T1.State,  
     T1.PriceIndex,  
     Q.BidIndexDate  
     from   
     (select M.*,    
      isnull(Q.State,  
      (select BillState from ARCM where Customer = M.Customer and CustGroup = M.CustGroup )) as 'State2'  
      from MSTD M  
      join (Select distinct FinMatl, MatlGroup from @T1) as x  
       on M.Material = x.FinMatl  
       and M.MatlGroup = x.MatlGroup  
      join MSQH Q  
       on M.MSCo = Q.MSCo   
         and M.Customer = Q.Customer  
         and M.CustGroup = Q.CustGroup  
         and isnull(M.CustJob,'') = isnull(Q.CustJob, '')   
         and isnull(M.CustPO, '') = isnull(Q.CustPO, '')   
      where M.SaleType = 'C'  
      and (M.SaleDate >= @BeginDate and M.SaleDate <= @EndDate)) AS MC  
     join @T1 T1  
      on MC.Material = T1.FinMatl  
      and MC.MatlGroup = T1.MatlGroup  
      and MC.State2 = T1.[State]  
     join MSQH Q  
      on MC.MSCo = Q.MSCo   
        and MC.Customer = Q.Customer  
        and MC.CustGroup = Q.CustGroup  
        and isnull(MC.CustJob,'') = isnull(Q.CustJob, '')   
        and isnull(MC.CustPO, '') = isnull(Q.CustPO, '')   
     left join ARCM ARCM  
      on Q.CustGroup = ARCM.CustGroup  
      and Q.Customer = ARCM.Customer  
     where Q.QuoteType = 'C'  
      and MC.SaleType = 'C'  
     and Q.ApplyEscalators = 'Y'  
     and (MC.SaleDate >= @BeginDate and MC.SaleDate <= @EndDate)  
     and MC.MSCo = @MSCo  
--C     --  
     --select '@T2', * from  @T2  
  
     --End Step 2  
     --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
     --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
     --Step 3  
     --Build on @T2  
--C     --Gather info about contracts involved, lookup PI and BI and calculate PIBI Ratio  
  
     declare @T3C table  
     (SaleType varchar(5),  
     Customer bCustomer Null,  
     CustomerName varchar (60) NULL,  
     MSCo int,  
     Job varchar(20),  
     [Contract] varchar (20),  
     Units decimal (15,4),  
     UM varchar(20),  
     [%Weight]  decimal(15,4),  
     FinMatl dbo.bMatl,  
     CompMatl dbo.bMatl,  
     [Description] dbo.bItemDesc,   
     [State] Varchar (2),  
     PriceIndex varchar(20),  
     SaleDate datetime,  
     BidIndexMonth datetime,  
     BidIndexDate datetime,  
     BI decimal (15,4),  
     [PI] decimal (15,4),  
     PIBIRatio decimal (15,4),  
     IncreaseOrDecrease varchar(15),  
     FactorToUse decimal(15,4),  
     PriceIndexDescrip varchar (15))  
  
     --Gather data about Customer Sales  
--C     ----  
     insert @T3C  
     select   
     'MST',  
     T.Customer,  
     T.CustomerName,  
     T.MSCo,  
     T.Job,  
     Null as [Contract],  
     T.Units,  
     T.UM,  
     T.[%Weight],  
     T.FinMatl,  
     T.CompMatl,  
     T.[Description],  
     T.State,  
     T.PriceIndex,  
     T.SaleDate,  
     DateName( mm,T.BidIndexDate)+ ', ' + DateName(yy, T.BidIndexDate) as 'BidIndexMonth',  
     T.BidIndexDate as 'BidIndexDate',  
     H.EnglishPrice as 'BI',  
     H2.EnglishPrice as 'PI',  
     ----------  
     --Ratio of PI to BI  
     --if (PI / BI) > 1 then Price Increase else Price decrease  
     H2.EnglishPrice / H.EnglishPrice as 'PIBIRatio',   
     case when H2.EnglishPrice / H.EnglishPrice >= 1 then 'Increase' else 'Decrease' end as 'IncreaseOrDecrease',  
     -------------------------  
     --was increase (decrease) larger or less than Factor  
     --if increase (decrese) > than Factor then use factor else use 0  
     CASE WHEN (H2.EnglishPrice / H.EnglishPrice) >= (1 + H.Factor) THEN  (1 + H.Factor)    
       WHEN  (H2.EnglishPrice / H.EnglishPrice) <= (1 - H.Factor) THEN (1 - H.Factor)  
     Else 1 End as 'FactorToUse',--0 if does not meet   
     (select left(HQPO.Description, 15) from HQPO where Country = H.Country and State = H.State and PriceIndex = H.PriceIndex) as 'PriceIndexDescrip'  
     from @T2C T  
     join dbo.HQPD  H   
      on T.State = H.State  
      and T.PriceIndex = H.PriceIndex  
        and T.BidIndexDate Between H.FromDate and H.ToDate  
     left join dbo.HQPD  H2   
      on T.State = H2.State  
      and T.PriceIndex = H2.PriceIndex  
      and T.SaleDate Between H2.FromDate and H2.ToDate  
     where T.SaleType = 'MST'  
--C     --  
     --select '@T3', T3.* from @T3 T3  
     --  
     ----End Step 3  
     ----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
     ----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
     ----Step 4  
     ----Calculate PA, Contract days, Liquid Tons, ect  
     ----filter out records that don't meet MinDays and MinAmount requirements  
     declare @T4C table  
     (SaleType varchar(5),  
     MSCo int,  
     Customer bCustomer Null,  
     CustomerName varchar (60) NULL,  
     COName varchar(60),  
     Job varchar(20),  
     [Contract] varchar (20),  
     Units decimal (15,4),  
     UM varchar(20),  
     LiquidTons decimal(15,4),  
     [%Weight]  decimal(15,4),  
     FinMatl dbo.bMatl,  
     CompMatl dbo.bMatl,  
     [Description] dbo.bItemDesc,
     [State] Varchar (2),  
     PriceIndex varchar(20),  
     SaleDate datetime,  
     SaleMonth varchar (20),  
     BidIndexMonth datetime,  
     BidIndexDate datetime,  
     BI decimal (15,4),  
     [PI] decimal (15,4),  
     PA decimal (20,4),  
     ContractDays decimal(15,4),  
     Mindays int,  
     MinAmt decimal(15,4),  
     PriceIndexDescrip varchar (15))  
--C     ------  
     insert @T4C  
     select   
     T3.SaleType,  
     T3.MSCo,  
     T3.Customer,  
     T3.CustomerName,  
     (select [Name] from HQCO where HQCo = T3.MSCo) as 'COName',  
     T3.Job,   
     T3.Contract,  
     T3.Units,  
     T3.UM,  
     T3.Units * T3.[%Weight]/100 as 'LiquidTons',  
     T3.[%Weight],  
     T3.FinMatl,  
     T3.CompMatl,  
     T3.[Description],  
     T3.State,  
     T3.PriceIndex,  
     T3.SaleDate,  
     DateName( mm,T3.SaleDate)+ ', ' + DateName(yy, T3.SaleDate) as 'SaleMonth',  
     T3.BidIndexMonth,  
     T3.BidIndexDate,  
     T3.BI,  
     T3.[PI],  
     --PA = (PI/BI - 1 + factor) * C * Q  
     --PA = (PI/BI -  factor) * C * Q  
     --C = ((T3.BI*T3.[%Weight])/100)  
     (T3.PIBIRatio - T3.FactorToUse) * (( T3.BI  *  T3.[%Weight]) /100) * (T3.Units) as 'PA',  
     Datediff(d, T3.BidIndexDate,T3.SaleDate) as 'Contractdays',  
     H.MinDays,   
     H.MinAmt,  
     T3.PriceIndexDescrip  
     from @T3C T3  
     join HQPD H  
      on T3.State = H.State  
      and T3.PriceIndex = H.PriceIndex  
      and T3.BidIndexDate >= H.FromDate and T3.BidIndexDate <= H.ToDate  
  
--C     --select '@T4', * from @T4   
  
     select    
     T4.SaleType,  
     T4.MSCo,  
     T4.Customer,  
     T4.CustomerName,  
     T4.COName,  
     T4.Job,   
     T4.Contract,  
     T4.Units,  
     T4.UM,  
     T4.LiquidTons,  
     T4.[%Weight],  
     T4.FinMatl,  
     T4.CompMatl,  
     T4.[Description],  
     T4.State,  
     T4.PriceIndex,  
     T4.SaleDate,  
     DATEADD(dd,-(DAY(T4.SaleDate)-1),T4.SaleDate) as 'SaleMonthDT',  
     T4.SaleMonth,  
     T4.BI,  
     T4.[PI],  
     T4.PA,  
	 case when T4.Units = 0 then 0 else T4.PA/T4.Units end as 'Esculator',
     T4.ContractDays,  
     T4.Mindays,   
     T4.MinAmt,  
     T4.PriceIndexDescrip  
     from @T4C T4  
     where T4.ContractDays >= T4.Mindays   
     and ABS(T4.PA) >= MinAmt  
     and T4.SaleDate >= @BeginDate and T4.SaleDate <= @EndDate  
     and (Customer = @Customer or @Customer =@defaultCustomer)  
--     and (Job = @Job or @Job = @defaultJob)  
     and (Job = @CustomerJob or @CustomerJob = @defaultCustomerJob)  
--C  
    End  
  

--  
End  
  
  
  
  
  
GO
GRANT EXECUTE ON  [dbo].[brptMSOilPriceEscal] TO [public]
GO
