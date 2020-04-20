SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMDrawingLogRevisionsUpdate]
/***********************************************************
* Created:     8/26/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* 
* Description:	Update a drawing log revision record.
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @DrawingType bDocType,
      @Drawing bDocument,
      @Rev TINYINT,
      @RevisionDate bDate,
      @Status bStatus,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @Description bDesc,
      @RevisionDescription bDesc,
      @KeyID BIGINT,
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_DrawingType bDocType,
      @Original_Drawing bDocument,
      @Original_Rev TINYINT,
      @Original_RevisionDate bDate,
      @Original_Status bStatus,
      @Original_Notes VARCHAR(MAX),
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_Description bDesc,
      @Original_RevisionDescription bDesc,
      @Original_KeyID BIGINT
    )
AS 
    BEGIN
        SET NOCOUNT ON ;
        DECLARE @DocCat VARCHAR(10),
            @msg VARCHAR(255)
        SET @DocCat = 'DRAWING'
	
	--Status Code Validation
        IF ( [dbo].vpfPMValidateStatusCode(@Status, @DocCat) ) = 0 
            BEGIN
                SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '')
                    + ' is not valid for Document Category: ' + ISNULL(@DocCat,
                                                              '') + '.'
                RAISERROR(@msg, 16, 1)
                GOTO vspExit
            END
	
	--Update the drawing revision
        UPDATE  PMDR
        SET     RevisionDate = @RevisionDate,
                Status = @Status,
                Notes = @Notes,
                UniqueAttchID = @UniqueAttchID,
                Description = @RevisionDescription
        WHERE   ( PMCo = @Original_PMCo )
                AND ( Project = @Original_Project )
                AND ( DrawingType = @Original_DrawingType )
                AND ( Drawing = @Original_Drawing )
                AND ( Rev = @Original_Rev )
	
	--Get the current record        EXECUTE vpspPMDrawingLogRevisionsGet @PMCo, @Project, @DrawingType,
            @Drawing, @KeyID	        vspExit:    END
GO
GRANT EXECUTE ON  [dbo].[vpspPMDrawingLogRevisionsUpdate] TO [VCSPortal]
GO
