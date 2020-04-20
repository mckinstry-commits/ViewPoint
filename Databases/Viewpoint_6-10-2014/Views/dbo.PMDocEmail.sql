SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PMDocEmail]
AS
WITH EmailInformation(AttachmentID, [From], [To], [CC], [Subject], SentDate, ReceivedDate)
AS
(
	SELECT HQAI.AttachmentID, EmailFromAddress AS [From], EmailToAddresses AS [To], EmailCCAddresses AS [CC], EmailSubject AS [Subject], EmailSentDate, EmailReceivedDate
	FROM HQAT 
	INNER JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
	WHERE IsEmail = 'Y' AND IsEmailIndex = 1 AND CurrentState <> 'D'
)

SELECT HQAI.AttachmentID, [From], [To], [CC], [Subject], EmailInformation.SentDate, EmailInformation.ReceivedDate, HQAI.JCJob AS Project, HQAI.JCCo AS PMCo
FROM HQAI
INNER JOIN EmailInformation ON EmailInformation.AttachmentID = HQAI.AttachmentID;



GO
GRANT SELECT ON  [dbo].[PMDocEmail] TO [public]
GRANT INSERT ON  [dbo].[PMDocEmail] TO [public]
GRANT DELETE ON  [dbo].[PMDocEmail] TO [public]
GRANT UPDATE ON  [dbo].[PMDocEmail] TO [public]
GRANT SELECT ON  [dbo].[PMDocEmail] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMDocEmail] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMDocEmail] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMDocEmail] TO [Viewpoint]
GO
