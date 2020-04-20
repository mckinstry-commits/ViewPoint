SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMOtherDocumentsUpdate]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*              2011/11/27 TEJ - Modifying to reflect a change of Description to DocumentDescription
* 
* Description:	Update an other document.
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @DocType bDocType,
      @Document bDocument,
      @DocumentDescription bItemDesc,
      @Location VARCHAR(60),
      @VendorGroup bGroup,
      @RelatedFirm bFirm,
      @ResponsibleFirm bFirm,
      @ResponsiblePerson bEmployee,
      @Issue bIssue,
      @Status bStatus,
      @DateDue bDate,
      @DateRecd bDate,
      @DateSent bDate,
      @DateDueBack bDate,
      @DateRecdBack bDate,
      @DateRetd bDate,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @KeyID BIGINT,
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_DocType bDocType,
      @Original_Document bDocument,
      @Original_DocumentDescription bDesc,
      @Original_Location VARCHAR(60),
      @Original_VendorGroup bGroup,
      @Original_RelatedFirm bFirm,
      @Original_ResponsibleFirm bFirm,
      @Original_ResponsiblePerson bEmployee,
      @Original_Issue bIssue,
      @Original_Status bStatus,
      @Original_DateDue bDate,
      @Original_DateRecd bDate,
      @Original_DateSent bDate,
      @Original_DateDueBack bDate,
      @Original_DateRecdBack bDate,
      @Original_DateRetd bDate,
      @Original_Notes VARCHAR(MAX),
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_KeyID BIGINT

    )
AS 
    BEGIN
        SET NOCOUNT ON ;
	
        DECLARE @DocCat VARCHAR(10),
            @msg VARCHAR(255)
        SET @DocCat = 'OTHER'

	--Status Code Validation
        IF ( [dbo].vpfPMValidateStatusCode(@Status, @DocCat) ) = 0 
            BEGIN
                SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '')
                    + ' is not valid for Document Category: ' + ISNULL(@DocCat,
                                                              '') + '.'
                RAISERROR(@msg, 16, 1)
                GOTO vspExit
            END
	
	--Related Firm Validation
        IF @RelatedFirm = -1 
            SET @RelatedFirm = NULL
	
	--Responsible Firm Validation
        IF @ResponsibleFirm = -1 
            SET @ResponsibleFirm = NULL

	--Responsible Person Validation
        IF @ResponsiblePerson = -1 
            SET @ResponsiblePerson = NULL
	
	--Issue Validation
        IF @Issue = -1 
            SET @Issue = NULL

        UPDATE  PMOD
        SET     Description = @DocumentDescription,
                Location = @Location,
                VendorGroup = @VendorGroup,
                RelatedFirm = @RelatedFirm,
                ResponsiblePerson = @ResponsiblePerson,
                Issue = @Issue,
                Status = @Status,
                DateDue = @DateDue,
                DateRecd = @DateRecd,
                DateSent = @DateSent,
                DateDueBack = @DateDueBack,
                DateRecdBack = @DateRecdBack,
                DateRetd = @DateRetd,
                Notes = @Notes,
                UniqueAttchID = @UniqueAttchID
        WHERE   ( PMCo = @Original_PMCo )
                AND ( Project = @Original_Project )
                AND ( DocType = @Original_DocType )
                AND ( Document = @Original_Document )
		
	
	--Get the updated current record
        EXECUTE vpspPMOtherDocumentsGet @PMCo, @Project, @VendorGroup,
            @ResponsibleFirm, @KeyID
	
        vspExit:
    END
	



GO
GRANT EXECUTE ON  [dbo].[vpspPMOtherDocumentsUpdate] TO [VCSPortal]
GO
