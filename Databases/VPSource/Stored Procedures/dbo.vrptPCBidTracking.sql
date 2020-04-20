SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ====================================================================================              
-- Author:  Mike Brewer                    
-- Create date: 5/26/09                    
-- Description: This Procedure will be used for the PC Bid Tracking report.                    
-- ====================================================================================                    
CREATE PROCEDURE [dbo].[vrptPCBidTracking]                    
                    
(@Company bCompany,            
@BidJCDept  bDept,            
@BegBidDate datetime,            
@EndBidDate datetime,            
@BidStatus varchar (30),            
@BidEstimator varchar (30),            
@PlansOrdered varchar(1),            
@BidSubmitted varchar(1))                    
                    
      
                    
AS                    
BEGIN                    
 -- SET NOCOUNT ON added to prevent extra result sets from                    
 -- interfering with SELECT statements.                    
SET NOCOUNT ON;                    
                  
        
--declare @Company bCompany            
--set @Company = 1            
--            
--declare @BidJCDept  bDept            
--set @BidJCDept = '01'            
--            
--declare @BegBidDate datetime            
--set @BegBidDate = '1950-01-01'             
----set @BegBidDate = '2010-01-01'            
--            
--declare @EndBidDate datetime            
--set @EndBidDate = '2050-12-31'            
----set @EndBidDate = '2010-12-31'            
--            
--declare @BidStatus varchar (30)            
--set @BidStatus = 'I - Invitation to Bid Sent'    
--            
--declare @BidEstimator varchar (30)        
--set @BidEstimator = Null            
----set @BidEstimator = 5        
--            
--declare @PlansOrdered varchar(1)            
--set  @PlansOrdered = 'N'            
--            
--declare @BidSubmitted varchar(1)               
--set @BidSubmitted = 'N'            
          
Begin          
 if  @BidStatus = '' set @BidStatus = Null          
end          
          
Begin          
 if  @BidEstimator = '' set @BidEstimator = Null          
end          
          
Begin        
 if @BidJCDept = '' set @BidJCDept = Null        
End        
    
Begin     
 if @BegBidDate = '1950-01-01' set @BegBidDate = Null    
End    
        
Begin     
 if @EndBidDate =  '2050-12-31' set @EndBidDate = Null    
End    
    
        
            
SELECT             
H.HQCo,             
H.Name,             
P.BidDate,             
P.Description,             
P.PotentialProject,             
P.BidNumber,             
P.ProjectSize,             
P.ProjectValue,             
P.BidPlanOrdered,             
P.BidPlanReceived,             
P.BidStarted,             
P.BidSubmitted,             
P.BidResult,             
D2.DisplayValue as 'BidResultDisplay',            
P.BidPreMeeting,             
P.BidEstimator as 'BidEstimatorName',            
P.BidJCDept,             
P.ProjectType,             
J.Description as 'JCDepartDescription',             
P.BidStatus,             
D.DisplayValue as 'BidStatusDisplayValue',            
P.JCCo            
FROM   HQCO H            
INNER JOIN PCPotentialWork P            
 ON H.HQCo=P.JCCo             
left JOIN JCDM J             
 ON P.JCCo=J.JCCo             
 AND P.BidJCDept =J.Department            
left join DDCI D            
 on  P.BidStatus = D.DatabaseValue            
 and 'PCBidStatus' = D.ComboType            
left join DDCI D2            
 on  P.BidResult = D2.DatabaseValue            
 and 'PCBidResult' = D2.ComboType          
--left join JCMP JP        
-- on P.JCCo = JP.JCCo        
-- and P.ProjectMgr = JP.ProjectMgr        
WHERE              
P.JCCo=@Company             
AND (@BegBidDate is Null or P.BidDate >= @BegBidDate)        
AND (@EndBidDate is Null or P.BidDate <= @EndBidDate)        
AND (@BidJCDept is Null or P.BidJCDept = @BidJCDept)              
AND (@BidEstimator is Null or P.BidEstimator = @BidEstimator)            
AND (@BidStatus is Null or D.DisplayValue = @BidStatus)     
              
--if @PlansOrdered = N show all (including Nulls), if Y show only BidsSubmitted less than today's date            
and (isnull(P.BidPlanOrdered,'2050-12-31') <= case             
     when @PlansOrdered = 'Y' then   getdate()             
     else  isnull(P.BidPlanOrdered,'2050-12-31')  end)            
            
--if @PlansOrdered = N show all (including Nulls), if Y show only BidsSubmitted less than today's date            
and (isnull(P.BidSubmitted,'2050-12-31') <= case             
     when @BidSubmitted = 'Y' then   getdate()             
     else  isnull(P.BidSubmitted,'2050-12-31')  end)        
ORDER BY             
P.ProjectType,             
P.BidJCDept,             
P.BidEstimator,             
P.BidDate     
  
  
  
            
End 




GO
GRANT EXECUTE ON  [dbo].[vrptPCBidTracking] TO [public]
GO
