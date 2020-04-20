SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.bspDDSLUserColumn    Script Date: 8/28/99 9:32:38 AM ******/
CREATE   PROC [dbo].[bspDDSLUserColumn]
/***********************************************************
* CREATED BY: DANF 03/05/2004
* MODIFIED By : JRK 11/07/2006 Updated to use vDDSLc for V6 
*				AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function.
*				GF 09/23/2011 - TK-08517 added bSMCo as securable data type.
*
* USAGE:
* Add or remove user memo columns from DDSL
*
* INPUT PARAMETERS
*   TableName, Datatype, InstanceColumn, QualifierColumn, Action(Addtion,Deletion)
*   The Form is needed for Additions only.
* INPUT PARAMETERS
*   @msg        error message if something went wrong
* RETURN VALUE
*   0 Success
*   1 fail
************************************************************************/
    (
      @TableName VARCHAR(30) = NULL,
      @Datatype VARCHAR(30) = NULL,
      @InstanceColumn VARCHAR(30) = NULL,
      @Form VARCHAR(30) = NULL,
      @Action VARCHAR(10) = NULL,
      @msg VARCHAR(60) OUTPUT
    )
AS 
    SET nocount ON
    DECLARE @rcode INT,
        @RecordCount INT,
        @QualifierColumn VARCHAR(30)
    SELECT  @rcode = 0
   
    IF @TableName IS NULL 
        BEGIN
            SELECT  @msg = 'Missing Table!',
                    @rcode = 1
            RETURN @rcode
        END
   
    IF @InstanceColumn IS NULL 
        BEGIN
            SELECT  @msg = 'Missing Instance Column!',
                    @rcode = 1
            RETURN @rcode
        END
   
   ----TK-08517
    IF @Datatype NOT IN ( 'bAPCo', 'bARCo', 'bCMCo', 'bEMCo', 'bGLCo', 'bHQCo',
                          'bINCo', 'bJCCo', 'bMSCo', 'bPOCo', 'bPRCo', 'bSLCo',
                          'bJBCo', 'bHRCo', 'bPMCo', 'bCMAcct', 'bEmployee',
                          'bContract', 'bJob', 'bLoc', 'bHRRef', 'bSMCo' ) 
        BEGIN
            SELECT  @msg = 'Invalid Security Data Type'
            RETURN @rcode
        END
   
    IF NOT EXISTS ( SELECT TOP 1
                            1
                    FROM    sysobjects o
                            JOIN syscolumns c ON o.id = c.id
                    WHERE   o.name = @TableName
                            AND c.name = @InstanceColumn )
        AND @Action = 'Deletion' 
        BEGIN
            SELECT  @msg = 'Instance not on file!' --, @rcode = 1
            RETURN @rcode
        END
   
    IF @Action = 'Addition' 
        BEGIN
   
   		-- Set @QualifierColumn by finding company value in form
   		-- Find Qualifer by Data Type For Employees look for bPRCo
   		-- for Job and Contract look for bJCCo, For bLoc look
   		-- for bINCo
			-- use inline table function for perf
            IF @Datatype = 'bEmployee' 
                SELECT TOP 1
                        @QualifierColumn = ColumnName
                FROM    dbo.vfDDFIShared(@Form)
                WHERE   Datatype = 'bPRCo'
                        AND ColumnName IS NOT NULL
            IF @Datatype = 'bJob'
                OR @Datatype = 'bContract' 
                SELECT TOP 1
                        @QualifierColumn = ColumnName
                FROM    dbo.vfDDFIShared(@Form)
                WHERE   Datatype = 'bJCCo'
                        AND ColumnName IS NOT NULL
            IF @Datatype = 'bLoc' 
                SELECT TOP 1
                        @QualifierColumn = ColumnName
                FROM    dbo.vfDDFIShared(@Form)
                WHERE   Datatype = 'bINCo'
                        AND ColumnName IS NOT NULL
            IF @Datatype = 'bHRRef' 
                SELECT TOP 1
                        @QualifierColumn = ColumnName
                FROM    dbo.vfDDFIShared(@Form)
                WHERE	Datatype = 'bHRCo'
                        AND ColumnName IS NOT NULL
            IF @Datatype = 'bCMAcct' 
                SELECT TOP 1
                        @QualifierColumn = ColumnName
                FROM    dbo.vfDDFIShared(@Form)
                WHERE   Datatype = 'bCMCo'
                        AND ColumnName IS NOT NULL
                        
            ----TK-08517         
            IF @Datatype IN ( 'bAPCo', 'bARCo', 'bCMCo', 'bEMCo', 'bGLCo',
                              'bHQCo', 'bINCo', 'bJCCo', 'bMSCo', 'bPOCo',
                              'bPRCo', 'bSLCo', 'bJBCo', 'bHRCo', 'bPMCo',
                              'bSMCo' ) 
                SELECT  @QualifierColumn = @InstanceColumn
   
            IF ISNULL(@QualifierColumn, '') = '' 
                BEGIN
                    IF SUBSTRING(@TableName, 1, 3) = 'bud'
                        AND EXISTS ( SELECT 1
                                     FROM   dbo.bUDTH WITH ( NOLOCK )
                                     WHERE  CompanyBasedYN = 'Y'
                                            AND FormName = @Form ) 
                        SELECT  @QualifierColumn = 'Co'
                    IF ISNULL(@QualifierColumn, '') = '' 
                        BEGIN
                            SELECT  @msg = 'Missing Company Qualifier Column for adding Security Entry into DDSL.'
                            RETURN @rcode
                        END
                END
   
            IF NOT EXISTS ( SELECT TOP 1
                                    1
                            FROM    dbo.DDSLShared WITH ( NOLOCK )
                            WHERE   TableName = @TableName
                                    AND Datatype = @Datatype
                                    AND InstanceColumn = @InstanceColumn ) 
                BEGIN
                    INSERT  dbo.vDDSLc
                            ( TableName,
                              Datatype,
                              InstanceColumn,
                              InUse,
                              QualifierColumn
                            ) --, Custom, WhereClause) --(JRK)Custom and WhereClause were droppedin "v" tables.
                            SELECT  @TableName,
                                    @Datatype,
                                    @InstanceColumn,
                                    'N',
                                    @QualifierColumn --, 1, null
   	
                    SELECT  @RecordCount = @@rowcount
                END
        END
   
    IF @Action = 'Deletion' 
        BEGIN
            IF EXISTS ( SELECT TOP 1
                                1
                        FROM    dbo.DDSLShared WITH ( NOLOCK )
                        WHERE   TableName = @TableName
                                AND Datatype = @Datatype
                                AND InstanceColumn = @InstanceColumn ) 
                BEGIN
                    DELETE  dbo.vDDSLc
                    WHERE   TableName = @TableName
                            AND Datatype = @Datatype
                            AND InstanceColumn = @InstanceColumn
   	
                    SELECT  @RecordCount = @@rowcount
                END
        END
   
    RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[bspDDSLUserColumn] TO [public]
GO
