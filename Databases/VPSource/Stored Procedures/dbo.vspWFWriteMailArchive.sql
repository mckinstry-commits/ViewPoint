SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Charles Courchaine
-- Create date: 2/6/2008
-- Description:	Saves messages to the vMailQueueArchive table
-- =============================================
CREATE PROCEDURE [dbo].[vspWFWriteMailArchive] 
	-- Add the parameters for the stored procedure here
	@To varchar(3000),
	@CC varchar(3000) = NULL,
	@BCC varchar(3000) = NULL,
	@From varchar(3000) = NULL,
	@Subject varchar(3000),
	@Body text,
	@Attempts int,
	@FailureDate datetime,
	@FailureReason varchar(3000),
	@Source varchar (30),
	@Success bYN,
	@SentDate datetime = null,
    @AttachIDs varchar(max) = null,
    @UniqueAttchID varchar(max) = null,
    @AttachFiles varchar(max) = null,
	@HasAttachments bYN = null,
	@TokenID int = null,
	@VPUserName bVPUserName = null

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    insert into vMailQueueArchive (SentTo, CC, BCC, SentFrom, Subject, Body, Attempts, FailureDate, FailureReason, Source, Sent, SentDate, AttachIDs, UniqueAttchID, AttachFiles, HasAttachments, TokenID, VPUserName) values (@To, @CC, @BCC, @From, @Subject, @Body, @Attempts, @FailureDate, @FailureReason, @Source, @Success, @SentDate, @AttachIDs, @UniqueAttchID, @AttachFiles, @HasAttachments, @TokenID, @VPUserName )
END

GO
GRANT EXECUTE ON  [dbo].[vspWFWriteMailArchive] TO [public]
GO
