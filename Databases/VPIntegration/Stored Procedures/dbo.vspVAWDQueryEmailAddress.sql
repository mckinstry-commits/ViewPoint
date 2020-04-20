SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspVAWDQueryEmailAddress]
  /************************************************************************
  * CREATED: 	HH 11/15/12 		B-11732
  * MODIFIED:   
  *
  * Purpose of Stored Procedure:	Return all email addresses for WF Notifier 
  *									Job Manager.  
  * 
  *
  * returns 0 if successfull 
  * returns 1 and error msg if failed
  *
  *************************************************************************/
          
(@ContactType int = 0)

as
set nocount on

DECLARE @rcode int
SET @rcode = 0

BEGIN TRY

	;WITH ContactEmails
	AS
	(
		SELECT DISTINCT Name, EMail, 'AP Vendor' as ContactType
		FROM APVM 
		WHERE EMail IS NOT NULL AND EMail <> ''
	
		UNION ALL
		
		SELECT DISTINCT Name, EMail, 'AR Customer' as ContactType
		FROM ARCM 
		WHERE EMail IS NOT NULL AND EMail <> ''
		
		UNION ALL
		
		SELECT DISTINCT FirstName + ISNULL(' ' + MiddleInitial + ' ',' ') +  LastName, Email, 'HQ Contacts' as ContactType
		FROM HQContact
		WHERE Email IS NOT NULL AND Email <> ''
		
		UNION ALL
		
		SELECT DISTINCT Name, Email, 'Project Manager' as ContactType
		FROM JCMP 
		WHERE Email IS NOT NULL AND Email <> ''
		
		UNION ALL
		
		SELECT DISTINCT ContactName, EMail, 'PM Firm Contact for AP/AR' as ContactType
		FROM PMFM
		WHERE EMail IS NOT NULL AND EMail <> ''
	
		UNION ALL
		
		SELECT DISTINCT FirstName + ISNULL(' ' + MiddleInit + ' ',' ') +  LastName, EMail, 'PM Firm Contact' as ContactType
		FROM PMPM
		WHERE EMail IS NOT NULL AND EMail <> ''
		
		UNION ALL
		
		SELECT DISTINCT FirstName + ISNULL(' ' + MidName + ' ',' ') +  LastName, Email, 'PR Employee' as ContactType
		FROM PREH
		WHERE Email IS NOT NULL AND Email <> ''
	
		UNION ALL
		
		SELECT DISTINCT FullName, EMail, 'VA User' as ContactType
		FROM DDUP
		WHERE EMail IS NOT NULL AND EMail <> ''
		
		UNION ALL
		
		SELECT DISTINCT Name, Email, 'PC Contacts' as ContactType
		FROM PCContacts
		WHERE Email IS NOT NULL AND Email <> ''
		
		UNION ALL
		
		SELECT DISTINCT ServiceCenter + ' ' + [Description], EMail, 'SM Service Center' as ContactType
		FROM SMServiceCenter
		WHERE EMail IS NOT NULL AND EMail <> ''
	)
	SELECT	ce1.Name
			,ce1.EMail
			,Stuff((SELECT ' / ' + ContactType 
						FROM   ContactEmails ce2 
						WHERE  ce1.Name = ce2.Name 
								AND ce1.EMail = ce2.EMail 
						ORDER BY ce2.ContactType								
						FOR XML PATH('')), 1, 2, '') [ContactType] 
	FROM ContactEmails ce1
	WHERE Name <> ''
	GROUP  BY Name, EMail
	ORDER BY Name
		
END TRY
BEGIN CATCH
    
     SET @rcode = 1
     
END CATCH

bspexit:
RETURN @rcode








GO
GRANT EXECUTE ON  [dbo].[vspVAWDQueryEmailAddress] TO [public]
GO
