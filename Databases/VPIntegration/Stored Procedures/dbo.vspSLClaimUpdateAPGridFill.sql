SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspSLClaimUpdateAPGridFill]
/****************************************************************************
* CREATED BY:	GF 10/10/2012 TK-18326 SL Claim Enhancement
* MODIFIED BY:
*
*
* USAGE:
* Fills grid with available SL Claims that can be updated to AP Transaction Entry
* or AP Unapproved Invoices
*
* INPUT PARAMETERS:
* @SLCo				SL Company
* @ProcessName		AP Transaction Entry or AP Unapproved Invoices
* @BeginSL			Beginning subcontract or null
* @EndSL			Ending subcontract or null
* @BeginVendorName	Beginning vendor sort name or null
* @EndVendorName	Ending vendor sort name or null
*
* OUTPUT PARAMETERS:
*	See Select statement below
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@SLCo bCompany = NULL, @ProcessName VARCHAR(128) = NULL, 
 @UpdateAllClaims CHAR(1) = 'N',
 @BeginJCCo bCompany = NULL, @BeginJob bJob = NULL, 
 @EndJCCo bCompany = NULL, @EndJob bJob = NULL,
 @BeginVendorName VARCHAR(20) = NULL, @EndVendorName VARCHAR(20) = NULL)
AS
SET NOCOUNT ON

DECLARE @rcode INT

SET @rcode = 0

IF @UpdateAllClaims IS NULL SET @UpdateAllClaims = 'N'

----"SLClaimUpdateAPTrans", "SLClaimUpdateAPUnapprove"

---- WILL NEED MORE WORK ONCE UPDATES TO AP ARE COMPLETE FOR WHICH CLAIMS ARE AVAILABLE USING STATUS
IF @ProcessName = 'SLClaimUpdateAPUnapprove'
	BEGIN
	/* Fill update grid with valid claims for AP unapproved invoices  */
	select @UpdateAllClaims AS [Update]
		  ,c.SL AS [Subcontract]
		  ,c.ClaimNo AS [Claim No]
		  ,c.[Description] AS [Claim Description]
		  ,SLHD.Job AS [Job]
		  ,JCJM.[Description] AS [Job Description]
		  ,SLHD.Vendor AS [Vendor]
		  ,APVM.Name AS [Name]
		  ,c.ClaimDate AS [Claim Date]
		  ,c.APRef AS [Invoice No.]
		  ,TTL.AmountPayable AS [Amount Payable]
	from dbo.vSLClaimHeader c WITH (NOLOCK)
	INNER JOIN dbo.bSLHD SLHD WITH (NOLOCK) ON SLHD.SLCo=c.SLCo AND SLHD.SL=c.SL
	INNER JOIN dbo.bAPVM APVM WITH (NOLOCK) ON APVM.VendorGroup=SLHD.VendorGroup AND APVM.Vendor=SLHD.Vendor
	INNER JOIN dbo.bJCJM JCJM WITH (NOLOCK) ON JCJM.JCCo=SLHD.JCCo AND JCJM.Job=SLHD.Job
	INNER JOIN dbo.SLClaimHeaderTotal TTL WITH (NOLOCK) ON TTL.SLCo = c.SLCo AND TTL.SL=c.SL AND TTL.ClaimNo=c.ClaimNo
	WHERE c.SLCo = @SLCo
		AND SLHD.JCCo >= ISNULL(@BeginJCCo, SLHD.JCCo)
		AND SLHD.Job >= ISNULL(@BeginJob, SLHD.Job)
		AND SLHD.JCCo <= ISNULL(@EndJCCo, SLHD.JCCo)
		AND SLHD.Job <= ISNULL(@EndJob, SLHD.Job)
		AND APVM.SortName >= ISNULL(@BeginVendorName, APVM.SortName)
		AND APVM.SortName <= ISNULL(@EndVendorName, APVM.SortName)
		AND (c.ClaimStatus <> 20 ----denied
			OR (c.ClaimStatus = 30 AND SLHD.ApprovalRequired = 'N')) ----certified and not required
		--AND c.ClaimStatus NOT IN(20,30) ----denied ,certified
		---- must have an amount payable
		AND (TTL.ApproveAmount <> 0 OR TTL.ApproveTaxAmount <> 0 OR TTL.ApproveRetention <> 0)
		---- display only claims with items
		AND EXISTS(SELECT 1 FROM dbo.vSLClaimItem i WHERE i.SLCo=c.SLCo
						AND i.SL=c.SL AND i.ClaimNo=c.ClaimNo)
		---- SL Claim Key Id must not be in AP
		AND NOT EXISTS(SELECT 1 FROM dbo.bAPUI APUI WHERE APUI.SLKeyID = c.KeyID)
		AND NOT EXISTS(SELECT 1 FROM dbo.bAPTL APTL WHERE APTL.SLKeyID = c.KeyID)
		AND NOT EXISTS(SELECT 1 FROM dbo.bAPHB APHB WHERE APHB.SLKeyID = c.KeyID)
		
	order by c.SL, c.ClaimNo
	END
