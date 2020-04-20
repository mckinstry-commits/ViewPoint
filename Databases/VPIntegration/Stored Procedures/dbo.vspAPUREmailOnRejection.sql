SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspAPUREmailOnRejection]
   /***************************************************
   *    Created:	MV 01/21/08 - #29702 Unapproved Enhancement
   *	Modified:	CC 02/26/2009 - #128583 Add AP Unapproved source to mail queue insertions
   *				GF 07/24/22012 TK-16602 expand originator to bVPUserName
   *
   *    Purpose: Called from APUnappInvRev when a reviewer rejects an invoice.
   *	If any of the three email on rejection flags in bHQRG are checked then
   *	email the designated people: invoice originator, responsible person, all
   *    reviewers who have approved the line.  
   *
   *    Input:
   *        @apco
   *        @uimth
   *        @uiseq
   *		@source 'H' for header or 'L' for line
   *		@line 
   *
   *    output:
   *		@msg on error
   *            
   ****************************************************/
   (@apco bCompany, @uimth bMonth, @uiseq int, @source varchar(31),@line int = null,
	@reviewergroup varchar(10), @formreviewer varchar(3),@login varchar(20),@msg varchar(200) = null output)
   
   as
   set nocount on

	declare @rcode int, @emailinvoriginator bYN, @emailrespperson bYN, @emailreviewers bYN ,@EmailTo varchar(3000),
	@EmailFrom varchar(3000), @EmailSubject varchar(3000), @EmailBody varchar(max), @ReviewerName as varchar(30),
	@vendorname varchar(50), @apref bAPReference, @opencursor int,@emailreviewer varchar(3),
	----TK-16602
	@originator bVPUserName,@responsibleperson varchar(3)

   select @rcode = 0, @opencursor = 0
	
	--Get flags from vHQRG
	select @emailinvoriginator=EmailOptOnRejOriginator,@emailrespperson=EmailOptOnRejResponsiblePerson,
			@emailreviewers=EmailOptOnRejReviewerApproved,@responsibleperson=ResponsiblePerson 
	from HQRG with (nolock) where ReviewerGroup=@reviewergroup
	--Get Reviewers name
	select @ReviewerName = Name from HQRV where Reviewer=@formreviewer
	--Get Vendor name and APRef
		select @vendorname=m.Name, @apref=i.APRef from APUI i with (nolock) join APVM m on i.VendorGroup=m.VendorGroup and
		i.Vendor=m.Vendor 
		where i.APCo=@apco and i.UIMth=@uimth and i.UISeq=@uiseq
		

	--set up Email Subject, Body, From
	 select @EmailSubject = 'Invoice Rejected ' 
	 select @EmailBody = 'Reviewer: ' + isnull(@ReviewerName, @formreviewer) + ' has rejected the invoice for Vendor: ' +
		@vendorname + ' Inv #: ' + isnull(@apref,'')
	 select @EmailFrom = EMail from DDUP with (nolock) where VPUserName=@login 
	 if @EmailFrom is null select @EmailFrom=''

	-- LINE LEVEL EMAILS - reviewer rejected a single line
	if @source = 'L' and @line is not null 
	begin
		-- add Line to Email Subject and Body
		select @EmailBody = @EmailBody + ' on Line: ' + convert(varchar(10),@line)
		--email the invoice originator
		if @emailinvoriginator = 'Y' 
		begin
			-- set up Email To from invoice orignator (login) in APUL, get email address from user preferences
			select @EmailTo = d.EMail from APUL l with (nolock) join DDUP d with (nolock) on l.InvOriginator=d.VPUserName
				where APCo=@apco and UIMth=@uimth and UISeq=@uiseq and Line=@line
			if @EmailTo is not null 
			begin
			INSERT into vMailQueue ([To],[From],[Subject],[Body], [Source]) VALUES (@EmailTo, @EmailFrom,@EmailSubject,@EmailBody, 'AP Unapproved')
			end
		end

		-- email the responsible person 
		if @emailrespperson = 'Y' 
		begin
			-- set up Email To from email address in HQRV for the responsible person 
			select @EmailTo = RevEmail from HQRV with (nolock) join HQRG with (nolock)on HQRV.Reviewer=HQRG.ResponsiblePerson
				where HQRG.ReviewerGroup=@reviewergroup
			if @EmailTo is not null 
			begin
			INSERT into vMailQueue ([To],[From],[Subject],[Body], [Source]) VALUES(@EmailTo, @EmailFrom,@EmailSubject,@EmailBody, 'AP Unapproved')
			end
		end
		-- email all reviewers who have approved this line
		if @emailreviewers = 'Y'
		begin
		-- if there are approved invoices, email the reviewers othewise exit 
		if exists (select 1 from APUR with (nolock) where APCo=@apco and UIMth=@uimth and UISeq=@uiseq and 
			Line=@line and ApprvdYN='Y') 
			begin
			declare vcCursor1 cursor local fast_forward for
			select Reviewer	from bAPUR where APCo=@apco and UIMth=@uimth and UISeq=@uiseq 
				and Line = @line and ApprvdYN='Y' and Reviewer <> @formreviewer and APTrans is null
			open vcCursor1
			select @opencursor = 1
			Cursor1_loop:
				-- get the next reviewer
				fetch next from vcCursor1 into @emailreviewer
				if @@fetch_status <> 0 goto Cursor1_end
				-- set up Email To from the email address in HQRV
				select @EmailTo = RevEmail from HQRV with (nolock) where Reviewer=@emailreviewer
				if @EmailTo is not null
				begin
				INSERT into vMailQueue ([To],[From],[Subject],[Body], [Source]) VALUES(@EmailTo, @EmailFrom,@EmailSubject,@EmailBody, 'AP Unapproved')	
				end
				goto Cursor1_loop
			 end
			Cursor1_end:
				if @opencursor = 1
				begin
					close vcCursor1
					deallocate vcCursor1
					select @opencursor = 0
				end
		else goto vsp_exit -- no reviewers have approved this line so we're finished - exit
		end
		
	end	-- END LINE LEVEL EMAILS

	-- HEADER LEVEL EMAILS - reviewer rejected the invoice (all lines)
	if @source = 'H' 
	begin
		--email the invoice originator
		if @emailinvoriginator = 'Y' 
		begin
			-- get invoice originator from APUL for each line
			declare vcCursor2 cursor local fast_forward for
			select DISTINCT InvOriginator from APUL with (nolock) where APCo=@apco and UIMth=@uimth and UISeq=@uiseq 
			open vcCursor2
			select @opencursor = 1
			Cursor2_loop:
				--get invoice originator (login)
				fetch next from vcCursor2 into @originator
				if @@fetch_status <> 0 goto Cursor2_end
				--get the originator's email address from User Preferences
				select @EmailTo = EMail from DDUP with(nolock) where VPUserName=@originator
			if @EmailTo is not null 
			begin
				INSERT into vMailQueue ([To],[From],[Subject],[Body], [Source]) VALUES(@EmailTo, @EmailFrom,@EmailSubject,@EmailBody, 'AP Unapproved')	
				goto Cursor2_loop
			end
			Cursor2_end:
			if @opencursor = 1
			begin
				close vcCursor2
				deallocate vcCursor2
				select @opencursor = 0
			end
		end
		-- email the responsible person 
		if @emailrespperson = 'Y' 
		begin
			-- get Email address from HQRV for this responsible person 
			select @EmailTo = RevEmail from HQRV with (nolock) join HQRG with (nolock)on HQRV.Reviewer=HQRG.ResponsiblePerson
				where HQRG.ReviewerGroup=@reviewergroup
			if @EmailTo is not null 
			begin
			-- add Email to vMailQueue
			INSERT into vMailQueue ([To],[From],[Subject],[Body], [Source]) VALUES(@EmailTo, @EmailFrom,@EmailSubject,@EmailBody, 'AP Unapproved')
			end
		end
		-- email all reviewers who have approved this invoice
		if @emailreviewers = 'Y'
		begin
		-- if there are approved invoices email those reviewers othewise exit 
		if exists (select 1 from APUR with (nolock) where APCo=@apco and UIMth=@uimth and UISeq=@uiseq and 
			Line<> -1 and ApprvdYN='Y') 
			begin
			declare vcCursor3 cursor local fast_forward for
			select DISTINCT Reviewer from bAPUR where APCo=@apco and UIMth=@uimth and UISeq=@uiseq 
				and Line<> -1 and ApprvdYN='Y' and APTrans is null
			open vcCursor3
			select @opencursor = 1
			vcCursor3_loop:
				-- get the next reviewer
				fetch next from vcCursor3 into @emailreviewer
				if @@fetch_status <> 0 goto vcCursor3_end
				-- get Email address from HQRV for this reviewer
				select @EmailTo = RevEmail from HQRV with (nolock) where Reviewer=@emailreviewer
				if @EmailTo is not null
				begin
				INSERT into vMailQueue ([To],[From],[Subject],[Body], [Source]) VALUES(@EmailTo, @EmailFrom,@EmailSubject,@EmailBody, 'AP Unapproved')	
				end
				goto vcCursor3_loop
			 end
			vcCursor3_end:
				if @opencursor = 1
				begin
					close vcCursor3
					deallocate vcCursor3
					select @opencursor = 0
				end
		else goto vsp_exit -- no reviewers have approved this line so we're finished - exit
		end
	end	-- END HEADER LEVEL EMAILS

	

	vsp_exit:
    Return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspAPUREmailOnRejection] TO [public]
GO
