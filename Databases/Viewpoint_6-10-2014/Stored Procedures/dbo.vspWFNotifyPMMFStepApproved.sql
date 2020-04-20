SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************
* Author:		Nels H.
* Create date:  5/24/2012
* Description:	Sends notification of a step approval to the PO originator
*				as part of the PMMF PO approval process
* Modified:		5/30/2012 - Nels H. - updated comments that were not correct
*									- updated the text of the email
*				6/08/2012 - Nels H. - improved formatting for VP messaging
*				6/21/2012 - Nels H. - changed message based on PM feedback
*
*	Inputs:
*	@SourceParentKeyID	KeyID from Pending PO header record
*	@POStatus			Indicates if PO approval is complete
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFNotifyPMMFStepApproved] 
	-- Add the parameters for the stored procedure here
	@SourceParentKeyID bigint,
	@POStatus varchar(8)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Insert statements for procedure here
    declare @PO varchar(30), @EMailTo varchar(60), @FullName varchar(60),
	@EMailSubject varchar(60), @EMailBody varchar(255)
	
	select @EMailTo = userInfo.EMail, @FullName = userInfo.FullName,
		@PO = item.PO
	-- The first two joins provide all the data on the approval process
	from dbo.vWFProcessDetail detail 
	join dbo.vWFProcessDetailStep step on step.ProcessDetailID = detail.KeyID
	-- This join gives us the needed PO data, replace this for other approval types
	join dbo.bPMMF item on item.KeyID = detail.SourceKeyID
	-- This allows us to filter by header PO record
	join dbo.bPOHD header on header.JCCo = item.PMCo and header.Job = item.Project
		and header.POCo = item.POCo and header.PO = item.PO
	-- Finally this one gives us the needed user data to send an email
	join dbo.vDDUP userInfo on detail.InitiatedBy = userInfo.VPUserName
	where detail.SourceView = 'PMMF'
		and step.KeyID = detail.CurrentStepID
		and header.KeyID = @SourceParentKeyID
		and userInfo.EMail is not null
	order by item.POItem	
	
	--set up Email Subject, Body, From
	if @POStatus = 'approved'
		begin
			select @EMailSubject = 'Purchase order ' + @PO + ' has been fully approved.'
			select @EMailBody = isnull(nullif(@FullName, ''), 'Viewpoint User') + ',' +
						char(13) + char(10) + char(13) + char(10) +	@EMailSubject
		end
	else
		begin
			select @EMailSubject = 'Purchase order ' + @PO + ' has moved to a new step.'
			select @EMailBody = isnull(nullif(@FullName, ''), 'Viewpoint User') + ',' +
						char(13) + char(10) + char(13) + char(10) +
						@EMailSubject + char(13) + char(10) + char(13) + char(10) +
						'You can review the document in your Work Center.'
		end

	--currently the from field is left blank, should use customer default
	insert into vMailQueue ([To],[From],[Subject],[Body], [Source])
	values (@EMailTo, '', @EMailSubject, @EMailBody, 'Workflow')

END

GO
GRANT EXECUTE ON  [dbo].[vspWFNotifyPMMFStepApproved] TO [public]
GO
