SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspAPUnappThresholdReviewers]
 /***********************************************************
   * CREATED BY: MV 02/13/08
   * MODIFIED By : MV 06/20/08 - #128715 add threshold reviewers for header RG and line RG 
   *				MV 03/31/09 - #132911 - apply negative threshold reviewers for credit invoices.
   *				MV 10/01/09 - #135628 - apply negative threshold reviewers to credit and non credit invoices.
   *				GF 09/10/2010 - issue #141031 changed to use vfDateOnly
   *				MV 11/15/10 - #141879 - was adding previously deleted reviewers back into bAPUR because it was
   *					adding reviewers that aren't threshold reviewers (don't have a threshold amount entered in v.HQRD).
   *				MV 01/15/2013 - D-05483/TK-20779 replaced vfDateOnly with getdate for DateAssigned in APUR insert. Notifier query needs hours/minutes.
   *
   * USAGE:
   * called from APUnappInv, SLUpdateAPUnapp and triggers btAPULi and btAPULu
   * adds threshold reviewers to invoice lines. If a line number is not passed in
   * threshold reviewers are applied to all lines. If a line number is passed in 
   * threshold reviewers are added only for that line. In either case both header RG
   * line RG threshold reviewers are evaluated.
   * INVOICE TOTAL - reviewers are added only if the invoice total (sum of GrossAmt of all lines)
   *    is above their threshold amount. 
   * LINE AMOUNT - reviewers are added only if the line's GrossAmt equal or above their threshold amount.
   * 
   * INPUT PARAMETERS
   *   APCo, UIMth, UISeq, Line 

   * OUTPUT PARAMETERS
   *    @msg If Error

   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@apco bCompany = null , @uimth bMonth= null, @uiseq int = null, @line int = null)
    AS
    SET NOCOUNT ON
  
 
    DECLARE @rcode INT, @opencursor INT,@applythresholdtoline bYN,
	@invoicetotal bDollar, @reviewergroup VARCHAR(10), @APUIreviewergroup VARCHAR(10)
    SELECT @rcode = 0, @opencursor = 0

/*APUnappInv Header*/
IF @line IS NULL
BEGIN
    -- Add Header Reviewer Group INVOICE TOTAL threshold reviewers to all lines
    SELECT @APUIreviewergroup = ReviewerGroup 
    FROM dbo.bAPUI 
    WHERE APCo = @apco AND UIMth = @uimth AND UISeq = @uiseq
    IF @APUIreviewergroup IS NOT NULL
    BEGIN
		-- see if there are any threshold reviewers to add
		IF EXISTS
			(
				SELECT * 
				FROM dbo.vHQRD 
				WHERE ReviewerGroup=@APUIreviewergroup 
				AND ISNULL(ThresholdAmount,0)<> 0
			)
		BEGIN
			SELECT @applythresholdtoline=ApplyThreshToLineYN 
			FROM dbo.vHQRG 
			WHERE ReviewerGroup=@APUIreviewergroup
			IF  @applythresholdtoline = 'N' -- threshold is applied for line amount
			BEGIN
				--get invoice total
				SELECT @invoicetotal = SUM(GrossAmt)
				FROM dbo.bAPUL 
				WHERE APCo=@apco AND UIMth=@uimth AND UISeq=@uiseq
				-- insert APUI threshold reviewers
				INSERT dbo.bAPUR (APCo, UIMth, UISeq, ReviewerGroup, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, Rejected)
				SELECT @apco, @uimth, @uiseq, @APUIreviewergroup,r.Reviewer, 'N', l.Line, r.ApprovalSeq,
					getdate(), 'N'
				FROM dbo.bAPUL l
				JOIN dbo.bAPUI i ON i.APCo=l.APCo AND i.UIMth=l.UIMth AND i.UISeq=l.UISeq
				JOIN dbo.vHQRD r ON i.ReviewerGroup=r.ReviewerGroup
				WHERE  i.APCo=@apco AND i.UIMth=@uimth AND i.UISeq=@uiseq AND r.ReviewerGroup=@APUIreviewergroup
					AND @invoicetotal >= r.ThresholdAmount
					AND NOT EXISTS (
									SELECT 1 
									FROM dbo.bAPUR h
									WHERE h.APCo = @apco AND h.UIMth = @uimth AND h.UISeq = @uiseq
									AND h.Line=l.Line AND h.Reviewer = r.Reviewer
									)
			END
		END
	END
	 --Add Line Reviewer Group INVOICE TOTAL threshold reviewers 
	SELECT @invoicetotal = SUM(GrossAmt)
	FROM dbo.bAPUL 
	WHERE APCo=@apco AND UIMth=@uimth AND UISeq=@uiseq
	INSERT dbo.bAPUR (APCo, UIMth, UISeq, ReviewerGroup, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, Rejected)
	SELECT @apco, @uimth, @uiseq, l.ReviewerGroup,d.Reviewer, 'N', l.Line, d.ApprovalSeq,
		getdate(), 'N'
	FROM dbo.bAPUL l
	JOIN dbo.vHQRG r ON l.ReviewerGroup=r.ReviewerGroup
	JOIN dbo.vHQRD d ON r.ReviewerGroup=d.ReviewerGroup
	WHERE l.APCo=@apco AND l.UIMth=@uimth AND l.UISeq=@uiseq
		AND r.ApplyThreshToLineYN='N'
		AND (d.ThresholdAmount IS NOT NULL AND @invoicetotal >= d.ThresholdAmount)
		AND NOT EXISTS (
						SELECT * 
						FROM dbo.bAPUR h 
						WHERE h.APCo = @apco AND h.UIMth = @uimth AND h.UISeq = @uiseq
						AND h.Line=l.Line AND h.Reviewer = d.Reviewer
						)
