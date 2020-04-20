SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspAPURCascadeApprovalByLine]
    /*************************************************************
    *    Created by: MV 01/29/08 - #29702 Unapproved Enhancement
	*								
    *    
    *    Modified:
    *    
    *    Purpose: Called from APUnappInvRevItems when a line is approved.     
    *             Lower level reviewers on this line will be approved 
	*			  if the APUL Reviewer Group is flagged to allow uplevel approvals.
    *
    *    Inputs: @apco
    *            @uimth
    *            @uiseq
    *            @reviewer
    *            @jcco
    *            @job
    *            @linetype
    *            @apprvdyn
	*			 @loginname
    *            @reviewergroup
    *
    *
    *
    *
    *************************************************************/
    (@apco bCompany, @reviewer varchar(3), @apprvdyn char(1),@loginname bVPUserName = null,
     @uimth bMonth, @uiseq int, @line int, @reviewergroup varchar(10) = null)
    
    as
	declare @allowuplevelapproval int

	if @apprvdyn = 'Y'
	begin
		-- get uplevel flag from HQRG
		select @allowuplevelapproval = AllowUpLevelApproval from HQRG with (nolock)
		 where ReviewerGroup=@reviewergroup
		-- do cascade approvals if AllowUpLevelApprovals is 2 - lower level reviewers on this line
		if @allowuplevelapproval = 2
			begin
			update APUR 
			set ApprvdYN = @apprvdyn,LoginName = @loginname
			where /*ReviewerGroup=@reviewergroup and */	Reviewer <> @reviewer 
				and APUR.Rejected ='N'
				and APUR.ApprvdYN ='N'
				and APUR.ApprovalSeq < (select ApprovalSeq from APUR r1 (nolock) where APUR.APCo = r1.APCo and APUR.UIMth=r1.UIMth and
					 APUR.UISeq=r1.UISeq and APUR.Line = r1.Line and r1.Reviewer=@reviewer)
				and APUR.APCo = @apco and APUR.UIMth = @uimth and APUR.UISeq = @uiseq and APUR.Line=@line
			end
	end
  
    return

GO
GRANT EXECUTE ON  [dbo].[vspAPURCascadeApprovalByLine] TO [public]
GO
