SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- ====================================================================================    
-- Author:  Dan Koslicki          
-- Create date: 5/31/10
-- Issue #: 138735          
-- Description: This Procedure will be used for the PC Bid Swing report.      
-- Test Run: EXEC vrptPCBidSwing 1,'','1950-01-01','2050-12-31','','','',''

-- ====================================================================================  

CREATE PROCEDURE [dbo].[vrptPCBidSwing]        
        
(@Company		bCompany,
@BidJCDept		bDept,
@BegBidDate		DATETIME,
@EndBidDate		DATETIME,
@BidStatus		VARCHAR(20),
@BidPrimeSub	VARCHAR(1),
@Competitor		VARCHAR(30),
@ProjectType	VARCHAR(10))        
        
AS        
BEGIN        
-- SET NOCOUNT ON added to prevent extra result sets from        
-- interfering with SELECT statements.        
SET NOCOUNT ON;        
      

--DECLARE @Company bCompany
--SET		@Company = 1

--DECLARE @BidJCDept  bDept
--SET		@BidJCDept = '01'

--DECLARE @BegBidDate DATETIME
--SET		@BegBidDate = '1950-01-01' 
----SET		@BegBidDate = '2010-01-01'

--DECLARE @EndBidDate DATETIME
--SET		@EndBidDate = '2050-12-31'
----SET		@EndBidDate = '2010-12-31'

--DECLARE @BidStatus VARCHAR(20)
--SET		@BidStatus = ''

--DECLARE @ProjectType VARCHAR(10)
--SET		@ProjectType = ''			-- Testing values: NULL, 'Casino'

--DECLARE @BidPrimeSub VARCHAR(1)
--SET		@BidPrimeSub = ''			-- Testing values: NULL, 'P', 'S'

--DECLARE @Competitor VARCHAR(30)
--SET		@Competitor = '';			-- Testing values: NULL, 'BIDCO Construction'


-- CTE used to calculate BidSwingAmount and AssumedCompetitorMarkupPercent 
-- for reuse when calulating the SwingPercent
WITH PCBidDetail (HQCo, 
				Name, 
				BidDate, 
				Description, 
				PotentialProject, 
				BidNumber, 
				BidStarted, 
				BidSubmitted, 
				Estimator, 
				BidJCDept, 
				ProjectType, 
				JCDepartDescription, 
				BidStatus, 
				BidStatusDisplayValue,
				JCCo,
				PrimeSub,
				PrimeSubDisplayValue,
				BidTotalCost,
				BidTotalPrice, 
				BidProfit,
				BidMarkup,
				Competitor,
				CompetitorBid,
				BidSwingAmount,
				AssumedCompetitorMarkupPercent)

AS (
SELECT 
	HQCo				= H.HQCo, 
	Name				= H.Name, 
	BidDate				= P.BidDate, 
	Description			= P.Description, 
	PotentialProject	= P.PotentialProject, 
	BidNumber			= P.BidNumber,
	BidStarted			= P.BidStarted, 
	BudSubmitted		= P.BidSubmitted,  
	Estimator			= P.BidEstimator, 
	BidJCDept			= P.BidJCDept, 
	ProjectType			= P.ProjectType, 
	JCDepartDescription = J.Description, 
	BidStatus			= P.BidStatus, 
	BidStatusDisplayValue = D.DisplayValue,
	JCCo				= P.JCCo,
	PrimeSub			= P.PrimeSub,
	PrimeSubDisplayValue = CASE ISNULL(P.PrimeSub,'')
							WHEN '' THEN ''
							WHEN 'P' THEN 'Prime'
							WHEN 'S' THEN 'Sub'
							ELSE ''
							END,
	BidTotalLCost		= P.BidTotalCost,
	BidTotalPrice		= P.BidTotalPrice, 
	BidProfit			= P.BidProfit,
	BidMarkup			= ISNULL(P.BidMarkup,0),		-- Percentage as decimal
	Competitor			= P.Competitor,
	CompetitorBid		= P.CompetitorBid,
	BidSwingAmount		= ISNULL(P.CompetitorBid,0) - ISNULL(P.BidTotalCost,0),
	AssumedCompetitorMarkupPercent = CASE ISNULL(P.CompetitorBid,0)  -- Percentage as decimal
										WHEN 0 THEN 0
										ELSE (ISNULL(P.CompetitorBid,0) - ISNULL(P.BidTotalCost,0)) / P.CompetitorBid END

	FROM   HQCO H

	INNER JOIN	PCPotentialWork P
			ON	P.JCCo = H.HQCo
			AND	P.JCCo = @Company
			AND	(@ProjectType IS NULL OR @ProjectType = '' OR P.ProjectType = @ProjectType)
			AND (P.BidDate IS NOT NULL AND P.BidDate >= @BegBidDate)
			AND (P.BidDate IS NOT NULL AND P.BidDate <= @EndBidDate)
			AND (@BidJCDept IS NULL OR @BidJCDept = '' OR P.BidJCDept = @BidJCDept)
			AND (@BidStatus IS NULL OR @BidStatus = '' OR P.BidStatus = @BidStatus)
			AND (@BidPrimeSub IS NULL OR @BidPrimeSub = '' OR P.PrimeSub = @BidPrimeSub)
			AND (@Competitor IS NULL OR @Competitor = '' OR P.Competitor = @Competitor)
			
		
	LEFT JOIN	JCDM J 
			ON	J.JCCo = P.JCCo
			AND J.Department = P.BidJCDept
	
	--LEFT JOIN	JCMP JM
	--		ON	JM.JCCo = P.JCCo 
	--		AND JM.ProjectMgr = P.BidEstimator 

	LEFT JOIN DDCI D						-- Join to get the Bid Status Display Value
			ON  D.DatabaseValue = P.BidStatus 
			AND D.ComboType = 'PCBidStatus'

	LEFT JOIN DDCI D2						-- JOin to get the Bid Result Display Value
			ON  D2.DatabaseValue = P.BidResult 
			AND D2.ComboType = 'PCBidResult'
	)

SELECT	PB.HQCo, 
		PB.Name, 
		PB.BidDate, 
		PB.Description, 
		PB.PotentialProject, 
		PB.BidNumber, 
		PB.BidStarted, 
		PB.Estimator, 
		PB.BidJCDept, 
		PB.ProjectType, 
		PB.JCDepartDescription, 
		PB.BidStatusDisplayValue,
		PB.JCCo,
		PB.PrimeSub,
		PB.PrimeSubDisplayValue,
		PB.BidTotalCost,
		PB.BidTotalPrice, 
		PB.BidProfit,
		PB.BidMarkup,
		PB.Competitor,
		PB.CompetitorBid,
		PB.BidSwingAmount,
		PB.AssumedCompetitorMarkupPercent,
		[SwingPercent] = PB.AssumedCompetitorMarkupPercent - PB.BidMarkup
		
FROM	PCBidDetail PB						-- CTE Definition created begins above

ORDER BY 
		PB.PrimeSub,
		PB.ProjectType,   
		PB.BidJCDept,   
		PB.Estimator,
		PB.BidDate,
		PB.BidStatus

END



GO
GRANT EXECUTE ON  [dbo].[vrptPCBidSwing] TO [public]
GO
