SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[vrptPCBidAnalysis]

(@Company bCompany, 

@PotentialProjectStart varchar(100), 
@PotentialProjectEnd varchar(100), 

@VendorStart bVendor, 
@VendorEnd bVendor, 

@ScopeStart varchar(10), 
@ScopeEnd varchar(10), 

@PhaseStart bPhase, 
@PhaseEnd bPhase, 

@BidAmountHighLowAll varchar(1), 
@BidResponse varchar(1), 
@BidReceived varchar(1), 
@BidAwarded varchar(1), 

@SortOrder varchar(1))

AS
/***********************************************************************
*	Created: 12/20/2010
*	Author : Huy Huynh
*	Purpose: This stored procedure is intended to analyse vrvPCBidAnalysis
*
*	Reports: PCBidAnalysis.rpt
*
*	Mods:	 
***********************************************************************/
/*IF @PotentialProjectEnd = ''
Begin
	SELECT @PotentialProjectEnd = 'zzzzzzzzzzzzzzzzzzzz'	
End
IF @VendorStart = '' 
Begin
	SELECT @VendorStart = 0	
End
IF @VendorEnd = '' 
Begin
	SELECT @VendorEnd = 999999999999999	
End
IF @ScopeEnd = ''
Begin
	SELECT @ScopeEnd = 'zzzzzzzzzz'	
End
IF @PhaseEnd = ''
Begin
	SELECT @PhaseEnd = 'zzzzzzzzzzzzz'	
End
*/
IF @BidAmountHighLowAll = 'H' 
BEGIN
	WITH MaxBids (CoveragePotentialProject, ScopeCode, Phase, MaxAmount)
	AS
	(
			SELECT DISTINCT CoveragePotentialProject, ScopeCode , Phase, Max(BidAmount) FROM vrvPCBidAnalysis 
			WHERE BidAmount IS NOT NULL
			GROUP BY CoveragePotentialProject, ScopeCode , Phase
	)
	SELECT vrvPCBidAnalysis.*
	FROM MaxBids
	LEFT JOIN vrvPCBidAnalysis
	ON MaxBids.CoveragePotentialProject = vrvPCBidAnalysis.CoveragePotentialProject
	AND MaxBids.ScopeCode = vrvPCBidAnalysis.ScopeCode
	AND MaxBids.Phase = vrvPCBidAnalysis.Phase
	AND MaxBids.MaxAmount = vrvPCBidAnalysis.BidAmount
	
	WHERE HQCo = @Company
	AND (vrvPCBidAnalysis.CoveragePotentialProject BETWEEN @PotentialProjectStart AND @PotentialProjectEnd)
	AND (vrvPCBidAnalysis.Vendor BETWEEN @VendorStart AND @VendorEnd)
	AND (vrvPCBidAnalysis.ScopeCode BETWEEN @ScopeStart AND @ScopeEnd OR vrvPCBidAnalysis.ScopeCode IS NULL)
	AND (vrvPCBidAnalysis.Phase BETWEEN @PhaseStart AND @PhaseEnd OR vrvPCBidAnalysis.Phase IS NULL)
	AND (vrvPCBidAnalysis.BidResponse = @BidResponse OR @BidResponse = '')
	AND (vrvPCBidAnalysis.BidReceived = @BidReceived OR @BidReceived = '')
	AND (vrvPCBidAnalysis.BidAwarded = @BidAwarded OR @BidAwarded = '')
END
ELSE IF @BidAmountHighLowAll = 'L' 
BEGIN
	WITH MinBids (CoveragePotentialProject, ScopeCode, Phase, MinAmount)
	AS
	(
			SELECT DISTINCT CoveragePotentialProject, ScopeCode , Phase, Min(BidAmount) FROM vrvPCBidAnalysis 
			WHERE BidAmount IS NOT NULL
			GROUP BY CoveragePotentialProject, ScopeCode , Phase
	)
	SELECT vrvPCBidAnalysis.*
	FROM MinBids
	LEFT JOIN vrvPCBidAnalysis
	ON MinBids.CoveragePotentialProject = vrvPCBidAnalysis.CoveragePotentialProject
	AND MinBids.ScopeCode = vrvPCBidAnalysis.ScopeCode
	AND MinBids.Phase = vrvPCBidAnalysis.Phase
	AND MinBids.MinAmount = vrvPCBidAnalysis.BidAmount
	
	WHERE HQCo = @Company
	AND (vrvPCBidAnalysis.CoveragePotentialProject BETWEEN @PotentialProjectStart AND @PotentialProjectEnd)
	AND (vrvPCBidAnalysis.Vendor BETWEEN @VendorStart AND @VendorEnd)
	AND (vrvPCBidAnalysis.ScopeCode BETWEEN @ScopeStart AND @ScopeEnd OR vrvPCBidAnalysis.ScopeCode IS NULL)
	AND (vrvPCBidAnalysis.Phase BETWEEN @PhaseStart AND @PhaseEnd OR vrvPCBidAnalysis.Phase IS NULL)
	AND (vrvPCBidAnalysis.BidResponse = @BidResponse OR @BidResponse = '')
	AND (vrvPCBidAnalysis.BidReceived = @BidReceived OR @BidReceived = '')
	AND (vrvPCBidAnalysis.BidAwarded = @BidAwarded OR @BidAwarded = '')
END
ELSE
	SELECT * FROM vrvPCBidAnalysis
	WHERE HQCo = @Company
	AND (CoveragePotentialProject BETWEEN @PotentialProjectStart AND @PotentialProjectEnd)
	AND (vrvPCBidAnalysis.Vendor BETWEEN @VendorStart AND @VendorEnd)
	AND (ScopeCode BETWEEN @ScopeStart AND @ScopeEnd OR ScopeCode IS NULL)
	AND (Phase BETWEEN @PhaseStart AND @PhaseEnd OR Phase IS NULL)
	AND (BidResponse = @BidResponse OR @BidResponse = '')
	AND (BidReceived = @BidReceived OR @BidReceived = '')
	AND (BidAwarded = @BidAwarded OR @BidAwarded = '')

GO
GRANT EXECUTE ON  [dbo].[vrptPCBidAnalysis] TO [public]
GO
