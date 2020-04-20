SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMDrawingLogRevisionsInsert]
/***********************************************************
* Created:     8/26/09		JB		Rewrote SP/cleanup
* Modified:		GF 09/09/2010 - issue #141031 changed to use function vfDateOnly
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* 
* Description:	Insert a drawing log revision record.
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @DrawingType bDocType,
      @Drawing bDocument,
      @Rev VARCHAR(3),
      @RevisionDate bDate,
      @Status bStatus,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @Description bDesc,
      @RevisionDescription bDesc
    )
AS 
    BEGIN
        SET NOCOUNT ON ;
        DECLARE @DocCat VARCHAR(10),
            @msg VARCHAR(255)
        SET @DocCat = 'DRAWING' 

	--Revision Date Validation
	----#141031
        IF ( @RevisionDate IS NULL ) 
            SET @RevisionDate = dbo.vfDateOnly()

	--Status Code Validation
        IF ( @Status IS NULL ) 
            SET @Status = ( SELECT  [BeginStatus]
                            FROM    [PMCO]
                            WHERE   [PMCo] = @PMCo
                          )
	
        IF ( [dbo].vpfPMValidateStatusCode(@Status, @DocCat) ) = 0 
            BEGIN
                SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '')
                    + ' is not valid for Document Category: ' + ISNULL(@DocCat,
                                                              '') + '.'
                RAISERROR(@msg, 16, 1)
                GOTO vspExit
            END

	--Revision Validation
        IF ( ISNULL(@Rev, '') = ''
             OR @Rev = '+'
             OR @Rev = 'n'
             OR @Rev = 'N'
           ) 
            BEGIN
                SET @Rev = ( SELECT ISNULL(MAX(Rev), 0) + 1
                             FROM   [PMDR] WITH ( NOLOCK )
                             WHERE  [PMCo] = @PMCo
                                    AND [Project] = @Project
                                    AND [DrawingType] = @DrawingType
                                    AND [Drawing] = @Drawing
                           )
            END
        ELSE 
            IF ISNUMERIC(@Rev) <> 1 
                BEGIN
                    SET @msg = 'Invalid Revision.  Revision does not accept text characters.'
                    RAISERROR(@msg, 16, 1)
                    GOTO vspExit
                END
	

        INSERT  INTO PMDR
                ( PMCo,
                  Project,
                  DrawingType,
                  Drawing,
                  Rev,
                  RevisionDate,
                  Status,
                  Notes,
                  UniqueAttchID,
                  Description
		    )
        VALUES  ( @PMCo,
                  @Project,
                  @DrawingType,
                  @Drawing,
                  @Rev,
                  @RevisionDate,
                  @Status,
                  @Notes,
                  @UniqueAttchID,
                  @RevisionDescription
		    )

	--Get the current record
        DECLARE @KeyID INT
        SET @KeyID = SCOPE_IDENTITY()
        EXECUTE vpspPMDrawingLogRevisionsGet @PMCo, @Project, @DrawingType,
            @Drawing, @KeyID

        vspExit:
        RETURN
    END
GO
GRANT EXECUTE ON  [dbo].[vpspPMDrawingLogRevisionsInsert] TO [VCSPortal]
GO
