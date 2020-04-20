SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[bspIMUploadHeaderDetail]

/**************************************************
*
*  Created By:   MH 03/28/02
*  Modified By:  danf 11/07/02 - 19123 Added error message for columns that do not allow nulls.
*		danf 01/30/02 - Removed quotes.
*		rbt 05/13/03 - #21242 SET ANSI_WARNINGS OFF to avoid insert failure when text field is truncated.								
*		rbt	05/13/03 - #20726 Allow description for RecKey column to be "RecKey" or "Record Key".
*		rbt 05/16/03 - #17507 Change exec bspIMBatchAssign to use 'OUTPUT' keyword
*					for return error messages to be passed back.
*		RBT 05/20/03 - #19675 Catch non-numeric data being passed for numeric fields,
*					and change call to bspIMGetLastBatchSeq to return value into @rc instead
*					of @rcode so VB knows about errors.  Changed err msgs to be more descriptive.
*		RBT 05/28/03 - #19532 Change upload procedure to use transactions to keep header and detail
*					lines together, so that if any details fail, we roll back the header and its other details too.
*		RBT 06/05/03 - #20071 Replaced pseudo-cursors with cursors.  Added "with (nolock)" to select queries.
*					Also group details with their header with one transaction per header, so if any detail fails,
*					its header and all other details will be rolled back and remain in IMWE.  Messages are put into IMWM
*					via dynamic sql after transaction end, otherwise could be rolled back.  Turned off auto statistics for IMWE.
*		RBT 06/05/03 - #20197 Replace single quotes with single backquotes.
*		RBT 06/30/03 - #21679 Comment out sp_autostats line that turned off statistics. 
*		RBT 08/12/03 - #22140 Use variable to indicate HeaderCursor open.
*		RBT 09/05/03 - #20131 Allow record types <> table names.  Correct rectypes if first table <> header.
*		RBT 10/27/03 - #22777 Save SQL exec strings in IMWM as error 9999 in case of fatal error.
*		RBT 01/12/04 - #23432 Import to Notes field.
*		RBT 07/06/04 - #25022 Get RecKey identifier from DDUD, not IMTD.
*		RBT 08/25/04 - #25350 Insert Identifier into IMWM where applicable.
*		DANF 12/21/04 - Issue #26577: Changed reference from DDFH to vDDFH
*		DANF 12/19/06 - 6.X Added Try Catch around insert statement
*		CC 02/26/08 - #127127 Remove comma from numeric values
*		CC 03/20/08 - #127467 add check for null batch company add error, and skip record
*		CC 03/21/08 - #127572 Add transaction rollback code in the catch blocks if the transaction is in an uncommitable state (-1)
*		CC 03/25/08 - #122980 Add support for large fields/notes
*		TJL 08/27/09 - Issue #135341, Special AP Invoice w/Release Retg for Textura
*		GF 09/14/2010 - issue #141031 changed to use vfDateOnly
*		AR 6/22/11	- TK-07089 - Fixing performance issues with INFO columns
*		GF 01/30/2012 TK-12057 #145652 change to sys.views from sys.tables
*		AR 02/08/2012 TK-12057 #145652 change to sys.views from sys.tables
*	
*
*USAGE:
*
*Upload data from IMWE to appropriate tables.  Designed 
*for Header/Detail batch tables.  
*
*INPUT PARAMETERS
*    Company, ImportId, Template, Errmsg
*
*RETURN PARAMETERS
*    Error Message
*
*None
*
*************************************************/
    (
      @importid VARCHAR(20) = NULL ,
      @template VARCHAR(30) = NULL ,
      @errmsg VARCHAR(500) = NULL OUTPUT
    )
AS 
    SET nocount ON

/* Store current state for ANSI_WARNINGS to restore at end. */
    DECLARE @ANSIWARN INT
    SELECT  @ANSIWARN = 0
    IF @@OPTIONS & 8 > 0 
        SELECT  @ANSIWARN = 1
    SET ANSI_WARNINGS OFF
     
     
     --Locals
    DECLARE @ident INT ,
        @detailident INT ,
        @headrecseq INT ,
        @detailrecseq INT ,
        @columnlist VARCHAR(MAX) ,
        @valuelist VARCHAR(MAX) ,
        @rcode INT ,
        @detailcollist VARCHAR(MAX) ,
        @detailvallist VARCHAR(MAX) ,
        @detailinsert VARCHAR(MAX) ,
        @headerinsert VARCHAR(MAX) ,
        @headerkeyident INT ,
        @detailkeyident INT ,
        @headerkeycol INT ,
        @detailkeycol INT ,
        @quote INT ,
        @importcolumn VARCHAR(30) ,
        @importvalue VARCHAR(MAX) ,
        @coltype VARCHAR(20) ,
        @headform VARCHAR(30) ,
        @detailform VARCHAR(30) ,
        @headerr INT ,
        @detailerr INT ,
        @deletestmt VARCHAR(8000) ,
        @errcode INT ,
        @errdesc VARCHAR(255) ,
        @ErrorMessage VARCHAR(2048) ,
        @firstform VARCHAR(30) ,
        @secondform VARCHAR(30) ,
        @rectypecount INT ,
        @batchyn CHAR(1) ,
        @headtable VARCHAR(10) ,
        @detailtable VARCHAR(10) ,
        @headrectype VARCHAR(10) ,
        @detailrectype VARCHAR(10) ,
        @batchid bBatchID ,
        @batchmth VARCHAR(25) ,
        @batchseq INT ,
        @batchlock VARCHAR(MAX) ,
        @batchunlock VARCHAR(MAX) ,
        @maxbatchid INT ,
        @sql VARCHAR(MAX) ,
        @updateIMBC VARCHAR(MAX) ,
        @imbccount INT ,
        @rc INT ,
        @retainageident INT ,
        @retainageYN bYN ,
        @IMWMinsert VARCHAR(MAX) ,
        @intrans INT ,
        @quoteloc INT ,
        @hcstatus INT ,
        @dcstatus INT ,
        @DetailCursorOpen INT ,
        @HeaderCursorOpen INT , 
	
	-- Auto Validation & Posting, AP Release Retainge (Textura)
        @releaseretgflagID INT ,
        @disttaxflagID INT ,
        @detailkeyID INT ,
        @linetypeID INT ,
        @slID INT ,
        @slitemID INT ,
        @jccoID INT ,
        @jobID INT ,
        @phasegroupID INT ,
        @phaseID INT ,
        @grossamtID INT ,
        @vendorgroupID INT ,
        @vendorID INT ,
        @relretgflag CHAR(1) ,
        @disttaxflag bYN ,
        @relexists bYN ,
        @headerreckey VARCHAR(60) ,
        @detailreckey VARCHAR(60) ,
        @aplinetype VARCHAR(60) ,
        @sl VARCHAR(60) ,
        @slitem VARCHAR(60) ,
        @jcco VARCHAR(60) ,
        @job VARCHAR(60) ,		--varchar(60) is correct here
        @phasegroup VARCHAR(60) ,
        @phase VARCHAR(60) ,
        @detailrelamount VARCHAR(60) ,								--varchar(60) is correct here
        @vendorgroup VARCHAR(60) ,
        @vendor VARCHAR(60) ,															--varchar(60) is correct here
        @valproc VARCHAR(MAX) ,
        @postproc VARCHAR(MAX) ,
        @valerrmsg VARCHAR(500) ,
        @posterrmsg VARCHAR(500) ,
        @autopostdate bDate ,
        @openHeaderRelcursor TINYINT ,
        @openAPLBRelcursor TINYINT ,
        @errorid TINYINT ,
        @headererrorid TINYINT ,
        @relrcode TINYINT ,
        @relerrmsg VARCHAR(500)

    DECLARE @coident INT ,
        @co bCompany ,
        @form VARCHAR(30) ,
        @batchassign_errmsg VARCHAR(8000)
     
--the ascii code for a single quote
    SELECT  @quote = 39
     
--initialize the error code
    SELECT  @rcode = 0 ,
            @ident = -1 ,
            @headrecseq = -1 ,
            @headerr = 0 ,
            @DetailCursorOpen = 0 ,
            @HeaderCursorOpen = 0 ,
            @relexists = 'N' ,
            @openHeaderRelcursor = 0 ,
            @openAPLBRelcursor = 0 ,
            @relrcode = 0
	
----#141031
    SET @autopostdate = dbo.vfDateOnly()

    SELECT  @rectypecount = COUNT(ImportTemplate)
    FROM    IMTR WITH ( NOLOCK )
    WHERE   ImportTemplate = @template

