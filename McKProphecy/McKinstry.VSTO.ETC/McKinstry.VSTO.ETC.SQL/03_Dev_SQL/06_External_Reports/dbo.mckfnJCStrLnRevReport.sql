USE [ViewpointTraining]
GO
/****** Object:  UserDefinedFunction [dbo].[mckfnJCStrLnRevReport]    Script Date: 10/12/2016 12:15:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Jonathan Ziebell
-- Create date: 02/12/2016
-- Description:	Straight Line Revenue Recognition Report
-- Update Hist: USER-----------DESC
-- 02/22/2016   J.Ziebell      Added GL Department and Name To Report 
-- 03/07/2016   J.Ziebell      Add GL Deparmtment to Parameter List, BO Classification to output
-- 05/17/2016   J.Ziebell      LTrim added to Contract Join of JCCM, remove Department Join to JCCM
-- 10/05/2016   J.Ziebell      Convert to WIP Archive 3 and include PRG Description
-- =============================================
ALTER FUNCTION [dbo].[mckfnJCStrLnRevReport] 
(
      @Month         SMALLDATETIME
	, @Company       TINYINT
	, @Department    VARCHAR(10)
	, @GLDepartment    VARCHAR(10)
	, @Contract      VARCHAR(10)
	, @ContractStat  TINYINT
	, @POC           VARCHAR(50)
)
RETURNS TABLE 
AS
RETURN 
WITH mckJCStrLnRev_Table (
	ThroughMonth			
	, JCCo					
	, Contract			
	, ContractDesc
	, PRG
	, PRGDescription	
	--, ContractItem	
	--, ContractIemDesc
	--, ContractItemNotes	
    , ContractStatusDesc 		
	, StrLineTermStart			
    , StraightLineTerm_Months	
	, StrLineTermEnd	
	, RemainingMonths			
	, RevenueTypeName          
    , Department 
	, GLDepartment
	, GLDepartmentName            
	--, POC						
	, POCName
	, VerticalMarket
	, BOClass					
	, OrigContractAmt			
	, CurrContractAmt			
	, ProjContractAmt			
	, FinalProjectedAmt			
	--, OriginalCost				
	--, ProjectedCost	
	--, FinalProjectedCost	
	, ProjectMargin
	, ProjectMarginPct
	, PrevMTDEarnedRev
	, CurrentMthRev		
	, TotalEarnedRevenue
	)
AS
	(SELECT
		WIPA.ThroughMonth
		, WIPA.JCCo
		, WIPA.Contract
		, WIPA.ContractDesc
		, WIPA.PRGNumber
		, WIPA.PRGDescription
		--, 'X' AS ContractItem
		--, 'X' AS ContractIemDesc
		--, 'X' AS ContractItemNotes
		, WIPA.ContractStatusDesc
		, WIPA.StrLineTermStart
		, WIPA.StrLineTerm AS StraightLineTerm_Months
		, (DATEADD(MONTH,(WIPA.StrLineTerm -1),WIPA.StrLineTermStart)) AS StrLineTermEnd
		, CASE WHEN (WIPA.ThroughMonth < WIPA.StrLineTermStart) THEN WIPA.StrLineTerm
			   WHEN (WIPA.ThroughMonth = WIPA.StrLineTermStart) THEN (WIPA.StrLineTerm - 1)
			   WHEN ((WIPA.ThroughMonth > WIPA.StrLineTermStart) 
					AND ((DATEDIFF(Month, WIPA.StrLineTermStart, WIPA.ThroughMonth)) < (WIPA.StrLineTerm))) THEN (WIPA.StrLineTerm - ((DATEDIFF(Month, WIPA.StrLineTermStart, WIPA.ThroughMonth))+1))
			   ELSE 0
			   END AS RemainingMonths
		, WIPA.RevenueTypeName
		, WIPA.Department
		, WIPA.GLDepartment
		, WIPA.GLDepartmentName
		--, WIPA.POC
		, WIPA.POCName
		, WIPA.VerticalMarket
		, BO.Description	
		, WIPA.OrigContractAmt
		, WIPA.CurrContractAmt
		, WIPA.ProjContractAmt
		, WIPA.RevenueWIPAmount AS FinalProjectedAmt
		--, CASE WHEN (WIPA.ProjContractAmt <> 0 ) Then WIPA.ProjContractAmt
		--	   WHEN (WIPA.CurrContractAmt <> 0 ) Then WIPA.CurrContractAmt
		--	   ELSE WIPA.OrigContractAmt 
		--	   END AS FinalProjectedAmt
		--, WIPA.OriginalCost
		--, WIPA.ProjectedCost
		--, CASE WHEN (WIPA.ProjectedCost <> 0 ) Then WIPA.ProjectedCost
		--	   WHEN (WIPA.OriginalCost <> 0 ) Then WIPA.OriginalCost
		--	   ELSE 0
		--	   END AS FinalProjectedCost
		, WIPA.ProjFinalGM
		, WIPA.ProjFinalGMPerc
		, WIPA.PrevEarnedRevenue
		, WIPA.MTDEarnedRev
		, (WIPA.PrevEarnedRevenue + WIPA.MTDEarnedRev) as TotalEarnedRevenue
		 FROM mckWipArchiveJC3 AS WIPA
			LEFT OUTER JOIN JCCM CM
				ON WIPA.JCCo = CM.JCCo
				AND LTRIM(WIPA.Contract) = LTRIM(CM.Contract)
				--AND WIPA.Department = CM.Department
			LEFT OUTER JOIN udBandOClass BO
				ON CM.udBOClass = BO.BOClassCode
		 WHERE WIPA.RevenueTypeName= 'Straight Line'
		 AND WIPA.IsLocked='Y'
		 AND WIPA.JCCo = ISNULL(@Company,WIPA.JCCo)
		 AND WIPA.Department = ISNULL(@Department,WIPA.Department)
		 AND RTRIM(WIPA.GLDepartment) = ISNULL(@GLDepartment,RTRIM(WIPA.GLDepartment))
		 --AND WIPA.Contract = ISNULL(@Contract,WIPA.Contract)
		 AND ((WIPA.Contract  LIKE ('%' + coalesce((@Contract),'') + '%')) OR (@Contract IS NULL)) 
		 AND WIPA.ContractStatus = ISNULL(@ContractStat,WIPA.ContractStatus)
		 --AND WIPA.POC = ISNULL(@POC,WIPA.POC)
		 AND (UPPER(WIPA.POCName) LIKE ('%' + coalesce(UPPER(@POC),'') + '%') OR @POC IS NULL) 
		 AND WIPA.ThroughMonth = dbo.vfFirstDayOfMonth(@Month)	
		)
	SELECT 
	ThroughMonth AS 'Through Month'			
	, JCCo AS 'JC Company'				
	, Contract			
	, ContractDesc AS 'Contract Description'
	, PRG AS 'PRG'
	, PRGDescription AS 'PRG Description'	
	--, ContractItem	
	--, ContractIemDesc
	--, ContractItemNotes	
    , ContractStatusDesc AS 'Contract Status'		
	, StrLineTermStart AS 'Straight Line Term Start'		
    , StraightLineTerm_Months AS 'Straight Line Term Months'
	, StrLineTermEnd AS 'Straight Line Term End'	
	, RemainingMonths AS 'Remaining S/L Months'			
	, RevenueTypeName AS 'Revenue Type'         
    , Department AS 'JC Department' 
	, GLDepartment AS 'GL Department'
	, GLDepartmentName  AS 'GL Department Name'        
	--, POC						
	, POCName AS 'POC Name'
	, VerticalMarket AS 'Vertical Market'
	, BOClass AS 'Forecast B&O Classification'					
	, OrigContractAmt AS 'Original Contract Amount'			
	, CurrContractAmt AS 'Current Contract Amount'			
	, ProjContractAmt AS 'Projected Contract Amount'		
	, FinalProjectedAmt	AS 'Projected Final Contract Amount'		
	--, OriginalCost				
	--, ProjectedCost		
	--, FinalProjectedCost
	, ProjectMargin AS 'Projected Final Gross Margin'
	, ProjectMarginPct AS 'Projected Final Gross Margin %'
	, PrevMTDEarnedRev AS 'Prior Month JTD Rev Earned'
	, CurrentMthRev AS 'MTD Earned Revenue'		
	--, (FinalProjectedAmt - FinalProjectedCost) AS FinalGrossMargin
	--, CASE WHEN (FinalProjectedCost > 0) THEN ((FinalProjectedAmt - FinalProjectedCost)/FinalProjectedAmt) 
	--		ELSE 0
	--		END AS FinalMarginPct		
	--, TotalEarnedRevenue
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,1,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,1,ThroughMonth)))
				THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '1'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,2,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,2,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '2'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,3,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,3,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '3'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,4,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,4,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '4'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,5,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,5,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '5'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,6,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,6,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '6'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,7,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,7,ThroughMonth)))
				THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '7'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,8,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,8,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '8'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,9,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,9,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '9'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,10,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,10,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '10'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,11,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,11,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '11'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,12,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,12,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '12'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,13,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,13,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '13'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,14,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,14,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '14'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,15,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,15,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '15'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,16,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,16,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '16'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,17,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,17,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '17'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,18,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,18,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '18'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,19,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,19,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '19'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,20,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,20,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '20'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,21,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,21,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '21'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,22,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,22,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '22'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,23,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,23,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '23'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,24,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,24,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '24'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,25,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,25,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '25'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,26,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,26,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '26'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,27,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,27,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '27'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,28,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,28,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '28'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,29,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,29,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '29'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,30,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,30,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '30'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,31,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,31,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '31'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,32,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,32,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '32'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,33,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,33,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '33'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,34,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,34,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '34'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,35,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,35,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '35'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,36,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,36,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '36'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,37,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,37,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '37'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,38,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,38,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '38'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,39,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,39,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '39'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,40,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,40,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '40'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,41,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,41,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '41'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,42,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,42,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '42'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,43,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,43,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '43'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,44,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,44,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '44'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,45,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,45,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '45'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,46,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,46,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '46'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,47,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,47,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '47'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,48,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,48,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '48'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,49,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,49,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '49'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,50,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,50,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '50'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,51,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,51,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '51'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,52,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,52,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '52'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,53,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,53,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '53'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,54,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,54,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '54'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,55,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,55,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '55'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,56,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,56,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '56'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,57,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,57,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '57'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,58,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,58,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '58'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,59,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,59,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '59'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN ((StrLineTermStart <= DATEADD(MONTH,60,ThroughMonth)) AND (StrLineTermEnd >= DATEADD(MONTH,60,ThroughMonth)))
					THEN ((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
			ELSE 0 
			END AS '60'
	, CASE  WHEN (RemainingMonths <= 0) THEN 0
			WHEN (StrLineTermStart >= DATEADD(MONTH,61,ThroughMonth)) THEN (FinalProjectedAmt - TotalEarnedRevenue)
			WHEN ((StrLineTermStart > ThroughMonth) AND (StrLineTermEnd >= DATEADD(MONTH,61,ThroughMonth)) AND (StrLineTermStart < DATEADD(MONTH,61,ThroughMonth))) 
				THEN ((FinalProjectedAmt) - (TotalEarnedRevenue) - (((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
				* (DATEDIFF(Month, StrLineTermStart,(DATEADD(MONTH,61,ThroughMonth))))))
			WHEN ((StrLineTermStart <= ThroughMonth) AND (StrLineTermEnd >= DATEADD(MONTH,61,ThroughMonth))) 
				THEN ((FinalProjectedAmt) - (TotalEarnedRevenue) - (((FinalProjectedAmt - TotalEarnedRevenue)/ RemainingMonths) 
				* (60)))	
			ELSE 0
			END AS 'Remaining Spread'
	FROM mckJCStrLnRev_Table;


