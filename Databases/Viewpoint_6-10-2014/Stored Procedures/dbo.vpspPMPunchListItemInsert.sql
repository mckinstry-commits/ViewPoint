SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vpspPMPunchListItemInsert]
/************************************************************
* CREATED:		2/28/06		CHS
* MODIFIED:		10/30/06	chs
* MODIFIED:		6/5/07		chs
* MODIFIED:		6/27/07		chs
				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   Inserts PM Punch List Item releated to a passed in Company
*	and Job
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo and Job 
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @PunchList bDocument,
	--@Item smallint,
      @Item VARCHAR(5),
      @Description VARCHAR(255),
      @VendorGroup bGroup,
      @ResponsibleFirm bFirm,
      @Location VARCHAR(10),
      @DueDate bDate,
      @FinDate bDate,
      @BillableYN bYN,
      @BillableFirm bFirm,
      @Issue bIssue,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    SET NOCOUNT ON ;
	

    DECLARE @rcode INT,
        @nextInspectionCode INT,
        @msg VARCHAR(255),
        @message VARCHAR(255)
	
    SELECT  @rcode = 0,
            @message = ''

	
    IF @Issue = -1 
        SET @Issue = NULL
    IF @BillableFirm = -1 
        SET @BillableFirm = NULL
    IF @ResponsibleFirm = -1 
        SET @ResponsibleFirm = NULL


--IF @Item is null
    IF ( ISNULL(@Item, '') = '' )
        OR @Item = '+'
        OR @Item = 'n'
        OR @Item = 'N' 
        BEGIN
		-- test for non-numeric characters
            IF ISNUMERIC(@Item) = 1 
                BEGIN
                    SET @Item = ( SELECT    ISNULL(( MAX(Item) + 1 ), 1)
                                  FROM      PMPI WITH ( NOLOCK )
                                  WHERE     PMCo = @PMCo
                                            AND PunchList = @PunchList
                                            AND Project = @Project
                                )
                END
            ELSE 
                BEGIN
                    SELECT  @rcode = 1,
                            @message = 'Item Code does not accept text characters. Please use another Code.'
                    GOTO bspmessage
                END
        END

    INSERT  INTO PMPI
            ( PMCo,
              Project,
              PunchList,
              Item,
              Description,
              VendorGroup,
              ResponsibleFirm,
              Location,
              DueDate,
              FinDate,
              BillableYN,
              BillableFirm,
              Issue,
              Notes,
              UniqueAttchID
            )
    VALUES  ( @PMCo,
              @Project,
              @PunchList,
              @Item,
              @Description,
              @VendorGroup,
              @ResponsibleFirm,
              @Location,
              @DueDate,
              @FinDate,
              @BillableYN,
              @BillableFirm,
              @Issue,
              @Notes,
              @UniqueAttchID 
            ) ;


    DECLARE @KeyID INT
    SET @KeyID = SCOPE_IDENTITY()
    EXECUTE vpspPMPunchListItemGet @PMCo, @Project, @PunchList, @KeyID

    bspexit:
    RETURN @rcode

    bspmessage:
    RAISERROR(@message, 11, -1);
    RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vpspPMPunchListItemInsert] TO [VCSPortal]
GO
