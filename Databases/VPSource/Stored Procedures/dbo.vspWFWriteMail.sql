SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Charles Courchaine
-- Create date: 2/6/2008
-- Description:	Saves messages to the vWFMail table
-- =============================================
CREATE PROCEDURE [dbo].[vspWFWriteMail] 
	-- Add the parameters for the stored procedure here
	@User bVPUserName,
	@To varchar(3000),
	@CC varchar(3000) = NULL,
	@BCC varchar(3000) = NULL,
	@From varchar(3000) = NULL,
	@Subject varchar(3000),
	@Body text,
	@Source varchar (30),
    @AttachIDs varchar(max) = null,
    @UniqueAttchID varchar(max) = null,
    @AttachFiles varchar(max) = null,
	@HasAttachments bYN = null


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    INSERT INTO vWFMail([UserID], [SentTo], CC, BCC, [From], [Subject], Body, Source, AttachIDs, AttachFiles, UniqueAttchID, HasAttachments) VALUES (@User, @To, @CC, @BCC, @From, @Subject, @Body, @Source, @AttachIDs, @AttachFiles, @UniqueAttchID, @HasAttachments);
END

GO
GRANT EXECUTE ON  [dbo].[vspWFWriteMail] TO [public]
GO
