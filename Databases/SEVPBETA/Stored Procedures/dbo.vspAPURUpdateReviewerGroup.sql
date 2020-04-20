SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[vspAPURUpdateReviewerGroup]
   /************************************************************
      * Created: 12/06/07 MV - #29702 Unapproved Enhancement project
      * Modified:	2/12/08 MV - #29702 - removed oldreviewergroup delete
      *             6/20/08 MV - #128715 - add only non-threshold reviewers here	
      *				GF 10/26/2010 - issue #141031 change to use vfDateOnly function
      *				MV 01/15/2013 - D-05483/TK-20779 replaced vfDateOnly with getdate for DateAssigned in APUR insert. Notifier query needs hours/minutes.
      * 
      * Usage:
      *	Adds and removes reviewer group reviewers to bAPUR 
      *
      * Inputs:
      *	@apco			AP Co#
      *	@uimth			Unapproved Invoice Mth
      *	@uiseq			Unapproved Invoice Seq#
      *	@line			UI Line#
      *	@oldreviewergroup	Previous RG 
      *	@reviewergroup	updated RG
      *	@removeoldYN	flag to remove reviewers from the line that are in the old reviewer group
      *	@grossamt			Gross Amount for the line	
      *
      *************************************************************/
    	(@apco bCompany = null, @uimth bMonth = null, @uiseq int = null, @line int = null,
     	 @reviewergroup varchar(10) = null, @grossamt bDollar = null, @msg varchar(255) output)

     as
     set nocount on 

	declare @rcode int, @ApplyThreshAmtToLine bYN, @APUIReviewerGroup varchar(10)
	select @rcode = 0 

	if @reviewergroup is not null
	begin
		if not exists(select 1 from vHQRG where ReviewerGroup=@reviewergroup)
		begin
		select @msg = 'Invalid Reviewer Group.', @rcode=1
		goto vspexit
		end	
	end
	
	--delete any reviewers already assigned to this line that are also in the reviewergroup
	delete from bAPUR where APCo = @apco and UIMth = @uimth and UISeq = @uiseq and Line = @line 
			 and exists(select 1 from vHQRD h where h.ReviewerGroup=@reviewergroup and h.Reviewer=bAPUR.Reviewer) 
			
	--add reviewers
	if @reviewergroup is not null
	begin
	 insert bAPUR (APCo, UIMth, UISeq, ReviewerGroup, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, Rejected)
		select @apco, @uimth, @uiseq, @reviewergroup,r.Reviewer, 'N', @line, r.ApprovalSeq, getdate(), 'N'
 		from vHQRD r
		where  ReviewerGroup=@reviewergroup	and r.ThresholdAmount is null
			and not exists (select 1 from bAPUR h where h.APCo = @apco and h.UIMth = @uimth and h.UISeq = @uiseq
			   and h.Line = @line and h.Reviewer = r.Reviewer)
	if @@rowcount = 0
		begin
		select @msg = 'Error: Reviewers in Reviewer Group: ' + @reviewergroup + ' were not added for this line.', @rcode=1
		goto vspexit
		end
	end
	

	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPURUpdateReviewerGroup] TO [public]
GO
