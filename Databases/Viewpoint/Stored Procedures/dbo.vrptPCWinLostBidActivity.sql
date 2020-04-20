SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ====================================================================================                
-- Author:  Mike Brewer                      
-- Create date: 5/26/09                      
-- Description: This Procedure will be used for the PC Bid Tracking report.                      
-- ====================================================================================                      
CREATE PROCEDURE [dbo].[vrptPCWinLostBidActivity]                      
                      
(@Company bCompany,              
@BidJCDept  bDept,              
@BegBidDate datetime,              
@EndBidDate datetime,             
@BidStatus varchar (30),              
@BidResult varchar(30),             
@ProjectType varchar(10),          
@PrimeSub varchar(1))                      
                      
                      
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
--declare @BidStatus varchar (20)            
--set @BidStatus = ''          
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
        
-----------------------------------------------------------    
Begin    
 if  @BidJCDept = '' set @BidJCDept = Null      
End    
     
          
Begin            
 if  @BidStatus = '' set @BidStatus = Null            
end            
            
Begin            
 if  @BidResult = '' set @BidResult = Null            
end            
          
Begin            
 if  @ProjectType = '' set @ProjectType = Null            
end            
          
Begin            
 if  @PrimeSub = '' set @PrimeSub = Null            
end            
          
          
select     
@@rowcount as 'X',  
P.PotentialProject as  'PCPotentialProjectID',     
H.HQCo,               
H.Name,             
P.BidJCDept,          
P.BidStatus as 'Bid Status',               
D.DisplayValue as 'BidStatusDisplayValue',         
P.BidDate as 'Bid Date',          
P.BidNumber as 'BidNumber',            
P.ProjectType as 'Project Type',              
P.Description as 'Project Name',            
P.BidTotalPrice as 'Bid Price',          
P.BidProfit as 'Bid Gross Profit',          
P.BidMarkup as 'Markup %',          
P.BidMarkup * 100 as 'MarkupPercent',          
(select top 1 PT.ContactName from PCPotentialProjectTeam PT  
 where PT.PotentialProject = P.PotentialProject  
 and PT.JCCo = P.JCCo  
 and PT.ContactType = 'Client') as 'Client Name',  
P.BidEstimator as 'Estimator',            
isnull(JM.Name,P.BidEstimator) as 'EstimatorName',         
P.PrimeSub,          
P.BidResult,          
D2.DisplayValue as 'BidResultDisplay',   ------------------------------------------------------------        
isnull(P.Description,'') + ',   Bid Number: ' + isnull(P.BidNumber,'') as 'ProjectBidName',     
isnull(@BidJCDept,'') as 'BidJCDeptParam',            
@BegBidDate as 'BegBidDateParam' ,          
@EndBidDate as 'EndBidDate'          
--isnull(@BidStatus, '') as 'BidStatusParam',          
--isnull(@BidResult,'') as 'BidResultParam',          
--isnull(@ProjectType,'') as 'ProjectTypeParam',          
--isnull(@PrimeSub,'') as 'PrimeSubParam'            
FROM   HQCO H              
INNER JOIN PCPotentialWork P              
 ON H.HQCo=P.JCCo       
left JOIN JCDM J               
 ON P.JCCo=J.JCCo               
 AND P.BidJCDept =J.Department            
left join JCMP JM          
 on P.JCCo = JM.JCCo          
 and case when isnumeric(P.BidEstimator) = 1 then P.BidEstimator else null end = JM.ProjectMgr   
left join DDCI D              
 on  P.BidStatus = D.DatabaseValue              
 and 'PCBidStatus' = D.ComboType           
left join DDCI D2            
 on  P.BidResult = D2.DatabaseValue            
 and 'PCBidResult' = D2.ComboType            
WHERE                
P.JCCo=@Company               
AND (isnull(P.BidDate,'1950-01-01') >= @BegBidDate              
  AND isnull(P.BidDate,'2050-12-31') <= @EndBidDate)     
AND (@BidJCDept is Null or P.BidJCDept = @BidJCDept)    
AND (@BidStatus is Null or D.DisplayValue = @BidStatus)    --BidStatus        
AND (@BidResult is Null or D2.DisplayValue = @BidResult)  --BidResult        
AND (@ProjectType is Null or P.ProjectType = @ProjectType)            
AND (@PrimeSub is Null or P.PrimeSub = @PrimeSub)            
  
      
end   
  
  
  
  
GO
GRANT EXECUTE ON  [dbo].[vrptPCWinLostBidActivity] TO [public]
GO
