SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMOtherDocumentsInsert]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:	   2011/09/15 AMR - TK-08520 - changing bNotes to VARCHAR(MAX)
*              2011/11/27 TEJ - Modifying to reflect a change of Description to DocumentDescription
*
* Description:	Insert an other document.
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
      @Issue bIssue,
      @Status bStatus,
      @ResponsibleFirm bFirm,
      @ResponsiblePerson bEmployee,
      @DateDue bDate,
      @DateRecd bDate,
      @DateSent bDate,
      @DateDueBack bDate,
      @DateRecdBack bDate,
      @DateRetd bDate,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER

    )
AS 
    BEGIN
        SET NOCOUNT ON ;

        DECLARE @nextDocument INT,
            @DocCat VARCHAR(10),
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
	
	--Document Validation
        IF ( ISNULL(@Document, '') = '' )
            OR @Document = '+'
            OR @Document = 'n'
            OR @Document = 'N' 
            BEGIN
                SET @nextDocument = ( SELECT    ISNULL(MAX(Document), 0) + 1
                                      FROM      PMOD WITH ( NOLOCK )
                                      WHERE     PMCo = @PMCo
                                                AND Project = @Project
                                                AND DocType = @DocType
                                                AND ISNUMERIC(Document) = 1
                                                AND Document NOT LIKE '%.%'
                                                AND SUBSTRING(LTRIM(Document),
                                                              1, 1) <> '0'
                                    )
                SET @msg = NULL
                EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @nextDocument,
                    @msg OUTPUT
                SET @Document = @msg
            END
        ELSE 
            BEGIN
                SET @msg = NULL
                EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @Document,
                    @msg OUTPUT
                SET @Document = @msg
            END

	--Insert the other document
        INSERT  INTO PMOD
                ( PMCo,
                  Project,
                  DocType,
                  Document,
                  Description,
                  Location,
                  VendorGroup,
                  RelatedFirm,
                  ResponsibleFirm,
                  ResponsiblePerson,
                  Issue,
                  Status,
                  DateDue,
                  DateRecd,
                  DateSent,
                  DateDueBack,
                  DateRecdBack,
                  DateRetd,
                  Notes,
                  UniqueAttchID
		    )
        VALUES  ( @PMCo,
                  @Project,
                  @DocType,
                  @Document,
                  @DocumentDescription,
                  @Location,
                  @VendorGroup,
                  @RelatedFirm,
                  @ResponsibleFirm,
                  @ResponsiblePerson,
                  @Issue,
                  @Status,
                  @DateDue,
                  @DateRecd,
                  @DateSent,
                  @DateDueBack,
                  @DateRecdBack,
                  @DateRetd,
                  @Notes,
                  @UniqueAttchID
		    )

	--Get the updated current record
        DECLARE @KeyID BIGINT
        SET @KeyID = SCOPE_IDENTITY()
        EXECUTE vpspPMOtherDocumentsGet @PMCo, @Project, @VendorGroup,
            @ResponsibleFirm, @KeyID
	
        vspExit:
    END
GO
GRANT EXECUTE ON  [dbo].[vpspPMOtherDocumentsInsert] TO [VCSPortal]
GO