END
    

/*APUnappInv Line */
IF @line IS NOT NULL
BEGIN
    --Add Header Reviewer Group LINE AMOUNT threshold reviewers to this line
    SELECT @APUIreviewergroup = ReviewerGroup
    FROM dbo.bAPUI 
    WHERE APCo = @apco AND UIMth = @uimth AND UISeq = @uiseq
    IF @APUIreviewergroup IS NOT NULL
    BEGIN
		SELECT @applythresholdtoline=ApplyThreshToLineYN 
		FROM dbo.vHQRG 
		WHERE ReviewerGroup=@APUIreviewergroup
		IF @applythresholdtoline = 'Y' 
		BEGIN
		 --insert APUI threshold reviewers
			INSERT dbo.bAPUR (APCo, UIMth, UISeq, ReviewerGroup, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, Rejected)
			SELECT @apco, @uimth, @uiseq, @APUIreviewergroup,r.Reviewer, 'N', @line, r.ApprovalSeq,
				getdate(), 'N'
			FROM dbo.bAPUL l
			JOIN dbo.bAPUI i ON i.APCo=l.APCo AND i.UIMth=l.UIMth AND i.UISeq=l.UISeq
			JOIN dbo.vHQRD r ON i.ReviewerGroup=r.ReviewerGroup
			WHERE l.APCo=@apco AND l.UIMth=@uimth AND l.UISeq=@uiseq AND l.Line = @line 
				AND(r.ThresholdAmount IS NOT NULL AND ISNULL(l.GrossAmt,0) >= ISNULL(r.ThresholdAmount,0))
				AND NOT EXISTS (
								SELECT * 
								FROM dbo.bAPUR h 
								WHERE h.APCo = @apco AND h.UIMth = @uimth AND h.UISeq = @uiseq
								AND h.Line=l.Line AND h.Reviewer = r.Reviewer
								)
		END
    END
    

--    --Add Line Reviewer Group LINE AMOUNT threshold reviewers to this line
    INSERT dbo.bAPUR (APCo, UIMth, UISeq, ReviewerGroup, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, Rejected)
    SELECT @apco, @uimth, @uiseq, l.ReviewerGroup,d.Reviewer, 'N', @line, d.ApprovalSeq,
		getdate(), 'N'
    FROM dbo.bAPUL l
    JOIN dbo.vHQRG r ON l.ReviewerGroup=r.ReviewerGroup
    JOIN dbo.vHQRD d ON r.ReviewerGroup=d.ReviewerGroup
    WHERE l.APCo=@apco AND l.UIMth=@uimth AND l.UISeq=@uiseq AND l.Line = @line
	    AND r.ApplyThreshToLineYN='Y'
		AND (d.ThresholdAmount IS NOT NULL AND (ISNULL(l.GrossAmt,0) >= d.ThresholdAmount))
	    AND NOT EXISTS (
						SELECT 1 
						FROM dbo.bAPUR h 
						WHERE h.APCo = @apco AND h.UIMth = @uimth AND h.UISeq = @uiseq
						AND h.Line=l.Line AND h.Reviewer = d.Reviewer
						)
END




vspexit:

RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPUnappThresholdReviewers] TO [public]
GO
