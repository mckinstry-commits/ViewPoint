SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************
* Author:		Nels H.
* Create date:  5/29/2012
* Description:	Sends notification of a rejection to the PO originator
*				as part of PO approval process
* Modified:		6/01/2012 - Nels H. - added comments from history table
*				6/05/2012 - Nels H. - added a sort by date to the comments
*									- updated the text of the email
*				6/08/2012 - Nels H. - improved formatting for VP messaging
*
*	Inputs:
*	@SourceParentKeyID	KeyID from Pending PO header record
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFNotifyPMMFRejected] 
	-- Add the parameters for the stored procedure here
	@SourceParentKeyID bigint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Insert statements for procedure here
    declare @PO varchar(30), @EMailTo varchar(128), @FullName varchar(128),
	@EMailSubject varchar(128), @EMailBody varchar(max), @Comment varchar(max),
	@Approver varchar(128), @CommentTime varchar(30), @SeqCounter int
	
	-- Declare table variable to store Comments
	declare @CommentTable table
	(
		Seq int identity(1,1),
		KeyID bigint not null,
		Approver bVPUserName null,
		Comment bNotes not null,
		CommentTime datetime
	)
	
	select distinct @EMailTo = userInfo.EMail, @FullName = userInfo.FullName, @PO = item.PO
	-- The first three joins provide all the data on the approval process
	from dbo.vWFProcessDetail detail 
	join dbo.vWFProcessDetailStep step on step.ProcessDetailID = detail.KeyID
	join dbo.vWFProcessDetailApprover approver on approver.DetailStepID = step.KeyID
	-- This join gives us the needed PO data, replace this for other approval types
	join dbo.bPMMF item on item.KeyID = detail.SourceKeyID
	-- This allows us to filter by header PO record
	join dbo.bPOHD header on header.JCCo = item.PMCo and header.Job = item.Project
		and header.POCo = item.POCo and header.PO = item.PO
	-- Finally this one gives us the needed user data to send an email
	join dbo.vDDUP userInfo on detail.InitiatedBy = userInfo.VPUserName
	where detail.SourceView = 'PMMF'
		and header.KeyID = @SourceParentKeyID
		and userInfo.EMail is not null
	
	--get all of the comments and store them in a temp table
	insert @CommentTable (KeyID, Approver, Comment, CommentTime)
	select approverhistory.KeyID, approverhistory.Approver,
	--we only want the most recent comment for each user/item
	max(approverhistory.Comments) as [Comment], max(approverhistory.DateTime) as [CommentTime]
	from POHDPM poheader
	join WFProcessHeader wfheader on wfheader.SourceKeyID = poheader.KeyID
		and wfheader.SourceView = 'POHDPM'
	join WFProcessDetail wfdetail on wfdetail.HeaderID = wfheader.KeyID
	join WFProcessDetailHistory detailhistory on detailhistory.KeyID = wfdetail.KeyID
		and detailhistory.Action = 'INSERT'
	join WFProcessDetailStepHistory stephistory on stephistory.ProcessDetailID = detailhistory.KeyID
		and detailhistory.Action = 'INSERT'
	join WFProcessDetailApproverHistory approverhistory on approverhistory.DetailStepID = stephistory.KeyID
		and approverhistory.Action = 'UPDATE'
		and approverhistory.FieldName = 'Comments'
	where poheader.KeyID  = @SourceParentKeyID
	group by approverhistory.KeyID, approverhistory.Approver
	order by CommentTime desc
	
	--set up Email Subject, Body
	select @EMailSubject = 'Purchase order ' + @PO + ' has been rejected' 
	select @EMailBody = isnull(nullif(@FullName, ''), 'Viewpoint User') + ',' +
						char(13) + char(10) + char(13) + char(10) +
						'Purchase order ' + @PO + ' has not passed the approval process.' +
						char(13) + char(10) + char(13) + char(10) +
						'You can review the document in your Work Center.'

	-- Loop through each comment
	set @SeqCounter = 1
	while @SeqCounter <= (select max(Seq) from @CommentTable)
		begin
			--Get comments to add to notification
			select @Approver = cast(Approver as varchar(128)),
				   @Comment = cast(Comment as varchar(max)),
				   @CommentTime = cast(CommentTime as varchar(30))
			from @CommentTable
			where Seq = @SeqCounter
			--Append comment header on first pass through the loop
			if @SeqCounter = 1
				begin
					select @EMailBody = @EMailBody +
										char(13) + char(10) + char(13) + char(10) +
										'Comments:' + char(13) + char(10)
				end
			--Append comments to the EMailBody
			select @EMailBody = @EMailBody + @Comment + char(13) + char(10) +
				   @Approver + ' - ' + @CommentTime + char(13) + char(10)
			
			set @SeqCounter = @SeqCounter + 1
		end

	--currently the from field is left blank, should use customer default
	insert into vMailQueue ([To],[From],[Subject],[Body], [Source])
	values (@EMailTo, '', @EMailSubject, @EMailBody, 'Workflow')

END

GO
GRANT EXECUTE ON  [dbo].[vspWFNotifyPMMFRejected] TO [public]
GO