ELSE
	BEGIN
	/* Fill update grid with valid claims AP transaction entry */
	SELECT @UpdateAllClaims AS [Update]
		  ,c.SL AS [Subcontract]
		  ,c.ClaimNo AS [Claim No]
		  ,c.[Description] AS [Claim Descripiton]
		  ,SLHD.Job AS [Job]
		  ,JCJM.[Description] AS [Job Description]
		  ,SLHD.Vendor AS [Vendor]
		  ,APVM.Name AS [Name]
		  ,c.ClaimDate AS [Claim Date]
		  ,c.APRef AS [Invoice No.]
		  ,TTL.AmountPayable AS [Amount Payable]
	from dbo.vSLClaimHeader c WITH (NOLOCK)
	INNER JOIN dbo.bSLHD SLHD WITH (NOLOCK) ON SLHD.SLCo=c.SLCo AND SLHD.SL=c.SL
	INNER JOIN dbo.bAPVM APVM WITH (NOLOCK) ON APVM.VendorGroup=SLHD.VendorGroup AND APVM.Vendor=SLHD.Vendor
	INNER JOIN dbo.bJCJM JCJM WITH (NOLOCK) ON JCJM.JCCo=SLHD.JCCo AND JCJM.Job=SLHD.Job
	INNER JOIN dbo.SLClaimHeaderTotal TTL WITH (NOLOCK) ON TTL.SLCo = c.SLCo AND TTL.SL=c.SL AND TTL.ClaimNo=c.ClaimNo
	WHERE c.SLCo = @SLCo
		AND SLHD.JCCo >= ISNULL(@BeginJCCo, SLHD.JCCo)
		AND SLHD.Job >= ISNULL(@BeginJob, SLHD.Job)
		AND SLHD.JCCo <= ISNULL(@EndJCCo, SLHD.JCCo)
		AND SLHD.Job <= ISNULL(@EndJob, SLHD.Job)
		AND APVM.SortName >= ISNULL(@BeginVendorName, APVM.SortName)
		AND APVM.SortName <= ISNULL(@EndVendorName, APVM.SortName)
		AND SLHD.ApprovalRequired = 'N' ---- claim approval required
		and c.ClaimStatus <> 20 ----denied
		----AND c.ClaimStatus NOT IN (10,20) ----pending, denied
		---- must have an amount payable
		AND (TTL.ApproveAmount <> 0 OR TTL.ApproveTaxAmount <> 0 OR TTL.ApproveRetention <> 0)	
		---- display only claims with items
		AND EXISTS(SELECT 1 FROM dbo.vSLClaimItem i WHERE i.SLCo=c.SLCo
						AND i.SL=c.SL AND i.ClaimNo=c.ClaimNo)
		---- SL Claim Key Id must not be in AP
		AND NOT EXISTS(SELECT 1 FROM dbo.bAPUI APUI WHERE APUI.SLKeyID = c.KeyID)
		AND NOT EXISTS(SELECT 1 FROM dbo.bAPTL APTL WHERE APTL.SLKeyID = c.KeyID)
		AND NOT EXISTS(SELECT 1 FROM dbo.bAPHB APHB WHERE APHB.SLKeyID = c.KeyID)

	order by c.SL, c.ClaimNo
	END
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLClaimUpdateAPGridFill] TO [public]
GO
