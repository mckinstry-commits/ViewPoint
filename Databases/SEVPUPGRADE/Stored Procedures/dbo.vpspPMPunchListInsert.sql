SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMPunchListInsert]
/************************************************************
* CREATED:		2/22/06		CHS
* Modified:		6/05/07		chs
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				GF 12/06/2011 TK-10599
*
* USAGE:
*   Inserts PM Punch List
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @PunchList bDocument,
      @Description VARCHAR(255),
      @PunchListDate bDate,
      @PrintOption CHAR(1),
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    SET NOCOUNT ON ;
	
    DECLARE @rcode INT,
        @nextPunchList INT,
        @msg VARCHAR(255)
    SET @rcode = 0

--if @PunchList is null
    IF ( ISNULL(@PunchList, '') = '' )
        OR @PunchList = '+'
        OR @PunchList = 'n'
        OR @PunchList = 'N' 
        BEGIN
            SET @nextPunchList = ( SELECT   ISNULL(( MAX(PunchList) + 1 ), 1)
                                   FROM     dbo.PMPU WITH ( NOLOCK )
                                   WHERE    PMCo = @PMCo
                                            AND Project = @Project
                                            AND ISNUMERIC(PunchList) = 1
                                            AND PunchList NOT LIKE '%.%'
                                            AND SUBSTRING(LTRIM(PunchList), 1,
                                                          1) <> '0'
                                 )
            SET @msg = NULL
            EXEC @rcode = dbo.vpspFormatDatatypeField 'bDocument',
                @nextPunchList, @msg OUTPUT
            SET @PunchList = @msg
        END
	
    ELSE 
        BEGIN
            SET @msg = NULL
            EXEC @rcode = dbo.vpspFormatDatatypeField 'bDocument', @PunchList,
                @msg OUTPUT
            SET @PunchList = @msg
        END
	
    INSERT  INTO dbo.PMPU
            ( PMCo,
              Project,
              PunchList,
              Description,
              PunchListDate,
              PrintOption,
              Notes,
              UniqueAttchID
            )
    VALUES  ( @PMCo,
              @Project,
              @PunchList,
              @Description,
              @PunchListDate,
              @PrintOption,
              @Notes,
              @UniqueAttchID
            ) ;


    DECLARE @KeyID INT
    SET @KeyID = SCOPE_IDENTITY()
    EXECUTE vpspPMPunchListGet @PMCo, @Project, @KeyID




GO
GRANT EXECUTE ON  [dbo].[vpspPMPunchListInsert] TO [VCSPortal]
GO
