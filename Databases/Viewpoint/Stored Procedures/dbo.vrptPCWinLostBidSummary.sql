SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ====================================================================================                  
-- Author:  Mike Brewer                        
-- Create date: 5/26/09                        
-- Description: This Procedure will be used for the PC Bid Tracking report.                        
-- ====================================================================================                        
CREATE PROCEDURE [dbo].[vrptPCWinLostBidSummary]                        
                        
(@Company bCompany,                
@BidJCDept  bDept,                
@BegBidDate datetime,                
@EndBidDate datetime,               
@BidStatus varchar (30),                
@BidResult varchar(30),               
@ProjectType varchar(10),            
@PrimeSub varchar(1),  
@BidJCDeptFromMain bDept,  
@ProjectTypeFromMain varchar(10))                        
                        
                        
AS                        
BEGIN                        
 -- SET NOCOUNT ON added to prevent extra result sets from                        
 -- interfering with SELECT statements.                        
SET NOCOUNT ON;                        
                      
                
--declare @Company bCompany                
--set @Company = 1                
--                
--declare @BidJCDept  bDept                
--set @BidJCDept = ''                
--                
--declare @BegBidDate datetime                
--set @BegBidDate = '1950-01-01'                 
----set @BegBidDate = '2010-03-01'                
--                
--declare @EndBidDate datetime                
--set @EndBidDate = '2050-12-31'              
----set @EndBidDate = '2010-03-25'                
--                
--declare @BidStatus varchar (30)              
--set @BidStatus = 'I - Invitation to Bid Sent'            
--                
--                
--declare @BidResult varchar(20)            
--set @BidResult = ''          
--            
--declare @ProjectType varchar(10)            
--set @ProjectType = ''          
--   
--            
--declare @PrimeSub varchar(1)            
----set @PrimeSub = 'S'            
--set @PrimeSub = ''     
--  
--  
--declare @BidJCDeptFromMain bDept  
--set @BidJCDeptFromMain = 'All'--will come from main report  
--  
--declare @ProjectTypeFromMain varchar(10)  
--set @ProjectTypeFromMain = 'All'--will come from main report  
  
  
  
DECLARE @PCWinLostBidActivity table  
(X int null,  
PCPotentialProjectID varchar (20) null,  
HQCo bCompany null,                 
Name varchar(60) null,               
BidJCDept bDept null,        
BidStatus   varchar (20) null,              
DisplayValue      varchar(30) null,   
BidDate bDate null,  
BidNumber varchar(20) null,     
ProjectType varchar(10) null,               
ProjectName Varchar(60) null,       
BidPrice bDollar null,  
BidGrossProfit bDollar null,   
[Markup%] bPct null,         
MarkupPercent decimal(18,2) null,    
ClientName varchar(60) null,  
Estimator varchar(30) null,       
EstimatorName varchar(60) null,      
PrimeSub varchar(1) null,      
BidResult varchar(1) null,         
BidResultDisplay varchar(60) null,           
ProjectBidName varchar(110),     
BidJCDeptParam bDept null,           
BegBidDateParam bDate null,        
EndBidDate bDate null)  
  
  
  
  
insert into @PCWinLostBidActivity execute vrptPCWinLostBidActivity @Company, @BidJCDept,   
@BegBidDate,  @EndBidDate, @BidStatus, @BidResult, @ProjectType, @PrimeSub  
  
  
declare @BidProfitGT money          
declare @BidTotalPriceGT money          
declare @NumProjects decimal(12,2)   
  
  
   
--select ProjectType, BidJCDept, BidPrice, * from  @PCWinLostBidActivity    
  
----------------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------------  
  
  
  
if isnull(@BidJCDeptFromMain,'') <> 'All' and  isnull(@ProjectTypeFromMain,'') <> 'All'     
  
                       
Begin    
  
--check param values  
--select 'param values', @BidJCDeptFromMain as '@BidJCDeptFromMain', @ProjectTypeFromMain as '@ProjectTypeFromMain'  
  
  
select   
@BidTotalPriceGT = sum(isnull(BidPrice,0)),  
@NumProjects = count(PCPotentialProjectID)  
from @PCWinLostBidActivity  
where   
isnull(ProjectType,'') = @ProjectTypeFromMain  
and  isnull(BidJCDept,'') = @BidJCDeptFromMain  
  
  
  
  
--------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------  
select  
BidResultDisplay as 'BidResultDisplay',  
sum(BidPrice) as 'Total Bid Price',  
case sum(isnull(@BidTotalPriceGT,0)) when  0 then 0         
 else    (sum(isnull(BidPrice,0))/ isnull(@BidTotalPriceGT,0)) * 100 end as 'Total%',   
count(PCPotentialProjectID) as 'NumofProjects',   
case @NumProjects when  0 then 0         
 else (CAST(count(PCPotentialProjectID) AS dec(12,2))/ @NumProjects) * 100 end as '%ofProjects'  
from @PCWinLostBidActivity  
where   
 isnull(ProjectType, '') = @ProjectTypeFromMain  
 and isnull(BidJCDept,'') = @BidJCDeptFromMain  
group by BidResultDisplay  
  
End  
  
  
--------------------------------------------------------------------------------------  
  
if @BidJCDeptFromMain = 'All' and  @ProjectTypeFromMain = 'All'                          
Begin     
  
  
select   
@BidTotalPriceGT = sum(isnull(BidPrice,0)),  
@NumProjects = count(PCPotentialProjectID)  
from @PCWinLostBidActivity  
  
select  
BidResultDisplay as 'BidResultDisplay',  
sum(BidPrice) as 'Total Bid Price',  
case sum(isnull(@BidTotalPriceGT,0)) when  0 then 0         
 else    (sum(isnull(BidPrice,0))/ isnull(@BidTotalPriceGT,0)) * 100 end as 'Total%',   
count(PCPotentialProjectID) as 'NumofProjects',   
case @NumProjects when  0 then 0         
 else (CAST(count(PCPotentialProjectID) AS dec(12,2))/ @NumProjects) * 100 end as '%ofProjects'  
from @PCWinLostBidActivity  
group by BidResultDisplay  
  
End  
  
End
GO
GRANT EXECUTE ON  [dbo].[vrptPCWinLostBidSummary] TO [public]
GO
