SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [dbo].[vf_PMRFIResponseText]
(
 @PMCo int,
 @Project varchar(10),
 @RFIType varchar(10),
 @RFI varchar(10)
 )

/******
 Created:  DH 8/24/10
 Modified: AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
  			TRL 03/30/11 TK-03409, Changed Join State on select statement to PMSC.  PMRFIResponse Status
				column no longer has to match PMRFI Status.  The Left Join allows for all reponse records to 
				show in the Response field in PMRFI
			GP 8/8/2011 - TK-07559 cast PMRFIResponse.Notes to smaller varchar so all responses will appear
			GP 8/11/2011 - TK-07631 removed time from LastDate select
			
 Usage:  Function returns concatenated fields from PMRFIResponse view formatted with carriage
		 returns and lines.  Used in the PM Request for Information Responses read-only text box.

		 
 Input Parameters:
	@PMCo
	@Project
	@RFIType
	@RFI

 Output:  Concatenated fields of Status, Contact, LastDate and Response Text from
		  PM RFI Response data			 
******/
RETURNS @ResponseText TABLE
(
  ResponseText varchar(max) NOT NULL
)
AS 
BEGIN

    DECLARE @responsetxt varchar(max)

    SELECT  @responsetxt = +ISNULL(@responsetxt, '') + 'Status:  '
            + ISNULL(PMSC.Description, '') + CHAR(13) + CHAR(10)						--Carriage return and line feed
            + 'From:  ' + ISNULL(PMPM.FirstName, '') + ' '
            + ISNULL(PMPM.LastName, '') + CHAR(13) + CHAR(10) + 'Date:  '
            + ISNULL(CAST(LastDate AS VARCHAR(11)), '')
            + CHAR(13) + CHAR(10) + 'Response:  ' + CHAR(13) + CHAR(10)
            + CHAR(13) + CHAR(10) + '   ' + ISNULL(CAST(PMRFIResponse.Notes AS VARCHAR(255)), '')
            + CHAR(13) + CHAR(10)
            + '________________________________________________' + CHAR(13)
            + CHAR(10)
    FROM    PMRFIResponse
            LEFT JOIN PMSC ON PMSC.Status = PMRFIResponse.Status
            LEFT OUTER JOIN PMPM ON PMPM.VendorGroup = PMRFIResponse.VendorGroup
                                    AND PMPM.FirmNumber = PMRFIResponse.RespondFirm
                                    AND PMPM.ContactCode = PMRFIResponse.RespondContact
    WHERE   PMRFIResponse.PMCo = @PMCo
            AND PMRFIResponse.Project = @Project
            AND PMRFIResponse.RFIType = @RFIType
            AND PMRFIResponse.RFI = @RFI
    ORDER BY PMRFIResponse.KeyID DESC

    INSERT  INTO @ResponseText
    VALUES  ( ISNULL(@responsetxt, '') )
			
    RETURN
END
 





GO
GRANT SELECT ON  [dbo].[vf_PMRFIResponseText] TO [public]
GO
