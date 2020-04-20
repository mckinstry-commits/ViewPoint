SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspAPURUpdateHeader]
/*************************************************************
* Created by:	TV/GG 09/27/01
*    
* Modified by:	TV 07/31/03 - #22000 Take out and ((r.ApprvdYN = 'N' and isnull(r.Rejected,'N') = 'N') or @showall = 'Y')          
*				MV 09/15/03 - #21650 update user login name of approver
*				MV 10/31/06 - APUnappInvRev 6X recode - removed @showall char(1) = 'N' from input params
*				MV 01/24/08 - #29702 Unapproved Enhancement 
*							- Approved = Y - if up level approval is allowed approve all lines for reviewer 
*								and all lines for lower level reviewers who have not rejected or already approved
*							- Rejected = Y - reject all lines for just this reviewer
*				MV 11/06/08 - #130958 commented out 'and r.Rejected ='N'' for update APUR for @apprvdyn='Y' but only
*							  for the reviewer line, not for cascade update. 
*							- Cascade update should approve only lines not rejected.
*				MH 04/11/11 - TK-03607 Expand @linetypes to varchar(8) to accomidate new SM line type.
*				KK 12/20/12 - D-06099 Refactor and modify to allow for multiple groups eligible for cascading approvals.
*    
*    Purpose: To update all eligible lines in APUR when     
*             Header area on APUnappInRev form is clicked
*
*    Inputs: @apco
*            @uimth
*            @uiseq
*            @reviewer
*            @jcco
*            @job
*            @linetype
*            @apprvdyn
*            @rejected
*            @rejreason
*
***************************************************************************/
(@apco bCompany, 
 @reviewer varchar(3), 
 @jcco bCompany = NULL, 
 @job bJob = NULL,
 @linetypes varchar(8),
 @apprvdyn char(1),
 @loginname bVPUserName = NULL,
 @rejected char(1),
 @rejreason varchar(20), 
 @uimth bMonth, 
 @uiseq int,
 @errmsg varchar(255) OUTPUT)

AS
-- Approve the invoice and applicable lines
IF @apprvdyn = 'Y'
BEGIN
	-- Update APUR for - self only
	UPDATE APUR
	SET ApprvdYN = 'Y',
		LoginName = @loginname,
		Rejected = 'N', 
		RejReason = NULL 
	FROM APUL l
	JOIN APUR r ON l.APCo = r.APCo 
			   AND l.UIMth = r.UIMth 
			   AND l.UISeq = r.UISeq 
			   AND l.Line = r.Line
	LEFT JOIN HQRG g ON g.ReviewerGroup = ISNULL(r.ReviewerGroup,'')
	WHERE r.Reviewer = @reviewer
		AND r.APCo = @apco 
		AND r.UIMth = @uimth 
		AND r.UISeq = @uiseq
		AND ISNULL(l.JCCo,0) = ISNULL(@jcco,ISNULL(l.JCCo,0))	-- optional restriction by JC Co#
    	AND ISNULL(l.Job,'') = ISNULL(@job,ISNULL(l.Job,''))	-- optional restriction by Job
    	AND CHARINDEX(CONVERT(varchar,l.LineType),@linetypes) <> 0 	-- included Line Types
		AND (r.ReviewerGroup IS NULL	-- no reviewer group for this line so only self approval 
			 OR g.AllowUpLevelApproval = 1 -- group not flagged to approve for other employees
			 OR ((SELECT COUNT(*) FROM APUR r1 (NOLOCK) -- group is flagged, but there are no additional reviewers
				  WHERE r1.Reviewer <> @reviewer
					AND r1.APCo = @apco 
					AND r1.UIMth = @uimth
					AND r1.UISeq = @uiseq
					AND r1.Line = r.Line 
					AND r1.ApprvdYN = 'N'
					AND r1.ApprovalSeq < r.ApprovalSeq
				 )= 0)		
			)

	-- Update APUR for - self and lower levels
	PRINT 'allow up level approval 2'
	UPDATE APUR
	SET ApprvdYN = 'Y',
		LoginName = @loginname,
		RejReason = NULL 
	FROM APUL l
	JOIN APUR r ON l.APCo = r.APCo 
			   AND l.UIMth = r.UIMth 
			   AND l.UISeq = r.UISeq 
			   AND l.Line = r.Line
	LEFT JOIN HQRG g ON g.ReviewerGroup = ISNULL(r.ReviewerGroup,'')
	WHERE   r.APCo = @apco 
		AND r.UIMth = @uimth 
		AND r.UISeq = @uiseq 
		AND ISNULL(l.JCCo,0) = ISNULL(@jcco,ISNULL(l.JCCo,0))	-- optional restriction by JC Co#
		AND ISNULL(l.Job,'') = ISNULL(@job,ISNULL(l.Job,''))	-- optional restriction by Job
		AND CHARINDEX(CONVERT(varchar,l.LineType),@linetypes) <> 0 	-- included Line Types
		AND g.AllowUpLevelApproval = 2 -- reviewer group will not be null in this case
		AND r.Rejected = 'N'
		AND r.ApprvdYN = 'N'
		AND r.ApprovalSeq <= (SELECT ApprovalSeq FROM APUR r1 (NOLOCK) 
							  WHERE r.APCo = r1.APCo 
								AND r.UIMth = r1.UIMth 
								AND r.UISeq = r1.UISeq 
								AND	r.Line = r1.Line 
								AND r1.Reviewer = @reviewer)
