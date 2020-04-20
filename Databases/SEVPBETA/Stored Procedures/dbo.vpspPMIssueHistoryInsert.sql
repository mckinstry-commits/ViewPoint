SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMIssueHistoryInsert]
/************************************************************
* CREATED:		3/15/06	CHS
* MODIFIED:		6/12/07	CHS
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   Inserts PM Issue History
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo and Job 
*
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @Issue bIssue,
	--@Seq smallint,
      @Seq VARCHAR(5),
      @DocType bDocType,
      @Document bDocument,
      @Rev TINYINT,
      @PCOType bDocType,
      @PCO bPCO,
      @PCOItem bPCOItem,
      @ACO bACO,
      @ACOItem bACOItem,
      @IssueDateTime DATETIME,
      @Action VARCHAR(MAX),
      @Login bVPUserName,
      @ActionDate bDate,
      @UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    SET NOCOUNT ON ;
	
    SET @Seq = ( SELECT ISNULL(( MAX(Seq) + 1 ), 1)
                 FROM   PMIH
                 WHERE  PMCo = @PMCo
                        AND Project = @Project
                        AND Issue = @Issue
               )

    INSERT  INTO PMIH
            ( PMCo,
              Project,
              Issue,
              Seq,
              DocType,
              Document,
              Rev,
              PCOType,
              PCO,
              PCOItem,
              ACO,
              ACOItem,
              IssueDateTime,
              Action,
              Login,
              ActionDate,
              UniqueAttchID
            )
    VALUES  ( @PMCo,
              @Project,
              @Issue,
              @Seq,
              @DocType,
              @Document,
              @Rev,
              @PCOType,
              @PCO,
              @PCOItem,
              @ACO,
              @ACOItem,
              @IssueDateTime,
              @Action,
              @Login,
              @ActionDate,
              @UniqueAttchID
            ) ;


    DECLARE @KeyID INT
    SET @KeyID = SCOPE_IDENTITY()
    EXECUTE vpspPMIssueHistoryGet @PMCo, @Project, @Issue, @KeyID



GO
GRANT EXECUTE ON  [dbo].[vpspPMIssueHistoryInsert] TO [VCSPortal]
GO
