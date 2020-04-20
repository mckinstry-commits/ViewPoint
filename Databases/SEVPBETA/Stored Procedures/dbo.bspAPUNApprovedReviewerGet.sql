SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[bspAPUNApprovedReviewerGet]
   /************************************************************
      * Created: TV 05/02/02
      * Modified: GG 06/21/02
      *			MV 10/01/04 - #25666 restrict job reviewers by reviewer type
      *			MV 02/10/05 - #26977 add default reviewer for IN Location
	  *			MV 05/09/07 - #27747 only insert if reviewers exists
	  *			MV 12/04/07 - #209702 add Vendor reviewer to all line types if flag is checked
	  *			MV 04/15/09 - #133256 - for Equip don't include ApprovalSeq in APUR insert 'does not exist' test
	  *			GF 10/26/2010 - issue #141031 changed to use function vfDateOnly
	  *			MV 01/15/2013 - D-05483/TK-20779 replaced vfDateOnly with getdate for DateAssigned in APUR insert. Notifier query needs hours/minutes.
      * 
      * Usage:
      *	Adds default Reviewer(s) to bAPUR based on information from
      *	AP Unapproved Invoice Line 
      *
      * Inputs:
      *	@apco			AP Co#
      *	@uimth			Unapproved Invoice Mth
      *	@uiseq			Unapproved Invoice Seq#
      *	@line			UI Line#
      *	@linetype		UI Line Type
      *	@jcco			JC Co# 
      *	@job			Job	
      *	@emco			EM Co#	
      *	@equip			Equipment	
      *	@vendorgroup	Vendor Group
      *	@vendor			Vendor
      *
      *************************************************************/
	(@apco bCompany = null, @uimth bMonth = null, @uiseq int = null, @line int = null,
	@linetype tinyint = null, @jcco bCompany = null, @job bJob = null, @emco bCompany = null, 
	@equip bEquip = null, @vendorgroup bGroup = null, @vendor bVendor = null, @inco bCompany = null, 
	@loc bLoc = null )
     
as
      
set nocount on 

	declare @addVendorRevToAllLineTypesYN bYN

	--Get Vendor flag for adding vendor reviewer to all line types
	select @addVendorRevToAllLineTypesYN = AddRevToAllLinesYN 
	from APVM (nolock) where VendorGroup=@vendorgroup and Vendor=@vendor

	-- add default Vendor Reviewer for Expense lines only
	if @linetype = 3
	begin
		if exists(select 1 from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor and isnull(Reviewer,'') <> '')
		begin
			insert bAPUR (APCo, UIMth, UISeq, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, Rejected)
			select @apco, @uimth, @uiseq, v.Reviewer, 'N', @line, 1, getdate(), 'N'
			from bAPVM v (nolock)
			where v.VendorGroup = @vendorgroup and v.Vendor = @vendor and isnull(v.Reviewer,'') <> ''
			and not exists (select 1 from bAPUR h (nolock) where h.APCo = @apco and h.UIMth = @uimth and h.UISeq = @uiseq
			and h.Line = @line and h.Reviewer = isnull(v.Reviewer,'') and h.APTrans is null and h.ExpMonth is null)
		end
	end
     
	-- add default Reviewer(s) for Job
	if @job is not null 
	begin

		if exists(select 1 from bJCJR where JCCo = @jcco and Job = @job and (ReviewerType = 1 or ReviewerType=3))
		begin
			insert bAPUR (APCo, UIMth, UISeq, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, Rejected)
			select @apco, @uimth, @uiseq, j.Reviewer, 'N', @line, j.Seq, getdate(), 'N'
			from bJCJR j
			where j.JCCo = @jcco and j.Job = @job and ReviewerType in (1, 3) 
			and not exists (select 1 from bAPUR h where h.APCo = @apco and h.UIMth = @uimth and h.UISeq = @uiseq
			and h.Line = @line and h.Reviewer = j.Reviewer and h.APTrans is null and h.ExpMonth is null)
		end
	end
      
	-- add default Reviewer for Equipment
	if @equip is not null
	begin
		if exists(select 1 from bEMDM d join bEMEM e on e.EMCo = d.EMCo and d.Department = e.Department
		where d.EMCo = @emco and e.Equipment = @equip and isnull(d.Reviewer,'') <> '')
		begin

			insert bAPUR (APCo, UIMth, UISeq, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, Rejected)
			select @apco, @uimth, @uiseq, d.Reviewer, 'N', @line, 1, getdate(), 'N'
			from bEMDM d
			join bEMEM e on e.EMCo = d.EMCo and d.Department = e.Department
			where d.EMCo = @emco and e.Equipment = @equip and isnull(d.Reviewer,'') <> ''
			and not exists (select 1 from bAPUR h where h.APCo = @apco and h.UIMth = @uimth and h.UISeq = @uiseq
			and h.Line = @line and h.Reviewer = isnull(d.Reviewer,'') and h.APTrans is null and h.ExpMonth is null)
		end
	end
     
     --add default Reviewer for IN Location 
   	if @loc is not null 
     	begin
		if exists(select 1 from bINLM where INCo = @inco and Loc = @loc and isnull(InvReviewer,'') <> '')
			begin

         insert bAPUR (APCo, UIMth, UISeq, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, Rejected)
         select @apco, @uimth, @uiseq, l.InvReviewer, 'N', @line, 1, getdate(), 'N'
     	from bINLM l
         where l.INCo = @inco and l.Loc = @loc and isnull(l.InvReviewer,'') <> '' 
     		and not exists (select 1 from bAPUR h where h.APCo = @apco and h.UIMth = @uimth and h.UISeq = @uiseq
               and h.Line = @line and h.Reviewer = l.InvReviewer and h.APTrans is null and h.ExpMonth is null)
          end
		end

	--add vendor reviewer to other line types
	if /*@addVendorRevToAllLineTypesYN = 'Y' and*/ @linetype <> 3
		begin

		if exists(select 1 from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor and isnull(Reviewer,'') <> '')
			begin
			insert bAPUR (APCo, UIMth, UISeq, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, Rejected)
			 select @apco, @uimth, @uiseq, v.Reviewer, 'N', @line, 1, getdate(), 'N'
     		from bAPVM v
			 where v.VendorGroup = @vendorgroup and v.Vendor = @vendor and isnull(v.Reviewer,'') <> ''
     			and not exists (select 1 from bAPUR h where h.APCo = @apco and h.UIMth = @uimth and h.UISeq = @uiseq
				   and h.Line = @line and h.Reviewer = isnull(v.Reviewer,'') and h.APTrans is null and h.ExpMonth is null)
			end
		end
	
      
     return

GO
GRANT EXECUTE ON  [dbo].[bspAPUNApprovedReviewerGet] TO [public]
GO