END

-- Reject the invoice and applicable lines
ELSE IF @rejected = 'Y'
BEGIN
	UPDATE APUR
	SET Rejected = @rejected,
	    RejReason = @rejreason,
	    LoginName = @loginname, 
	    ApprvdYN = 'N' 
	FROM APUL l
	JOIN APUR r ON l.APCo = r.APCo 
			   AND l.UIMth = r.UIMth 
			   AND l.UISeq = r.UISeq 
			   AND l.Line = r.Line
	WHERE r.Reviewer = @reviewer 
		AND ISNULL(l.JCCo,0) = ISNULL(@jcco,ISNULL(l.JCCo,0))	-- optional restriction by JC Co#
    	AND ISNULL(l.Job,'') = ISNULL(@job,ISNULL(l.Job,''))	-- optional restriction by Job
    	AND CHARINDEX(CONVERT(varchar,l.LineType),@linetypes) <> 0 	-- included Line Types
		AND r.APCo = @apco 
		AND r.UIMth = @uimth 
		AND r.UISeq = @uiseq
END

-- Both the Approve and Reject flags have been unchecked
ELSE IF @apprvdyn ='N' AND @rejected ='N'
BEGIN
	UPDATE APUR
	SET ApprvdYN = @apprvdyn,
		Rejected = @rejected, 
		RejReason = NULL, 
		LoginName = NULL
	FROM APUL l
	JOIN APUR r ON l.APCo = r.APCo 
			   AND l.UIMth = r.UIMth 
			   AND l.UISeq = r.UISeq 
			   AND l.Line = r.Line
	WHERE r.Reviewer = @reviewer 
		AND ISNULL(l.JCCo,0) = ISNULL(@jcco,ISNULL(l.JCCo,0))	-- optional restriction by JC Co#
    	AND ISNULL(l.Job,'') = ISNULL(@job,ISNULL(l.Job,''))	-- optional restriction by Job
    	AND CHARINDEX(CONVERT(varchar,l.LineType),@linetypes) <> 0 	-- included Line Types
		AND r.APCo = @apco 
		AND r.UIMth = @uimth 
		AND r.UISeq = @uiseq
END

RETURN


GO
GRANT EXECUTE ON  [dbo].[bspAPURUpdateHeader] TO [public]
GO
