SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspAPUIReviewerUpdate]
  /***********************************************************
   * CREATED BY: MV 02/20/08
   * MODIFIED By : MV 12/23/09 - 133073 - replace cursor with set based statement 
   *				GF 10/26/2010 - issue #141031 change to use vfDateOnly function
   *				MV 01/23/2013 TK-20779 use getdate() for DateAssigned insert to bAPUR.
   *              
   *
   * USAGE:
   * called from btAPUIu when the header (APUI) Reviewer Group changes.
   * It adds reviewers to the lines (APUL) for the new Reviewer Group
   * 
   * INPUT PARAMETERS
   *   APCo, UIMth, UISeq, ReviewerGroup 

   * OUTPUT PARAMETERS
   *    
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@apco bCompany = null , @uimth bMonth= null, @uiseq int = null, @reviewergroup varchar(10))
	as
	set nocount on
  
 
  declare @rcode int, @opencursor int,@line int, @applythresholdtoline bYN,
	@invoicetotal bDollar, @grossamt bDollar
 
  select @rcode = 0, @opencursor = 0

 --get threshold flag
	select @applythresholdtoline=ApplyThreshToLineYN from HQRG where ReviewerGroup=@reviewergroup

--get invoice total 
	select @invoicetotal = sum(GrossAmt) from APUL where APCo=@apco and UIMth=@uimth and UISeq=@uiseq

-- add header (-1) reviewers as lines - one insert statement will add each header (APUI) reviewer to each line (APUL)
	insert into bAPUR (APCo, UIMth, UISeq, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, DateApproved,
		AmountApproved, Rejected, RejReason, APTrans, ExpMonth, Memo, LoginName, UniqueAttchID, RejectDate, ReviewerGroup)
	----#141031
	select i.APCo,i.UIMth,i.UISeq,r.Reviewer,'N',i.Line,r.ApprovalSeq, getdate(),null,null,'N',null,
		null,null,null,null,null,null,r.ReviewerGroup
	from APUL i
	join bAPUR r on r.APCo = i.APCo and r.UIMth = i.UIMth and r.UISeq = i.UISeq  
		where r.APCo=@apco and r.UIMth=@uimth and r.UISeq=@uiseq and r.Line = -1 and r.ReviewerGroup=@reviewergroup and 
		not exists (select 1 from bAPUR r2 where i.APCo = r2.APCo and i.UIMth = r2.UIMth and i.UISeq = r2.UISeq and
		i.Line = r2.Line and r2.Reviewer = r.Reviewer and r.ApprovalSeq = r2.ApprovalSeq and 
		r.APTrans is null and r.ExpMonth is null)

-- add header (APUI) threshold reviewers to lines (APUL)
	INSERT bAPUR (APCo, UIMth, UISeq, ReviewerGroup, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, Rejected)
	----#141031
	SELECT @apco, @uimth, @uiseq, @reviewergroup,d.Reviewer, 'N', l.Line, d.ApprovalSeq, getdate(), 'N'
	FROM bAPUI i join vHQRD d on i.ReviewerGroup=d.ReviewerGroup
	JOIN bAPUL l on i.APCo=l.APCo and i.UIMth=l.UIMth and i.UISeq=l.UISeq
	WHERE  i.APCo=@apco and i.UIMth=@uimth and i.UISeq=@uiseq  and d.ReviewerGroup=@reviewergroup and
				(d.ThresholdAmount is not null and
				 case isnull(@applythresholdtoline,'N') when 'N' then isnull(@invoicetotal,0) else l.GrossAmt end >= d.ThresholdAmount) 
				 and not exists (select 1 from bAPUR r where r.APCo=@apco and r.UIMth=@uimth and r.UISeq=@uiseq and r.Line=l.Line and
					r.Reviewer = d.Reviewer and r.ApprovalSeq = d.ApprovalSeq)

  vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspAPUIReviewerUpdate] TO [public]
GO