--we should only have 2 record types but we don't know which one is header or which one is detail
    IF @rectypecount = 2 
        BEGIN
            SELECT  @headrectype = MIN(RecordType)
            FROM    IMTR WITH ( NOLOCK )
            WHERE   ImportTemplate = @template
            SELECT  @firstform = Form
            FROM    IMTR WITH ( NOLOCK )
            WHERE   ImportTemplate = @template
                    AND RecordType = @headrectype 
            SELECT  @detailrectype = RecordType
            FROM    IMTR WITH ( NOLOCK )
            WHERE   ImportTemplate = @template
                    AND RecordType > @headrectype
            SELECT  @secondform = Form
            FROM    IMTR WITH ( NOLOCK )
            WHERE   ImportTemplate = @template
                    AND RecordType = @detailrectype
        END

    SELECT  @headform = Form ,
            @batchyn = BatchYN
    FROM    DDUF WITH ( NOLOCK )
    WHERE   Form = @firstform 
    IF @batchyn = 'N' 
        BEGIN
            SELECT  @headform = Form ,
                    @batchyn = BatchYN
            FROM    DDUF WITH ( NOLOCK )
            WHERE   Form = @secondform 
            SELECT  @headrectype = RecordType
            FROM    IMTR WITH ( NOLOCK )
            WHERE   ImportTemplate = @template
                    AND Form = @headform

            IF @batchyn = 'N'
	--we got an error here.  Bump out of procedure.
                BEGIN
                    SELECT  @errmsg = 'Unable to get upload form information' ,
                            @rcode = 1
                    INSERT  IMWM
                            ( ImportId ,
                              ImportTemplate ,
                              Form ,
                              RecordSeq ,
                              Message
                            )
                    VALUES  ( @importid ,
                              @template ,
                              @firstform ,
                              @headrecseq ,
                              @errmsg
                            )
                    GOTO bspexit
                END
            ELSE 
                BEGIN
                    SELECT  @detailform = Form
                    FROM    DDUF
                    WHERE   Form = @firstform 
		-- correct the record types.
                    SELECT  @detailrectype = RecordType
                    FROM    IMTR WITH ( NOLOCK )
                    WHERE   ImportTemplate = @template
                            AND Form = @detailform
                END
        END
    ELSE 
        SELECT  @detailform = Form
        FROM    DDUF WITH ( NOLOCK )
        WHERE   Form = @secondform
	
	/* Special Release Retainage import.  Currently only affects AP Transaction Entry but could be expanded. 
	   Retrieve import specific ID's for later retrieval of import specific values. */
    IF @headform = 'APEntry' 
        BEGIN 
            SELECT  @releaseretgflagID = MAX(CASE WHEN b.ColumnName = 'ReleaseRetgFlag'
                                                  THEN a.Identifier
                                             END) ,
                    @disttaxflagID = MAX(CASE WHEN b.ColumnName = 'DistributeTaxFlag'
                                              THEN a.Identifier
                                         END) ,
                    @vendorgroupID = MAX(CASE WHEN b.ColumnName = 'VendorGroup'
                                              THEN a.Identifier
                                         END) ,
                    @vendorID = MAX(CASE WHEN b.ColumnName = 'Vendor'
                                         THEN a.Identifier
                                    END)
            FROM    IMTD a WITH ( NOLOCK )
                    JOIN DDUD b WITH ( NOLOCK ) ON a.Identifier = b.Identifier
            WHERE   a.ImportTemplate = @template
                    AND a.RecordType = @headrectype
                    AND b.Form = @headform
		
            SELECT  @detailkeyID = MAX(CASE WHEN b.ColumnName = 'RecKey'
                                            THEN a.Identifier
                                       END) ,
                    @linetypeID = MAX(CASE WHEN b.ColumnName = 'LineType'
                                           THEN a.Identifier
                                      END) ,
                    @slID = MAX(CASE WHEN b.ColumnName = 'SL'
                                     THEN a.Identifier
                                END) ,
                    @slitemID = MAX(CASE WHEN b.ColumnName = 'SLItem'
                                         THEN a.Identifier
                                    END) ,
                    @jccoID = MAX(CASE WHEN b.ColumnName = 'JCCo'
                                       THEN a.Identifier
                                  END) ,
                    @jobID = MAX(CASE WHEN b.ColumnName = 'Job'
                                      THEN a.Identifier
                                 END) ,
                    @phasegroupID = MAX(CASE WHEN b.ColumnName = 'PhaseGroup'
                                             THEN a.Identifier
                                        END) ,
                    @phaseID = MAX(CASE WHEN b.ColumnName = 'Phase'
                                        THEN a.Identifier
                                   END) ,
                    @grossamtID = MAX(CASE WHEN b.ColumnName = 'GrossAmt'
                                           THEN a.Identifier
                                      END)
            FROM    IMTD a WITH ( NOLOCK )
                    JOIN DDUD b WITH ( NOLOCK ) ON a.Identifier = b.Identifier
            WHERE   a.ImportTemplate = @template
                    AND a.RecordType = @detailrectype
                    AND b.Form = @detailform
        END
		
    SELECT  @headtable = ViewName
    FROM    dbo.vDDFH WITH ( NOLOCK )
    WHERE   Form = @headform
     
    IF @headtable = '' 
        BEGIN
            SELECT  @errmsg = 'Unable to get Header table information' ,
                    @rcode = 1
            INSERT  IMWM
                    ( ImportId ,
                      ImportTemplate ,
                      Form ,
                      RecordSeq ,
                      Message
                    )
            VALUES  ( @importid ,
                      @template ,
                      @firstform ,
                      @headrecseq ,
                      @errmsg
                    )
            GOTO bspexit
        END
     
    SELECT  @detailtable = ViewName
    FROM    dbo.vDDFH
    WHERE   Form = @detailform
     
    IF @detailtable = '' 
        BEGIN
            SELECT  @errmsg = 'Unable to get Detail table information' ,
                    @rcode = 1
            INSERT  IMWM
                    ( ImportId ,
                      ImportTemplate ,
                      Form ,
                      RecordSeq ,
                      Message
                    )
            VALUES  ( @importid ,
                      @template ,
                      @firstform ,
                      @headrecseq ,
                      @errmsg
                    )
            GOTO bspexit
        END
     
	--new company stuff
	--Get the identifier for the company.  This should be the first identifier.
    SELECT  @coident = MIN(Identifier)
    FROM    IMWE WITH ( NOLOCK )
    WHERE   ImportTemplate = @template
            AND RecordType = @headrectype
            AND ImportId = @importid	
	--new company stuff
    
    IF @releaseretgflagID IS NULL
        OR ( @releaseretgflagID IS NOT NULL
             AND EXISTS ( SELECT TOP 1
                                    1
                          FROM      IMWE
                          WHERE     ImportId = @importid
                                    AND ImportTemplate = @template
                                    AND Identifier = @releaseretgflagID
                                    AND Form = @headform
                                    AND ISNULL(UploadVal, '') <> 'R' )
           ) 
        BEGIN		
		/* call bspIMBatchAssign to spin through IMWE and assign the batches. 
		   This process will get skipped when ONLY Release Retg import records exists and no others. */
            EXEC @rc = bspIMBatchAssign @importid, @template, @headrectype,
                @headform, @coident, @batchassign_errmsg OUTPUT
            IF @rc <> 0 
                BEGIN
                    SELECT  @errmsg = 'Unable to assign batch.  '
                            + @batchassign_errmsg
                    SELECT  @rcode = 1
                    GOTO bspexit
                END
        END
		
	 --Get the key column identifier
    SELECT  @headerkeyident = a.Identifier
    FROM    IMTD a WITH ( NOLOCK )
            JOIN DDUD b WITH ( NOLOCK ) ON a.Identifier = b.Identifier
    WHERE   a.ImportTemplate = @template
            AND b.ColumnName = 'RecKey'
            AND a.RecordType = @headrectype
            AND b.Form = @headform
   
    DECLARE HeaderCursor CURSOR
    FOR
        SELECT DISTINCT
                IMWE.RecordSeq
        FROM    IMWE WITH ( NOLOCK )
                LEFT OUTER JOIN DDUD WITH ( NOLOCK ) ON IMWE.Form = DDUD.Form
                                                        AND DDUD.TableName = @headtable
                                                        AND DDUD.Identifier = IMWE.Identifier
                INNER JOIN IMTD WITH ( NOLOCK ) ON IMWE.ImportTemplate = IMTD.ImportTemplate
                                                   AND IMWE.Identifier = IMTD.Identifier
                                                   AND IMWE.RecordType = IMTD.RecordType
        WHERE   IMWE.ImportId = @importid
                AND IMWE.ImportTemplate = @template
                AND IMWE.RecordType = @headrectype
        ORDER BY IMWE.RecordSeq
     
    OPEN HeaderCursor
    SELECT  @HeaderCursorOpen = 1

    FETCH NEXT FROM HeaderCursor INTO @headrecseq
    SELECT  @hcstatus = @@FETCH_STATUS
     
    WHILE @hcstatus = 0 
        BEGIN  --outer while
     	/* Check import record Header.  If it is a Release Retg record, skip it.  It will be dealt with later. 
     	   Currently only affects AP Transaction Entry but could be expanded. */
            SELECT  @relretgflag = NULL
            IF @headform = 'APEntry' 
                BEGIN
			-- Get Header release retainage flag
                    SELECT  @relretgflag = UploadVal
                    FROM    IMWE
                    WHERE   ImportId = @importid
                            AND ImportTemplate = @template
                            AND Identifier = @releaseretgflagID
                            AND Form = @headform
                            AND RecordSeq = @headrecseq

                    IF ISNULL(@relretgflag, '') = 'R' 
                        BEGIN
                            SELECT  @relexists = 'Y'
                            GOTO SkipDeleteHeaderGetNext
                        END
                END
					    	
            SELECT  @headerr = 0 ,
                    @detailerr = 0
            SELECT  @IMWMinsert = NULL
 		--Develop header record
 		--Get the key value
            SELECT  @headerkeycol = UploadVal
            FROM    IMWE WITH ( NOLOCK )
            WHERE   ImportTemplate = @template
                    AND RecordType = @headrectype
                    AND Identifier = @headerkeyident
                    AND RecordSeq = @headrecseq
                    AND ImportId = @importid

 		--Get the first identifier for this RecordSequence
            SELECT  @ident = MIN(Identifier)
            FROM    IMWE WITH ( NOLOCK )
            WHERE   IMWE.ImportId = @importid
                    AND IMWE.ImportTemplate = @template
                    AND IMWE.RecordType = @headrectype
                    AND IMWE.RecordSeq = @headrecseq
 
            WHILE @ident IS NOT NULL 
                BEGIN  --inner header req while
                    SELECT  @importcolumn = NULL ,
                            @importvalue = NULL
                    IF EXISTS ( SELECT  1
                                FROM    --using sys tables for performance booster
										sys.columns c
										----TK-12057
										JOIN sys.views v ON v.[object_id] = c.[object_id]
										--INFORMATION_SCHEMA.COLUMNS c
										JOIN DDUD d ON v.[name] = d.TableName
                                                       AND c.[name] = d.ColumnName
                                WHERE   ( c.max_length > 60
                                          OR c.max_length = -1
                                        )
                                        AND d.Form = @headform
                                        AND d.Identifier = @ident
                                        AND d.TableName = @headtable ) 
                        BEGIN
                            SELECT  @importvalue = ( SELECT UploadVal
                                                     FROM   IMWENotes WITH ( NOLOCK )
                                                     WHERE  IMWENotes.ImportId = @importid
                                                            AND IMWENotes.ImportTemplate = @template
                                                            AND IMWENotes.RecordType = @headrectype
                                                            AND IMWENotes.Identifier = @ident
                                                            AND IMWENotes.RecordSeq = @headrecseq
                                                   )
 
                            SELECT  @importcolumn = ( SELECT  DDUD.ColumnName
                                                      FROM    IMWENotes WITH ( NOLOCK )
                                                              LEFT OUTER JOIN DDUD
                                                              WITH ( NOLOCK ) ON IMWENotes.Form = DDUD.Form
                                                              AND DDUD.TableName = @headtable
                                                              AND DDUD.Identifier = IMWENotes.Identifier
                                                      WHERE   IMWENotes.ImportId = @importid
                                                              AND IMWENotes.ImportTemplate = @template
                                                              AND IMWENotes.RecordType = @headrectype
                                                              AND IMWENotes.Identifier = @ident
                                                              AND IMWENotes.RecordSeq = @headrecseq
                                                    )
                        END
                    ELSE 
                        BEGIN
                            SELECT  @importvalue = ( SELECT IMWE.UploadVal
                                                     FROM   IMWE WITH ( NOLOCK )
                                                     WHERE  IMWE.ImportId = @importid
                                                            AND IMWE.ImportTemplate = @template
                                                            AND IMWE.RecordType = @headrectype
                                                            AND IMWE.Identifier = @ident
                                                            AND IMWE.RecordSeq = @headrecseq
                                                   )
 
                            SELECT  @importcolumn = ( SELECT  DDUD.ColumnName
                                                      FROM    IMWE WITH ( NOLOCK )
                                                              LEFT OUTER JOIN DDUD
                                                              WITH ( NOLOCK ) ON IMWE.Form = DDUD.Form
                                                              AND DDUD.TableName = @headtable
                                                              AND DDUD.Identifier = IMWE.Identifier
                                                      WHERE   IMWE.ImportId = @importid
                                                              AND IMWE.ImportTemplate = @template
                                                              AND IMWE.RecordType = @headrectype
                                                              AND IMWE.Identifier = @ident
                                                              AND IMWE.RecordSeq = @headrecseq
                                                    )
                        END
			--Get the destination Company
                    IF @ident = @coident 
                        SELECT  @co = @importvalue
     
                    IF ISNULL(@co, '') = '' 
                        BEGIN
				--Write back to IMWE
                            UPDATE  IMWE
                            SET     UploadVal = '*MISSING REQUIRED VALUE*'
                            WHERE   ImportId = @importid
                                    AND ImportTemplate = @template
                                    AND Identifier = @coident
                                    AND RecordSeq = @headrecseq

                            SELECT  @errmsg = 'Batch Company is null'

                            INSERT  IMWM
                                    ( ImportId ,
                                      ImportTemplate ,
                                      Form ,
                                      RecordSeq ,
                                      Identifier ,
                                      Error ,
                                      Message
                                    )
                            VALUES  ( @importid ,
                                      @template ,
                                      @firstform ,
                                      @headrecseq ,
                                      @ident ,
                                      @errcode ,
                                      @errmsg
                                    )
		
				--dump this record seq.  go onto next one	
                            SELECT  @rcode = 1 ,
                                    @headerr = 1
                            GOTO GetNextHeaderReqSeq
                        END
				
 			--get the batch info stuff
                    IF @importcolumn = 'Mth' 
                        SELECT  @batchmth = @importvalue
                    IF @importcolumn = 'BatchId' 
                        SELECT  @batchid = @importvalue
			--new batch seq code
                    IF UPPER(@importcolumn) = 'BATCHSEQ' 
                        BEGIN
                            EXEC @rc = bspIMGetLastBatchSeq @co, @batchmth,
                                @batchid, @headtable, @maxbatchid OUTPUT,
                                @errmsg OUTPUT
                            IF @rc = 0 
                                BEGIN
                                    SELECT  @importvalue = CONVERT(VARCHAR(100), @maxbatchid
                                            + 1)
                                    SELECT  @batchseq = @importvalue
                                END
                            ELSE 
                                BEGIN
                                    SELECT  @rcode = 1 ,
                                            @headerr = 1
                                    SELECT  @errmsg = 'Unable get last Batch Seq.  '
                                            + @errmsg
                                    INSERT  IMWM
                                            ( ImportId ,
                                              ImportTemplate ,
                                              Form ,
                                              RecordSeq ,
                                              Message ,
                                              Identifier
                                            )
                                    VALUES  ( @importid ,
                                              @template ,
                                              @firstform ,
                                              @headrecseq ,
                                              @errmsg ,
                                              @ident
                                            )
                                    GOTO bspexit
                                END
                        END
     
 			--determine if column is required....
                    IF @importvalue = ''
                        OR @importvalue IS NULL 
                        BEGIN	
                            IF ( SELECT COLUMNPROPERTY(OBJECT_ID(@headrectype),
                                                       @importcolumn,
                                                       'AllowsNull')
                               ) = 0 
 				--update upload value...message that Table.Column cannot be null
 				--stop developing this record, go to next record sequence
 				--write message to IMWM
                                BEGIN 
                                    SELECT  @rcode = 1 ,
                                            @headerr = 1
                                    SELECT  @errmsg = 'Identifier '
                                            + CONVERT(VARCHAR(10), @ident)
                                            + '.  Column : ' + @importcolumn
                                            + ' does not allow null values!' 
                                    INSERT  IMWM
                                            ( ImportId ,
                                              ImportTemplate ,
                                              Form ,
                                              RecordSeq ,
                                              Message ,
                                              Identifier
                                            )
                                    VALUES  ( @importid ,
                                              @template ,
                                              @firstform ,
                                              @headrecseq ,
                                              @errmsg ,
                                              @ident
                                            )
 
                                    GOTO GetNextHeaderReqSeq
                                END
                            ELSE
     				--set and emtry string to null
                                SELECT  @importvalue = NULL
                        END
     
     
                    IF @importcolumn IS NOT NULL 
                        BEGIN
                            SELECT  @coltype = ColType
                            FROM    DDUD WITH ( NOLOCK )
                            WHERE   Form = @headform
                                    AND Identifier = @ident
     
                            IF @importvalue IS NOT NULL 
                                BEGIN
 					--Catch fields with embedded single quotes...
                                    IF CHARINDEX(CHAR(@quote), @importvalue) > 0 
                                        BEGIN
     						--replace single quotes with single back-quotes
                                            SELECT  @importvalue = REPLACE(@importvalue,
                                                              CHAR(@quote),
                                                              '`')
                                        END
     					
                                    IF @coltype = 'varchar'
                                        OR @coltype = 'text' 
                                        IF ISNULL(@importvalue, '') <> '' 
                                            BEGIN
                                                SELECT  @importvalue = CHAR(@quote)
                                                        + @importvalue
                                                        + CHAR(@quote)
                                            END
                                        ELSE 
                                            BEGIN
                                                SELECT  @importvalue = 'char(null)'
                                            END
     
                                    IF @coltype = 'char' 
                                        IF ISNULL(@importvalue, '') <> '' 
                                            BEGIN
                                                SELECT  @importvalue = CHAR(@quote)
                                                        + @importvalue
                                                        + CHAR(@quote)
                                            END
                                        ELSE 
                                            BEGIN
                                                SELECT  @importvalue = 'char(null)'
                                            END
     
                                    IF @coltype = 'smalldatetime' 
                                        IF ISNULL(@importvalue, '') <> '' 
                                            BEGIN
                                                SELECT  @importvalue = CHAR(@quote)
                                                        + LTRIM(@importvalue)
                                                        + CHAR(@quote)
                                            END
                                        ELSE 
                                            BEGIN
                                                SELECT  @importvalue = 'char(null)'
                                            END
     
                                    IF @coltype = 'tinyint'
                                        OR @coltype = 'int'
                                        OR @coltype = 'numeric' 
                                        BEGIN
                                            IF ISNULL(@importvalue, '') = '' 
                                                SELECT  @importvalue = 'char(null)'
                                        END
     
                                    IF @coltype IN ( 'bigint', 'int',
                                                     'smallint', 'tinyint',
                                                     'decimal', 'numeric',
                                                     'money', 'smallmoney',
                                                     'float', 'real' ) 
                                        BEGIN
                                            SET @importvalue = REPLACE(@importvalue,
                                                              ',', '') 
                                            IF ISNUMERIC(@importvalue) <> 1
                                                AND @importvalue IS NOT NULL
                                                AND @importvalue <> 'char(null)' 
                                                BEGIN
                                                    SELECT  @rcode = 1 ,
                                                            @headerr = 1
                                                    SELECT  @errmsg = 'Identifier '
                                                            + CONVERT(VARCHAR(10), @ident)
                                                            + '.  Column : '
                                                            + @importcolumn
                                                            + ' does not allow non-numeric values!' 
     	
                                                    UPDATE  IMWE
                                                    SET     UploadVal = '*VALUE NOT NUMERIC*'
                                                    WHERE   ImportId = @importid
                                                            AND ImportTemplate = @template
                                                            AND Identifier = @ident
                                                            AND RecordSeq = @headrecseq
                                                            AND Form = @firstform
     	
                                                    INSERT  IMWM
                                                            ( ImportId ,
                                                              ImportTemplate ,
                                                              Form ,
                                                              RecordSeq ,
                                                              Message ,
                                                              Identifier
                                                            )
                                                    VALUES  ( @importid ,
                                                              @template ,
                                                              @firstform ,
                                                              @headrecseq ,
                                                              @errmsg ,
                                                              @ident
                                                            )
     				
                                                    GOTO GetNextHeaderReqSeq
                                                END
                                        END
     
                                    IF @valuelist IS NOT NULL 
                                        SELECT  @valuelist = @valuelist + ','
                                                + @importvalue
                                    ELSE 
                                        SELECT  @valuelist = 'values ('
                                                + @importvalue
     	
                                    IF @columnlist IS NULL 
                                        SELECT  @columnlist = 'Insert into '
                                                + @headtable + ' ('
                                                + @importcolumn
                                    ELSE 
                                        SELECT  @columnlist = @columnlist
                                                + ',' + @importcolumn
                                END
                        END	
     
		--get the next identifier
                    SELECT  @ident = MIN(Identifier)
                    FROM    ( SELECT    MIN(Identifier) AS Identifier
                              FROM      IMWE WITH ( NOLOCK )
                              WHERE     IMWE.ImportId = @importid
                                        AND IMWE.ImportTemplate = @template
                                        AND IMWE.RecordType = @headrectype
                                        AND IMWE.RecordSeq = @headrecseq
                                        AND IMWE.Identifier > @ident
                              UNION ALL
                              SELECT    MIN(Identifier) AS Identifier
                              FROM      IMWENotes WITH ( NOLOCK )
                              WHERE     IMWENotes.ImportId = @importid
                                        AND IMWENotes.ImportTemplate = @template
                                        AND IMWENotes.RecordType = @headrectype
                                        AND IMWENotes.RecordSeq = @headrecseq
                                        AND IMWENotes.Identifier > @ident
                            ) AS IMWEUnion 
                END

            SELECT  @headerinsert = @columnlist + ') ' + @valuelist + ')'
     
	--lock the batch
            SELECT  @batchlock = 'update HQBC set InUseBy = ' + CHAR(@quote)
                    + SUSER_SNAME() + CHAR(@quote) + ' where Co = '
                    + CONVERT(VARCHAR(3), @co) + ' and Mth = ' + CHAR(@quote)
                    + CONVERT(VARCHAR(30), @batchmth) + CHAR(@quote)
                    + ' and BatchId = ' + CONVERT(VARCHAR(6), @batchid) 
     
            BEGIN TRANSACTION 
            SELECT  @intrans = 1
     
            EXEC(@batchlock)
   
            DELETE  FROM IMWM
            WHERE   ImportId = @importid
                    AND Error = 9999
            INSERT  INTO IMWM
                    ( ImportId ,
                      ImportTemplate ,
                      Form ,
                      RecordSeq ,
                      Error ,
                      Message ,
                      SQLStatement
                    )
            VALUES  ( @importid ,
                      @template ,
                      @headform ,
                      @headrecseq ,
                      9999 ,
                      '' ,
                      @headerinsert
                    )
     
            SELECT  @errcode = 0
    
            BEGIN TRY
	--execute the insert APPB statement
                EXEC(@headerinsert)
            END TRY
	     
            BEGIN CATCH
                SELECT  @errcode = ERROR_NUMBER() ,
                        @ErrorMessage = ERROR_MESSAGE() ,
                        @rcode = 1

	-- Test whether the transaction is uncommittable.
                IF ( XACT_STATE() ) <> 0 
                    BEGIN
                        ROLLBACK TRANSACTION ;
                        SET @intrans = 0
                    END

                UPDATE  IMWM
                SET     Error = @errcode ,
                        Message = @ErrorMessage
                WHERE   ImportId = @importid
                        AND ImportTemplate = @template
                        AND Form = @headform
                        AND RecordSeq = @headrecseq
	    
                IF @@rowcount <> 1 
                    BEGIN
                        INSERT  IMWM
                                ( ImportId ,
                                  ImportTemplate ,
                                  Form ,
                                  RecordSeq ,
                                  Error ,
                                  Message
                                )
                        VALUES  ( @importid ,
                                  @template ,
                                  @headform ,
                                  @headrecseq ,
                                  @errcode ,
                                  @ErrorMessage
                                )
                    END
            END CATCH

            IF @errcode = 0 
                BEGIN
		--unlock the batch
                    SELECT  @batchunlock = 'update HQBC set InUseBy = null where Co = '
                            + CONVERT(VARCHAR(3), @co) + ' and Mth = '
                            + CHAR(@quote) + CONVERT(VARCHAR(30), @batchmth)
                            + CHAR(@quote) + ' and BatchId = '
                            + CONVERT(VARCHAR(6), @batchid) 

                    EXEC(@batchunlock)
     
                    IF @@error <> 0 
                        BEGIN
			--insert was sucessful but could not unlock the batch, 
			--abort the whole transaction. may want to consider bumping out
			--of the whole procedure.
                            SELECT  @headerr = 1
                            SELECT  @errcode = @@error
                            GOTO GetNextHeaderReqSeq
                        END
                END
            ELSE 
                BEGIN
		--insert failed, abort transaction
                    SELECT  @headerr = 1
                    GOTO GetNextHeaderReqSeq
                END
     
            SELECT  @headerinsert = NULL

	--Clear out the columnlist and valuelist
            SELECT  @columnlist = NULL ,
                    @valuelist = NULL ,
                    @coltype = NULL
     	
     
	--Now work on the line item detail records
	--Get the identifier for the key column
            DetailInsert:
            SELECT  @detailkeyident = a.Identifier
            FROM    IMTD a
                    JOIN DDUD b ON a.Identifier = b.Identifier
            WHERE   a.ImportTemplate = @template
                    AND b.ColumnName = 'RecKey'
                    AND a.RecordType = @detailrectype
                    AND b.Form = @detailform
   
	--Get Set of detail records associated with the header record's key value
     
            DECLARE DetailCursor CURSOR
            FOR
                SELECT DISTINCT
                        IMWE.RecordSeq
                FROM    IMWE WITH ( NOLOCK )
                        LEFT OUTER JOIN DDUD WITH ( NOLOCK ) ON IMWE.Form = DDUD.Form
                                                              AND DDUD.TableName = @detailtable
                                                              AND DDUD.Identifier = IMWE.Identifier
                        INNER JOIN IMTD WITH ( NOLOCK ) ON IMWE.ImportTemplate = IMTD.ImportTemplate
                                                           AND IMWE.Identifier = IMTD.Identifier
                                                           AND IMWE.RecordType = IMTD.RecordType
                WHERE   IMWE.ImportId = @importid
                        AND IMWE.ImportTemplate = @template
                        AND IMWE.RecordType = @detailrectype
                        AND IMWE.Identifier = @detailkeyident
                        AND IMWE.UploadVal = @headerkeycol
                ORDER BY IMWE.RecordSeq

            OPEN DetailCursor
            SELECT  @DetailCursorOpen = 1
            FETCH NEXT FROM DetailCursor INTO @detailrecseq
            SELECT  @dcstatus = @@FETCH_STATUS
     
            WHILE @dcstatus = 0 
                BEGIN
                    SELECT  @detailkeycol = UploadVal
                    FROM    IMWE WITH ( NOLOCK )
                    WHERE   ImportTemplate = @template
                            AND RecordType = @detailrectype
                            AND RecordSeq = @detailrecseq
                            AND Identifier = @detailkeyident
                            AND ImportId = @importid

		--Get the first identifier for this RecordSequence
                    SELECT  @detailident = MIN(Identifier)
                    FROM    IMWE WITH ( NOLOCK )
                    WHERE   IMWE.ImportId = @importid
                            AND IMWE.ImportTemplate = @template
                            AND IMWE.RecordType = @detailrectype
                            AND IMWE.RecordSeq = @detailrecseq 
     
                    IF @detailkeycol = @headerkeycol 
                        BEGIN
                            WHILE @detailident IS NOT NULL 
                                BEGIN
                                    SELECT  @importcolumn = NULL ,
                                            @importvalue = NULL ,
                                            @coltype = NULL
                                    IF EXISTS ( SELECT  1
                                                FROM    INFORMATION_SCHEMA.COLUMNS c
                                                        JOIN DDUD d ON c.TABLE_NAME = d.TableName
                                                              AND c.COLUMN_NAME = d.ColumnName
                                                WHERE   ( c.CHARACTER_MAXIMUM_LENGTH > 60
                                                          OR c.CHARACTER_MAXIMUM_LENGTH = -1
                                                        )
                                                        AND d.Form = @detailform
                                                        AND d.Identifier = @detailident
                                                        AND d.TableName = @detailtable ) 
                                        BEGIN
                                            SELECT  @importcolumn = ( SELECT
                                                              DDUD.ColumnName
                                                              FROM
                                                              IMWENotes WITH ( NOLOCK )
                                                              LEFT OUTER JOIN DDUD
                                                              WITH ( NOLOCK ) ON IMWENotes.Form = DDUD.Form
                                                              AND DDUD.TableName = @detailtable
                                                              AND DDUD.Identifier = IMWENotes.Identifier
                                                              WHERE
                                                              IMWENotes.ImportId = @importid
                                                              AND IMWENotes.ImportTemplate = @template
                                                              AND IMWENotes.RecordType = @detailrectype
                                                              AND IMWENotes.Identifier = @detailident
                                                              AND IMWENotes.RecordSeq = @detailrecseq
                                                              )
 
                                            SELECT  @importvalue = ( SELECT
                                                              IMWENotes.UploadVal
                                                              FROM
                                                              IMWENotes WITH ( NOLOCK )
                                                              LEFT OUTER JOIN DDUD
                                                              WITH ( NOLOCK ) ON IMWENotes.Form = DDUD.Form
                                                              AND DDUD.TableName = @detailtable
                                                              AND DDUD.Identifier = IMWENotes.Identifier
                                                              WHERE
                                                              IMWENotes.ImportId = @importid
                                                              AND IMWENotes.ImportTemplate = @template
                                                              AND IMWENotes.RecordType = @detailrectype
                                                              AND IMWENotes.Identifier = @detailident
                                                              AND IMWENotes.RecordSeq = @detailrecseq
                                                              )
                                        END
                                    ELSE 
                                        BEGIN
                                            SELECT  @importcolumn = ( SELECT
                                                              DDUD.ColumnName
                                                              FROM
                                                              IMWE WITH ( NOLOCK )
                                                              LEFT OUTER JOIN DDUD
                                                              WITH ( NOLOCK ) ON IMWE.Form = DDUD.Form
                                                              AND DDUD.TableName = @detailtable
                                                              AND DDUD.Identifier = IMWE.Identifier
                                                              WHERE
                                                              IMWE.ImportId = @importid
                                                              AND IMWE.ImportTemplate = @template
                                                              AND IMWE.RecordType = @detailrectype
                                                              AND IMWE.Identifier = @detailident
                                                              AND IMWE.RecordSeq = @detailrecseq
                                                              )
 
                                            SELECT  @importvalue = ( SELECT
                                                              IMWE.UploadVal
                                                              FROM
                                                              IMWE WITH ( NOLOCK )
                                                              LEFT OUTER JOIN DDUD
                                                              WITH ( NOLOCK ) ON IMWE.Form = DDUD.Form
                                                              AND DDUD.TableName = @detailtable
                                                              AND DDUD.Identifier = IMWE.Identifier
                                                              WHERE
                                                              IMWE.ImportId = @importid
                                                              AND IMWE.ImportTemplate = @template
                                                              AND IMWE.RecordType = @detailrectype
                                                              AND IMWE.Identifier = @detailident
                                                              AND IMWE.RecordSeq = @detailrecseq
                                                              )
                                        END
					
                                    IF @importcolumn IS NOT NULL 
                                        BEGIN
                                            IF @importcolumn = 'BatchId' 
                                                SELECT  @importvalue = @batchid
 
                                            IF @importcolumn = 'Mth' 
                                                SELECT  @importvalue = @batchmth
 
                                            IF @importcolumn = 'BatchSeq' 
                                                SELECT  @importvalue = @batchseq
 
                                            IF @importvalue = ''
                                                OR @importvalue IS NULL 
                                                BEGIN	
                                                    IF ( SELECT
                                                              COLUMNPROPERTY(OBJECT_ID(@detailrectype),
                                                              @importcolumn,
                                                              'AllowsNull')
                                                       ) = 0 
 						--update upload value...message that Table.Column cannot be null
 						--stop developing this record, go to next record sequence
                                                        BEGIN 
                                                            SELECT
                                                              @rcode = 1 ,
                                                              @detailerr = 1
                                                            SELECT
                                                              @errmsg = 'Column : '
                                                              + @importcolumn
                                                              + ' does not allow null values! See Identifier '
                                                              + CONVERT(VARCHAR(10), @detailident)
     
 							--Build error message to input after transaction rollback, otherwise gets rolled back!
                                                            SELECT
                                                              @IMWMinsert = 'insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier) '
                                                              + 'values ('
                                                              + CHAR(@quote)
                                                              + @importid
                                                              + CHAR(@quote)
                                                              + ','
                                                              + CHAR(@quote)
                                                              + @template
                                                              + CHAR(@quote)
                                                              + ','
                                                              + CHAR(@quote)
                                                              + @secondform
                                                              + CHAR(@quote)
                                                              + ','
                                                              + CONVERT(VARCHAR(10), @detailrecseq)
                                                              + ','
                                                              + CONVERT(VARCHAR(10), @detailerr)
                                                              + ','
                                                              + CHAR(@quote)
                                                              + @errmsg
                                                              + CHAR(@quote)
                                                              + ','
                                                              + @detailident
                                                              + ')'
     
                                                            GOTO GetNextHeaderReqSeq	--Exit on first detail error, because we can't store more than one insert statement for IMWM.
                                                        END
                                                    ELSE 
                                                        SELECT
                                                              @importvalue = NULL
                                                END
     					
 					--Catch fields with embedded single quotes...
                                            IF CHARINDEX(CHAR(@quote),
                                                         @importvalue) > 0 
                                                BEGIN
 						--replace single quotes with single back-quotes
                                                    SELECT  @importvalue = REPLACE(@importvalue,
                                                              CHAR(@quote),
                                                              '`')
                                                END
     
 					--Varchar, Char, and Smalldatetime data types need to be encapsulated in '''
                                            SELECT  @coltype = ColType
                                            FROM    DDUD
                                            WHERE   Form = @detailform
                                                    AND Identifier = @detailident
     
                                            IF @coltype = 'varchar'
                                                OR @coltype = 'text' 
                                                BEGIN
                                                    IF ISNULL(@importvalue, '') <> '' 
                                                        BEGIN
                                                            SELECT
                                                              @importvalue = CHAR(@quote)
                                                              + @importvalue
                                                              + CHAR(@quote)
                                                        END
                                                    ELSE 
                                                        BEGIN
                                                            SELECT
                                                              @importvalue = 'char(null)'
                                                        END
                                                END
     
 					--if @coltype = 'char' select @importvalue = char(@quote) + @importvalue + char(@quote)
                                            IF @coltype = 'char' 
                                                BEGIN
                                                    IF ISNULL(@importvalue, '') <> '' 
                                                        BEGIN
                                                            SELECT
                                                              @importvalue = CHAR(@quote)
                                                              + @importvalue
                                                              + CHAR(@quote)
                                                        END
                                                    ELSE 
                                                        BEGIN
                                                            SELECT
                                                              @importvalue = 'char(null)'
                                                        END
                                                END
     
     				--if @coltype = 'smalldatetime' select @importvalue = char(@quote) + ltrim(@importvalue) + char(@quote)
                                            IF @coltype = 'smalldatetime' 
                                                BEGIN
                                                    IF ISNULL(@importvalue, '') <> '' 
                                                        BEGIN
                                                            SELECT
                                                              @importvalue = CHAR(@quote)
                                                              + LTRIM(@importvalue)
                                                              + CHAR(@quote)
                                                        END
                                                    ELSE 
                                                        BEGIN
                                                            SELECT
                                                              @importvalue = 'char(null)'
                                                        END
                                                END
     
                                            IF @coltype = 'tinyint'
                                                OR @coltype = 'int'
                                                OR @coltype = 'numeric' 
                                                BEGIN
                                                    IF ISNULL(@importvalue, '') = '' 
                                                        SELECT
                                                              @importvalue = 'char(null)'
                                                END
     
                                            IF @coltype IN ( 'bigint', 'int',
                                                             'smallint',
                                                             'tinyint',
                                                             'decimal',
                                                             'numeric',
                                                             'money',
                                                             'smallmoney',
                                                             'float', 'real' ) 
                                                BEGIN
                                                    SET @importvalue = REPLACE(@importvalue,
                                                              ',', '') --CC issue #127127
                                                    IF ISNUMERIC(@importvalue) <> 1
                                                        AND @importvalue IS NOT NULL
                                                        AND @importvalue <> 'char(null)' 
                                                        BEGIN
                                                            SELECT
                                                              @rcode = 1 ,
                                                              @detailerr = 1
                                                            SELECT
                                                              @errmsg = 'Column : '
                                                              + @importcolumn
                                                              + ' does not allow non-numeric values! See Identifier '
                                                              + CONVERT(VARCHAR(10), @detailident)
     					
     						--Build error message to input after transaction rollback, otherwise gets rolled back!
                                                            SELECT
                                                              @IMWMinsert = 'insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier) '
                                                              + 'values ('
                                                              + CHAR(@quote)
                                                              + @importid
                                                              + CHAR(@quote)
                                                              + ','
                                                              + CHAR(@quote)
                                                              + @template
                                                              + CHAR(@quote)
                                                              + ','
                                                              + CHAR(@quote)
                                                              + @secondform
                                                              + CHAR(@quote)
                                                              + ','
                                                              + CONVERT(VARCHAR(10), @detailrecseq)
                                                              + ','
                                                              + CONVERT(VARCHAR(10), @detailerr)
                                                              + ','
                                                              + CHAR(@quote)
                                                              + @errmsg
                                                              + CHAR(@quote)
                                                              + ','
                                                              + @detailident
                                                              + ')'
     
                                                            GOTO GetNextHeaderReqSeq	--Save time by exiting now, but remaining details may have errors.
                                                        END
                                                END
     
                                            IF @importvalue IS NOT NULL 
                                                BEGIN
                                                    IF @detailvallist IS NOT NULL 
                                                        SELECT
                                                              @detailvallist = @detailvallist
                                                              + ','
                                                              + @importvalue
                                                    ELSE 
                                                        SELECT
                                                              @detailvallist = 'values ('
                                                              + @importvalue 
     
                                                    IF @detailcollist IS NOT NULL 
                                                        SELECT
                                                              @detailcollist = @detailcollist
                                                              + ','
                                                              + @importcolumn
                                                    ELSE 
                                                        SELECT
                                                              @detailcollist = 'insert into '
                                                              + @detailtable
                                                              + ' ('
                                                              + @importcolumn 
                                                END
                                        END
     
     			--Get the next identifier for this RecordSequence
                                    SELECT  @detailident = MIN(Identifier)
                                    FROM    ( SELECT    MIN(Identifier) AS Identifier
                                              FROM      IMWE WITH ( NOLOCK )
                                              WHERE     IMWE.ImportId = @importid
                                                        AND IMWE.ImportTemplate = @template
                                                        AND IMWE.RecordType = @detailrectype
                                                        AND IMWE.RecordSeq = @detailrecseq
                                                        AND IMWE.Identifier > @detailident
                                              UNION ALL
                                              SELECT    MIN(Identifier) AS Identifier
                                              FROM      IMWENotes WITH ( NOLOCK )
                                              WHERE     IMWENotes.ImportId = @importid
                                                        AND IMWENotes.ImportTemplate = @template
                                                        AND IMWENotes.RecordType = @detailrectype
                                                        AND IMWENotes.RecordSeq = @detailrecseq
                                                        AND IMWENotes.Identifier > @detailident
                                            ) AS IMWEUnion 
                                END	--develop detail 
     
                            SELECT  @detailinsert = @detailcollist + ') '
                                    + @detailvallist + ')'
     
                            DELETE  FROM IMWM
                            WHERE   ImportId = @importid
                                    AND Error = 9999
                            INSERT  INTO IMWM
                                    ( ImportId ,
                                      ImportTemplate ,
                                      Form ,
                                      RecordSeq ,
                                      Error ,
                                      Message ,
                                      SQLStatement
                                    )
                            VALUES  ( @importid ,
                                      @template ,
                                      @headform ,
                                      @detailrecseq ,
                                      9999 ,
                                      '' ,
                                      @detailinsert
                                    )
   
                            SELECT  @errcode = 0
    
                            BEGIN TRY
                                EXEC(@detailinsert)
                            END TRY 
		   
                            BEGIN CATCH
                                SELECT  @errcode = ERROR_NUMBER() ,
                                        @ErrorMessage = ERROR_MESSAGE() ,
                                        @rcode = 1

		-- Test whether the transaction is uncommittable.
                                IF XACT_STATE() <> 0 
                                    BEGIN
                                        ROLLBACK TRANSACTION ;
                                        SET @intrans = 0
                                    END

                                UPDATE  IMWM
                                SET     Error = @errcode ,
                                        Message = @ErrorMessage
                                WHERE   ImportId = @importid
                                        AND ImportTemplate = @template
                                        AND Form = @detailform
                                        AND RecordSeq = @detailrecseq
		    
                                IF @@rowcount <> 1 
                                    BEGIN
                                        INSERT  IMWM
                                                ( ImportId ,
                                                  ImportTemplate ,
                                                  Form ,
                                                  RecordSeq ,
                                                  Error ,
                                                  Message
                                                )
                                        VALUES  ( @importid ,
                                                  @template ,
                                                  @detailform ,
                                                  @detailrecseq ,
                                                  @errcode ,
                                                  @ErrorMessage
                                                )
                                    END
                            END CATCH
     
                            IF @errcode <> 0 
                                BEGIN
                                    SELECT  @detailerr = 1
                                    GOTO GetNextHeaderReqSeq
                                END
     
                            SELECT  @detailcollist = NULL
                            SELECT  @detailvallist = NULL
                            SELECT  @detailinsert = NULL
                        END
	
                    GetNextDetailReqSeq:
     
                    IF @detailerr = 0 
                        BEGIN 
     		--only delete if detailkey and headerkey match
                            IF @detailkeycol = @headerkeycol 
                                BEGIN
                                    SELECT  @deletestmt = 'Delete IMWE where ImportId = '
                                            + CHAR(@quote) + @importid
                                            + CHAR(@quote)
                                            + ' and RecordSeq = '
                                            + CONVERT(VARCHAR(5), @detailrecseq)
                                            + ' and RecordType = '
                                            + CHAR(@quote) + @detailrectype
                                            + CHAR(@quote)  
     
                                    EXEC(@deletestmt)
                                    SELECT  @deletestmt = NULL
				
                                    SELECT  @deletestmt = 'DELETE IMWENotes WHERE ImportId = '
                                            + CHAR(@quote) + @importid
                                            + CHAR(@quote)
                                            + ' AND RecordSeq = '
                                            + CONVERT(VARCHAR(5), @detailrecseq)
                                            + ' AND RecordType = '
                                            + CHAR(@quote) + @detailrectype
                                            + CHAR(@quote)  
     
                                    EXEC(@deletestmt)
                                    SELECT  @deletestmt = NULL	
                                END
                        END
                    ELSE 
                        BEGIN
                            SELECT  @errdesc = description
                            FROM    master.dbo.sysmessages
                            WHERE   error = @errcode
                        END
     
                    SELECT  @detailcollist = NULL ,
                            @detailvallist = NULL
     
                    FETCH NEXT FROM DetailCursor INTO @detailrecseq
                    SELECT  @dcstatus = @@FETCH_STATUS
     
                END
     
 --get next header record
            GetNextHeaderReqSeq:
 
            IF @DetailCursorOpen = 1 
                BEGIN
                    CLOSE DetailCursor
                    SELECT  @DetailCursorOpen = 0
                    DEALLOCATE DetailCursor
                END

            SELECT  @detailcollist = NULL
            SELECT  @detailvallist = NULL
            SELECT  @detailinsert = NULL
 	
            IF @headerr = 0
                AND @detailerr = 0 
                BEGIN 
                    IF @intrans = 1 
                        BEGIN
                            COMMIT TRANSACTION
                            SELECT  @intrans = 0	
                        END
 
 		--Delete Record from IMWE
                    SELECT  @deletestmt = 'Delete IMWE where ImportId = '
                            + CHAR(@quote) + @importid + CHAR(@quote)
                            + ' and RecordSeq = '
                            + CONVERT(VARCHAR(5), @headrecseq)
                            + ' and RecordType = ' + CHAR(@quote)
                            + @headrectype + CHAR(@quote)
 
                    EXEC(@deletestmt)
                    SELECT  @deletestmt = NULL
 
                    SELECT  @deletestmt = 'DELETE IMWENotes WHERE ImportId = '
                            + CHAR(@quote) + @importid + CHAR(@quote)
                            + ' AND RecordSeq = '
                            + CONVERT(VARCHAR(5), @detailrecseq)
                            + ' AND RecordType = ' + CHAR(@quote)
                            + @detailrectype + CHAR(@quote)  
 
                    EXEC(@deletestmt)
                    SELECT  @deletestmt = NULL	
 		--Update IMBC 
                    IF @batchid IS NOT NULL 
                        BEGIN
                            SELECT  @imbccount = ( SELECT   COUNT(ImportId)
                                                   FROM     IMBC
                                                   WHERE    ImportId = @importid
                                                            AND Co = @co
                                                            AND Mth = @batchmth
                                                            AND BatchId = @batchid
                                                 )
 
                            IF @imbccount = 0 
                                BEGIN
                                    INSERT  IMBC
                                            ( ImportId ,
                                              Co ,
                                              Mth ,
                                              BatchId ,
                                              RecordCount
                                            )
                                    VALUES  ( @importid ,
                                              @co ,
                                              @batchmth ,
                                              @batchid ,
                                              1
                                            )
                                END
 
                            IF @imbccount = 1 
                                BEGIN
                                    UPDATE  IMBC
                                    SET     RecordCount = RecordCount + 1
                                    WHERE   ImportId = @importid
                                            AND Co = @co
                                            AND Mth = @batchmth
                                            AND BatchId = @batchid
                                END
 
                            SELECT  @imbccount = NULL
                        END
                END
            ELSE 
                BEGIN
                    IF @intrans = 1 
                        BEGIN
                            ROLLBACK TRANSACTION
                            SELECT  @intrans = 0
                        END

                    SELECT  @rcode = 1
                    SELECT  @errmsg = 'Data errors.  Check IM Work Edit and IMWM.'
                END
 		
            SkipDeleteHeaderGetNext:
            SELECT  @columnlist = NULL ,
                    @valuelist = NULL ,
                    @headerr = 0
 
            SELECT  @IMWMinsert = NULL
 
            FETCH NEXT FROM HeaderCursor INTO @headrecseq
            SELECT  @hcstatus = @@FETCH_STATUS
        END --end outer while

/* Begin the Automatic batch Validation and Posting. */
--select @valproc = ValProc, @postproc = PostProc
--from IMTH			--Or DDUF
--where ImportTemplate = @template and Form = @headform

    IF @relexists = 'Y'
        OR ( @valproc IS NOT NULL
             AND @postproc IS NOT NULL
           ) 
        BEGIN
	/* Automatic validation and posting will only occur if user has entered both the Validation procedure
	   and the Posting procedure during setup.  The exception is when importing a text file with AP Release
	   Retainage entries (ie. Textura import file).  In this case, automatic Validation and Posting must 
	   occur regardless. */
            IF @batchyn = 'Y'
                AND @co IS NOT NULL
                AND @batchmth IS NOT NULL
                AND @batchid IS NOT NULL 
                BEGIN
                    SELECT  @posterrmsg = 'Batch Posting has failed.  Contact Viewpoint support.'
                            + CHAR(10) + CHAR(13)
                    IF @relexists = 'N' 
                        BEGIN
			/* ValProc and PostProc come from import setup.  Set appropriate and generic validation errmsg only. */
                            SELECT  @valerrmsg = 'Batch Validation errors exist.  Manually validate batch, check the error list and make repairs.  '
                            SELECT  @valerrmsg = @valerrmsg
                                    + 'When fixed, you will need to manually validate and post the corrected batch.'
                                    + CHAR(10) + CHAR(13)
                        END
                    ELSE 
                        BEGIN
			/* Special Release Retainage import file.  ValProc and PostProc can come from import setup but if not available
			   we must hardcode the appropriate routine.  In addition, set up special validation errmsg specific to this situation. 
			   Currently only affects AP Transaction Entry but could be expanded. */
                            IF @headform = 'APEntry' 
                                BEGIN
                                    SELECT  @valproc = ISNULL(@valproc,
                                                              'bspAPHBVal')
                                    SELECT  @postproc = ISNULL(@postproc,
                                                              'bspAPHBPost')
                                END
				
                            SELECT  @valerrmsg = 'Batch Validation errors exist.  Manually Validate Batch, check the error list and make repairs.  When fixed, '
                            SELECT  @valerrmsg = @valerrmsg
                                    + 'you will need to manually validate and post, then rerun UPLOAD to finish Release Retainage process.'
                                    + CHAR(10) + CHAR(13)
                        END
					 			
		/* Lock the batch */
                    SELECT  @batchlock = 'update HQBC set InUseBy = '
                            + CHAR(@quote) + SUSER_SNAME() + CHAR(@quote)
                            + ' where Co = ' + CONVERT(VARCHAR(3), @co)
                            + ' and Mth = ' + CHAR(@quote)
                            + CONVERT(VARCHAR(30), @batchmth) + CHAR(@quote)
                            + ' and BatchId = ' + CONVERT(VARCHAR(6), @batchid) 
		
                    EXEC(@batchlock)
		
		/* Automatic Validation */
                    EXEC @rcode = @valproc @co, @batchmth, @batchid,
                        @errmsg OUTPUT
                    IF EXISTS ( SELECT TOP 1
                                        1
                                FROM    HQBE WITH ( NOLOCK )
                                WHERE   Co = @co
                                        AND Mth = @batchmth
                                        AND BatchId = @batchid )
                        OR @rcode = 1 
                        BEGIN
                            SELECT  @rcode = 1
                            SELECT  @errmsg = @valerrmsg
 			
 			/* This error reporting is a little flaky but makes sense to the user.  All normal record sequences have long
 			   since been deleted in IMWE by this point.  The error that has occurred is relative to the Batch validation and posting.
 			   This occurs immediately after the import finishes uploading normal sequences to batch tables.  Therefore we attach
 			   this error to remaining "Release" import records in IMWE at the Header level using the last known Header Record Seq
 			   processed.  It will display to the user for an import record sequence that no longer exists but the error text
 			   will clearly stated that the failure was during batch processing and will instruct the user as to how to proceed. */
                            INSERT  IMWM
                                    ( ImportId ,
                                      ImportTemplate ,
                                      Form ,
                                      RecordSeq ,
                                      Message ,
                                      Identifier
                                    )
                            VALUES  ( @importid ,
                                      @template ,
                                      @firstform ,
                                      @headrecseq ,
                                      @errmsg ,
                                      @ident
                                    )
			
			/* Validation has failed.  Reset Batch control so that user may correct the problem. */
                            UPDATE  bHQBC
                            SET     Status = 0 ,
                                    InUseBy = NULL
                            WHERE   Co = @co
                                    AND Mth = @batchmth
                                    AND BatchId = @batchid
                        END
                    ELSE 
                        BEGIN
			/* Automatic Posting */
                            EXEC @rcode = @postproc @co, @batchmth, @batchid,
                                @autopostdate, @errmsg OUTPUT
                            IF @rcode = 1 
                                BEGIN
                                    SELECT  @rcode = 1
                                    SELECT  @errmsg = @posterrmsg
 				
                                    INSERT  IMWM
                                            ( ImportId ,
                                              ImportTemplate ,
                                              Form ,
                                              RecordSeq ,
                                              Message ,
                                              Identifier
                                            )
                                    VALUES  ( @importid ,
                                              @template ,
                                              @firstform ,
                                              @headrecseq ,
                                              @errmsg ,
                                              @ident
                                            )
                                END
                        END
			
		/* Unlock the batch */
                    SELECT  @batchunlock = 'update HQBC set InUseBy = null where Co = '
                            + CONVERT(VARCHAR(3), @co) + ' and Mth = '
                            + CHAR(@quote) + CONVERT(VARCHAR(30), @batchmth)
                            + CHAR(@quote) + ' and BatchId = '
                            + CONVERT(VARCHAR(6), @batchid) 

                    EXEC(@batchunlock)
		
		/* If either a Validation or a Posting error has occured, exit now. */
                    IF @rcode = 1 
                        GOTO bspexit
                END
	
	/* Automatic validation and posting was successful.  If Release Retainage import records exist, process them now. */
            IF @relexists = 'Y' 
                BEGIN
		/* Header Release Cursor.  */
                    DECLARE bcHeaderRel CURSOR local fast_forward
                    FOR
                        SELECT  MAX(CASE WHEN Identifier = @releaseretgflagID
                                         THEN RecordSeq
                                    END) AS 'RecSeq' ,
                                MAX(CASE WHEN Identifier = @releaseretgflagID
                                         THEN UploadVal
                                    END) AS 'RelRetgFlag' ,
                                MAX(CASE WHEN Identifier = @disttaxflagID
                                         THEN UploadVal
                                    END) AS 'DistTaxFlag' ,
                                MAX(CASE WHEN Identifier = @headerkeyident
                                         THEN UploadVal
                                    END) AS 'RecKey' ,
                                MAX(CASE WHEN Identifier = @coident
                                         THEN UploadVal
                                    END) AS 'Co' ,
                                MAX(CASE WHEN Identifier = @vendorgroupID
                                         THEN UploadVal
                                    END) AS 'VendorGroup' ,		--APEntry only
                                MAX(CASE WHEN Identifier = @vendorID
                                         THEN UploadVal
                                    END) AS 'Vendor'				--APEntry only						
                        FROM    dbo.IMWE WITH ( NOLOCK )
                        WHERE   ImportId = @importid
                                AND ImportTemplate = @template
                                AND RecordType = @headrectype
                        GROUP BY RecordSeq
                        HAVING  MAX(CASE WHEN Identifier = @releaseretgflagID
                                         THEN UploadVal
                                    END) = 'R'
                        ORDER BY RecKey

                    OPEN bcHeaderRel
                    SELECT  @openHeaderRelcursor = 1
		
                    FETCH NEXT FROM bcHeaderRel INTO @headrecseq, @relretgflag,
                        @disttaxflag, @headerreckey, @co, @vendorgroup,
                        @vendor
                    WHILE @@fetch_status = 0 
                        BEGIN	/* Begin generic Header Release loop */
   			/* Call Unique Procedures to process Release Retainage import records. 
			   Currently only affects AP Transaction Entry but could be expanded. */
   			/* AP Entry Release */
                            IF @headform = 'APEntry' 
                                BEGIN	/* Begin AP Entry Detail Release loop. */
                                    SELECT  @headererrorid = NULL
   				
   				/* Check for required Header values */
                                    IF @co IS NULL
                                        OR @co = 0		--@co = 0 required: When value removed from Work Edit, tinyint empty string is replaced with 0.	
                                        BEGIN
                                            SELECT  @headererrorid = 0
                                            SELECT  @errmsg = 'Missing AP Company.'
                                        END
                                    IF ISNULL(@vendorgroup, '') = '' 
                                        BEGIN
                                            SELECT  @headererrorid = 1
                                            SELECT  @errmsg = 'AP Vendor Group is missing.'
                                        END
                                    ELSE 
                                        BEGIN
                                            IF NOT EXISTS ( SELECT TOP 1
                                                              1
                                                            FROM
                                                              bHQCO WITH ( NOLOCK )
                                                            WHERE
                                                              HQCo = @co
                                                              AND VendorGroup = @vendorgroup ) 
                                                BEGIN
                                                    SELECT  @headererrorid = 1
                                                    SELECT  @errmsg = 'Not a valid Vendor Group for this AP Company.'
                                                END	  					
                                        END
                                    IF ISNULL(@vendor, '') = '' 
                                        BEGIN
                                            SELECT  @headererrorid = 2
                                            SELECT  @errmsg = 'AP Vendor is missing.'
                                        END
                                    ELSE 
                                        BEGIN
                                            IF NOT EXISTS ( SELECT TOP 1
                                                              1
                                                            FROM
                                                              bAPVM WITH ( NOLOCK )
                                                            WHERE
                                                              VendorGroup = @vendorgroup
                                                              AND Vendor = @vendor ) 
                                                BEGIN
                                                    SELECT  @headererrorid = 2
                                                    SELECT  @errmsg = 'Not a valid AP Vendor.'
                                                END	   					
                                        END
   				
                                    IF @headererrorid IS NOT NULL 
                                        BEGIN
                                            SELECT  @relrcode = 1 
                                            SELECT  @relerrmsg = @errmsg
                                            SELECT  @ident = CASE
                                                              WHEN @headererrorid = 0
                                                              THEN @coident
                                                              WHEN @headererrorid = 1
                                                              THEN @vendorgroupID
                                                              WHEN @headererrorid = 2
                                                              THEN @vendorID
                                                             END
						
                                            INSERT  IMWM
                                                    ( ImportId ,
                                                      ImportTemplate ,
                                                      Form ,
                                                      RecordSeq ,
                                                      Message ,
                                                      Identifier
                                                    )
                                            VALUES  ( @importid ,
                                                      @template ,
                                                      @firstform ,
                                                      @headrecseq ,
                                                      @errmsg ,
                                                      @ident
                                                    )
							
                                            GOTO Get_Next_HeaderR
                                        END
 							
                                    DECLARE bcAPLBRel CURSOR local fast_forward
                                    FOR
                                        SELECT  MAX(CASE WHEN Identifier = @detailkeyID
                                                         THEN RecordSeq
                                                    END) AS 'RecSeq' ,
                                                MAX(CASE WHEN Identifier = @detailkeyID
                                                         THEN UploadVal
                                                    END) AS 'RecKey' ,
                                                MAX(CASE WHEN Identifier = @linetypeID
                                                         THEN UploadVal
                                                    END) AS 'LineType' ,
                                                MAX(CASE WHEN Identifier = @slID
                                                         THEN UploadVal
                                                    END) AS 'SL' ,
                                                MAX(CASE WHEN Identifier = @slitemID
                                                         THEN UploadVal
                                                    END) AS 'SLItem' ,
                                                MAX(CASE WHEN Identifier = @jccoID
                                                         THEN UploadVal
                                                    END) AS 'JCCo' ,
                                                MAX(CASE WHEN Identifier = @jobID
                                                         THEN UploadVal
                                                    END) AS 'Job' ,
                                                MAX(CASE WHEN Identifier = @phasegroupID
                                                         THEN UploadVal
                                                    END) AS 'PhaseGroup' ,
                                                MAX(CASE WHEN Identifier = @phaseID
                                                         THEN UploadVal
                                                    END) AS 'Phase' ,
                                                MAX(CASE WHEN Identifier = @grossamtID
                                                         THEN UploadVal
                                                    END) AS 'RelAmount'
                                        FROM    dbo.IMWE WITH ( NOLOCK )
                                        WHERE   ImportId = @importid
                                                AND ImportTemplate = @template
                                                AND RecordType = @detailrectype
                                        GROUP BY RecordSeq
                                        HAVING  MAX(CASE WHEN Identifier = @detailkeyID
                                                         THEN UploadVal
                                                    END) = @headerreckey

                                    OPEN bcAPLBRel
                                    SELECT  @openAPLBRelcursor = 1
				
                                    FETCH NEXT FROM bcAPLBRel INTO @detailrecseq,
                                        @detailreckey, @aplinetype, @sl,
                                        @slitem, @jcco, @job, @phasegroup,
                                        @phase, @detailrelamount
                                    WHILE @@fetch_status = 0 
                                        BEGIN	/* Begin Invoice Process loop */
                                            IF ISNULL(@detailrelamount, '') = ''
                                                OR CONVERT(NUMERIC(12, 2), @detailrelamount) = 0 
                                                BEGIN
                                                    GOTO Delete_DetailR
                                                END
	
                                            SELECT  @errorid = NULL
   					/* There are two possible situations here:
   						1) These values do NOT exist in the import file and thus the IMWE Upload value is NULL
   						2) The user has removed a value directly by deleting it in the work edit form.  Therefore the IMWE Upload value is EMPTY STRING
   					   
   					   Due to this, in order for validation and error reporting to work for both conditions we need to pass in
   					   a NULL value whenever the Upload value is NULL or EMPTY STRING. */
                                            IF ISNULL(@aplinetype, '') = '' 
                                                SELECT  @aplinetype = NULL
                                            IF ISNULL(@sl, '') = '' 
                                                SELECT  @sl = NULL
                                            IF ISNULL(@slitem, '') = '' 
                                                SELECT  @slitem = NULL
                                            IF ISNULL(@jcco, '') = '' 
                                                SELECT  @jcco = NULL
                                            IF ISNULL(@job, '') = '' 
                                                SELECT  @job = NULL
                                            IF ISNULL(@phasegroup, '') = '' 
                                                SELECT  @phasegroup = NULL
                                            IF ISNULL(@phase, '') = '' 
                                                SELECT  @phase = NULL
                                            IF ISNULL(@detailrelamount, '') = '' 
                                                SELECT  @detailrelamount = 0
   					
   					/* Release Retainage */
                                            EXEC @rcode = dbo.vspIMProcessReleaseRetgAP @co,
                                                @aplinetype, @sl, @slitem,
                                                @jcco, @job, @phasegroup,
                                                @phase, @detailrelamount,
                                                @disttaxflag, @vendorgroup,
                                                @vendor, @errorid OUTPUT,
                                                @errmsg OUTPUT
                                            IF @rcode = 1 
                                                BEGIN
                                                    SELECT  @relrcode = 1 ,
                                                            @relerrmsg = @errmsg
                                                    SELECT  @detailident = CASE
                                                              WHEN @errorid = 0
                                                              THEN @coident
                                                              WHEN @errorid = 1
                                                              THEN @grossamtID
                                                              WHEN @errorid = 2
                                                              THEN @linetypeID
                                                              WHEN @errorid = 3
                                                              THEN @slID
                                                              WHEN @errorid = 4
                                                              THEN @slitemID
                                                              WHEN @errorid = 5
                                                              THEN @jccoID
                                                              WHEN @errorid = 6
                                                              THEN @jobID
                                                              WHEN @errorid = 7
                                                              THEN @phasegroupID
                                                              WHEN @errorid = 8
                                                              THEN @phaseID
                                                              END
						
                                                    INSERT  IMWM
                                                            ( ImportId ,
                                                              ImportTemplate ,
                                                              Form ,
                                                              RecordSeq ,
                                                              Message ,
                                                              Identifier
                                                            )
                                                    VALUES  ( @importid ,
                                                              @template ,
                                                              @secondform ,
                                                              @detailrecseq ,
                                                              @errmsg ,
                                                              @detailident
                                                            )
							
                                                    GOTO Get_Next_APLine
                                                END
 				
                                            Delete_DetailR:	
                                            SELECT  @deletestmt = 'Delete IMWE where ImportId = '
                                                    + CHAR(@quote) + @importid
                                                    + CHAR(@quote)
                                                    + ' and RecordSeq = '
                                                    + CONVERT(VARCHAR(5), @detailrecseq)
                                                    + ' and RecordType = '
                                                    + CHAR(@quote)
                                                    + @detailrectype
                                                    + CHAR(@quote)  
     
                                            EXEC(@deletestmt)
                                            SELECT  @deletestmt = NULL
     			
                                            Get_Next_APLine:		
                                            FETCH NEXT FROM bcAPLBRel INTO @detailrecseq,
                                                @detailreckey, @aplinetype,
                                                @sl, @slitem, @jcco, @job,
                                                @phasegroup, @phase,
                                                @detailrelamount
                                        END
				
                                    IF @openAPLBRelcursor = 1 
                                        BEGIN
                                            CLOSE bcAPLBRel
                                            DEALLOCATE bcAPLBRel
                                            SELECT  @openAPLBRelcursor = 0
                                        END
                                END		/* End AP Entry Detail Release loop. */

                            Delete_HeaderR:
                            IF EXISTS ( SELECT  MAX(CASE WHEN Identifier = @detailkeyID
                                                         THEN RecordSeq
                                                    END) AS 'RecSeq' ,
                                                MAX(CASE WHEN Identifier = @detailkeyID
                                                         THEN UploadVal
                                                    END) AS 'RecKey'
                                        FROM    dbo.IMWE WITH ( NOLOCK )
                                        WHERE   ImportId = @importid
                                                AND ImportTemplate = @template
                                                AND RecordType = @detailrectype
                                        GROUP BY RecordSeq
                                        HAVING  MAX(CASE WHEN Identifier = @detailkeyID
                                                         THEN UploadVal
                                                    END) = @headerreckey ) 
                                BEGIN
                                    GOTO Get_Next_HeaderR
                                END
	
                            SELECT  @deletestmt = 'Delete IMWE where ImportId = '
                                    + CHAR(@quote) + @importid + CHAR(@quote)
                                    + ' and RecordSeq = '
                                    + CONVERT(VARCHAR(5), @headrecseq)
                                    + ' and RecordType = ' + CHAR(@quote)
                                    + @headrectype + CHAR(@quote)

                            EXEC(@deletestmt)
                            SELECT  @deletestmt = NULL
			
                            Get_Next_HeaderR:
                            FETCH NEXT FROM bcHeaderRel INTO @headrecseq,
                                @relretgflag, @disttaxflag, @headerreckey, @co,
                                @vendorgroup, @vendor
                        END		/* End generic Header Release loop */

                    IF @openHeaderRelcursor = 1 
                        BEGIN
                            CLOSE bcHeaderRel
                            DEALLOCATE bcHeaderRel
                            SELECT  @openHeaderRelcursor = 0
                        END
                END
        END

/* If no other Upload errors have occurred, check for Release Retainage errors. */
    IF ( @rcode = 0
         AND @relrcode = 1
       ) 
        SELECT  @rcode = @relrcode ,
                @errmsg = @relerrmsg
		
    bspexit:
     
    IF @HeaderCursorOpen = 1 
        BEGIN
            CLOSE HeaderCursor
            SELECT  @HeaderCursorOpen = 0
            DEALLOCATE HeaderCursor
        END

    IF @openAPLBRelcursor = 1 
        BEGIN
            CLOSE bcAPLBRel
            DEALLOCATE bcAPLBRel
            SELECT  @openAPLBRelcursor = 0
        END
	
    IF @openHeaderRelcursor = 1 
        BEGIN
            CLOSE bcHeaderRel
            DEALLOCATE bcHeaderRel
            SELECT  @openHeaderRelcursor = 0
        END
								     
    IF @ANSIWARN = 1 
        SET ANSI_WARNINGS ON

    RETURN @rcode







GO
GRANT EXECUTE ON  [dbo].[bspIMUploadHeaderDetail] TO [public]
GO
