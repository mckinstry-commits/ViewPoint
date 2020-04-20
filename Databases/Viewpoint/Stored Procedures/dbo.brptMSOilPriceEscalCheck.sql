SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================  
-- Author:   Mike Brewer  
-- Create date: 3/25/09  
-- Modified:    3/30/09  
-- Description: Used for MS Oil Price Esculation Report, Issue #132416  
-- =============================================  
CREATE PROCEDURE [dbo].[brptMSOilPriceEscalCheck]  
------   
  (	@JCCo bCompany = 1,  
	@MSCo bCompany = 1)  
----  
----  
AS  
BEGIN  
--  SET NOCOUNT ON added to prevent extra result sets from  
--  interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
--  
--DECLARE @JCCo bCompany   
--SET @JCCo = 1  
--  
--  
--Declare @MSCo bCompany  
--set @MSCo = 1  
  
  
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
Country varchar (2),  
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
H.Country,  
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
H.Country,  
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
GROUP BY [%Weight], FinMatl, CompMatl, [Description], MatlGroup, [State], Country, PriceIndex)  
  
  
select  
'Material' as 'Section',  
T.[State] as 'State',  
T.Country,  
Null as 'Customer',  
'' as 'CustomerName',  
'' as 'Job',  
'' as 'JobDescription',  
Null as 'BidIndexdate',  
'' as 'ApplyEscalators',  
Null as 'CurrentContractDays',  
'' as 'Contract',  
'' as 'Qoute',  
'' as 'QouteDescription',  
T.MatlGroup,  
T.FinMatl,  
T.CompMatl,  
T.[Description],  
T.[%Weight] as '%Weight',  
T.PriceIndex,  
(select left(HQPO.Description, 15) from HQPO where Country = T.Country and State = T.State and PriceIndex = T.PriceIndex) as 'PriceIndexDescrip',  
	(	select H.MinDays   
		from  
		(	select Max(ToDate) as 'ToDate', State, Country, PriceIndex from dbo.HQPD  H   
			group by State, Country, PriceIndex) as x  
		join HQPD H  
			on  x.PriceIndex = H.PriceIndex  
			and x.State = H.State  
			and x.ToDate = H.ToDate  
			and x.Country = H.Country  
	  where x.PriceIndex = T.PriceIndex  
	  and x.State = T.[State]  
	  and x.Country = T.Country ) as 'MinDays',  
@JCCo as 'JCCo',  
@MSCo  as 'MSCo'  
from @T1 T  


--select * from HQPO
--select * from HQPD
  
--select * from INBO
  
Union all  
  
SELECT   
'Job' as 'Section',  
J.ShipState as 'State',  
'' as 'Country',  
CM.Customer as 'Customer',  
ARCM.Name as 'CustomerName',  
J.Job,  
J.Description as 'Job Description',  
CM.StartMonth as 'BidIndexdate',  
J.ApplyEscalators,  
Datediff(d, CM.StartMonth,getDate()) as 'CurrentContractDays',  
CM.Contract,  
'' as 'Quote',  
'' as 'QouteDescription',  
'' as 'MatlGroup',  
'' as 'FinMatl',  
'' as 'CompMatl',  
'' as 'Description',  
0 as '%Weight',  
'' as 'PriceIndex',  
'' as 'PriceIndexDescrip',  
0 as 'MinDays',  
@JCCo as 'JCCo',  
@MSCo  as 'MSCo'  
from JCJM J  
join JCCM CM  
	on CM.JCCo = J.JCCo  
	and CM.Contract = J.Contract  
left join ARCM ARCM  
	on CM.CustGroup = ARCM.CustGroup  
	and CM.Customer = ARCM.Customer  
where J.JCCo=@JCCo   
and J.ApplyEscalators = 'Y'  
  
Union All  
  
select   
'Quote' as 'Section',  
isnull(MSQH.State, A.BillState) as 'State',  
'' as 'Country',  
A.Customer,  
A.Name as 'CustomerName',  
'' as 'Job',  
'' as 'JobDescription',  
MSQH.BidIndexDate,  
MSQH.ApplyEscalators,  
Datediff(d, MSQH.BidIndexDate,Getdate()) as 'CurrentContractDays',  
'' as 'Contract',  
MSQH.Quote,  
MSQH.Description as 'QouteDescription',  
'' as 'MatlGroup',  
'' as 'FinMatl',  
'' as 'CompMatl',  
'' as 'Description',  
0 as '%Weight',  
'' as 'PriceIndex',  
'' as 'PriceIndexDescrip',  
0 as 'MinDays',  
@JCCo as 'JCCo',    
@MSCo as 'MSCo'  
from MSQH  
join ARCM A  
	on A.CustGroup = MSQH.CustGroup  
	and A.Customer = MSQH.Customer  
where MSQH.MSCo = @MSCo  
and MSQH.QuoteType = 'C'  
and MSQH.ApplyEscalators = 'Y'  
  
End  
  
  
  
  
  
GO
GRANT EXECUTE ON  [dbo].[brptMSOilPriceEscalCheck] TO [public]
GO
