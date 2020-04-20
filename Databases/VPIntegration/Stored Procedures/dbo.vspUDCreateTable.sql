SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspUDCreateTable]
      /********************************************************
      	Created 03/08/01 RM
        Modified 09/04/02 RM - Added UniqueAttchID column to allow attachments.
     						RM 02/06/03 -  Issue#19874 - Added code for UseNotes in UD Tables
   						RM 04/29/03 - Issue#16329 - Code to allow decimals based on the input mask
   						RM 08/12/03 - Issue#22122 - Make Notes Column Nullable.
   						RM 10/21/03 - Issue#22787 - Make InputType=5 behave as InputType=0 when creating table
   						RM 10/30/03 - Issue#22809 - Invalid msg when @inputmask is null and @prec = 0,1 or 2
   						RM 11/06/03 = Issue#22809 - Change cursors to local cursors.
   						DANF 03/10/04 - Issue#20536 - Added Security Entries into DDSL for secured datatypes.
   						RM 06/29/04 - Issue#24787 - Increased ColumnName variables to 30 characters
   						RM 05/02/05 - Issue#26710 - InputType - Text, InputLength 0 was erroring.  Default 1000 when 0
						TIMP 07/18/07 - Added WITH EXECUTE AS 'viewpointcs'
						TIMP 08/09/07 - Changed to vspUDCreateTable
						TIMP 11/07/07 - Issue #124825 - Added KeyID column
						TIMP 12/11/07 - Issue #125965 - #12 in issue - Made bYN DEFAULT 'N' NOT NULL
						TIMP 12/14/07 - Issue #122074 - Added or @decpos is null to make sure Decimal Position is not Null
						RM   01/04/08 - Issue#126645 - change @datatype from varchar(15) to varchar(20)
						CC	 01/16/08 - Issue #126696 - Added case for month and date input type (when @inputtype in (2,3) then ('smalldatetime'))
						RM   02/06/09 - Issue #131327 - Added bigint precision
						CC	 05/26/09 - Issue #129627 - Added call to [vspUDUpdateAuditTriggers] to update auditing on UD table
						AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
						JA - 11/14/12 - TK-14366 Change UseNotes to UseNotesTab
		Usage
      		Used to create a UD table
     
      ********************************************************/
    (
      @tablename VARCHAR(30),
      @errmsg VARCHAR(255) OUTPUT
    )
    WITH EXECUTE AS 'viewpointcs'
AS 
    DECLARE @rcode INT,
        @createstring VARCHAR(5000),
        @keystring VARCHAR(255),
        @btablename VARCHAR(31)
     
    SELECT  @rcode = 0,
            @btablename = 'b' + @tablename
     
    DECLARE @columnname VARCHAR(30),
        @keyseq INT,
        @datatype VARCHAR(20),
        @inputtype INT,
        @inputmask VARCHAR(15),
        @inputlength INT,
        @prec INT,
        @systemdatatype VARCHAR(30),
        @usenotestab int,
        @formname bDesc,
        @Created bYN
   
    DECLARE @numerictype VARCHAR(30),
        @leftofdecimal INT,
        @rightofdecimal INT,
        @decpos INT,
        @errstart VARCHAR(100)
     
    IF @tablename IS NULL 
        BEGIN
            SELECT  @rcode = 1,
                    @errmsg = 'Table Name Missing!'
            GOTO bspexit
        END
   
    SELECT  @formname = ISNULL(FormName, ''),
            @Created = Created
    FROM    dbo.bUDTH WITH ( NOLOCK )
    WHERE   TableName = @tablename
    IF @Created = 'Y' 
        BEGIN
            SELECT  @rcode = 1,
                    @errmsg = 'Table has already been created.  You may now only alter the table.'
            GOTO bspexit
        END
     
    IF NOT EXISTS ( SELECT  *
                    FROM    bUDTC
                    WHERE   TableName = @tablename
                            AND KeySeq IS NOT NULL ) 
        BEGIN
            SELECT  @rcode = 1,
                    @errmsg = 'Must have at least one key field.'
            GOTO bspexit
        END
     
    IF NOT EXISTS ( SELECT  *
                    FROM    bUDTC
                    WHERE   TableName = @tablename
                            AND KeySeq IS  NULL ) 
        BEGIN
            SELECT  @rcode = 1,
                    @errmsg = 'Cannot create a key-only table.'
            GOTO bspexit
        END
   
    DECLARE createcursor CURSOR local fast_forward
    FOR
        SELECT  ColumnName,
                KeySeq,
                DataType,
                InputType,
                InputMask,
                InputLength,
                Prec
        FROM    bUDTC
        WHERE   TableName = @tablename
        ORDER BY DDFISeq
     
    DECLARE keycursor CURSOR local fast_forward
    FOR
        SELECT  ColumnName
        FROM    bUDTC
        WHERE   TableName = @tablename
                AND KeySeq IS NOT NULL
        ORDER BY KeySeq
     
    IF ( SELECT CompanyBasedYN
         FROM   bUDTH
         WHERE  TableName = @tablename
       ) = 'Y' 
        SELECT  @createstring = 'Co bCompany not null',
                @keystring = 'Co'
     
     
     
      --Get columns and info for create string
    OPEN createcursor
     
    FETCH NEXT FROM createcursor INTO @columnname, @keyseq, @datatype,
        @inputtype, @inputmask, @inputlength, @prec
     
    WHILE @@fetch_status = 0 
        BEGIN
     
            IF @createstring IS NOT NULL 
                SELECT  @createstring = @createstring + ', '
     
     
     
            SELECT  @systemdatatype = NULL
     
            IF NOT @datatype IS NULL 
                EXEC @rcode = vspDDDTGetDatatypeInfo @datatype,
                    @inputtype OUTPUT, @inputmask OUTPUT, @inputlength OUTPUT,
                    @prec OUTPUT, @systemdatatype OUTPUT, @errmsg OUTPUT
     
            IF ISNULL(@systemdatatype, '') = '' 
                BEGIN
   /*   		select @createstring =  isnull(@createstring, '') + '[' + @columnname + ']  ' + convert(varchar(50),case @inputtype when 0 then 'varchar(' + convert(varchar(10),isnull(@inputlength,30)) + ')'
      										when 1 then (case @prec when 0 then 'tinyint' when 1 then 'smallint' when 2 then 'int' when 3 then 'numeric' end)
      										when 2 then 'smalldatetime'
      										when 3 then 'smalldatetime'  
     										when 4 then 'smalldatetime' 
     										when 5 then 'varchar(' + convert(varchar(10),isnull(@inputlength,30)) + ')' end)
     										+ (case isnull(@keyseq,'') when '' then ' null' else ' not null' end)*/
   	    
                    SELECT  @errstart = 'Column: ''' + @columnname + ''' '
   

                    IF @inputtype = 1 
                        BEGIN

   			--strip out the positioning characters and other characters
                            SELECT  @inputmask = REPLACE(REPLACE(@inputmask,
                                                              'R', ''), 'L',
                                                         '')
                            SELECT  @inputmask = REPLACE(@inputmask, ',', '')
   
                            IF @prec = 3--numeric
                                BEGIN

                                    SELECT  @decpos = CHARINDEX('.',
                                                              @inputmask, 1)
                                    IF @decpos = 0
                                        OR @decpos IS NULL 
                                        BEGIN
                                            SELECT  @errmsg = @errstart
                                                    + 'Cannot have Numeric precision unless mask has a decimal.',
                                                    @rcode = 1
                                            GOTO bspexit
                                        END


                                    SELECT  @leftofdecimal = @decpos - 1
                                    SELECT  @rightofdecimal = LEN(@inputmask)
                                            - @leftofdecimal - 1
   	
                                    SELECT  @numerictype = 'numeric('
                                            + CONVERT(VARCHAR(5), @leftofdecimal
                                            + @rightofdecimal) + ','
                                            + CONVERT(VARCHAR(5), @rightofdecimal)
                                            + ')'

                                END --prec=3
                            ELSE 
                                BEGIN
                                    SELECT  @decpos = ISNULL(CHARINDEX('.',
                                                              @inputmask, 1),
                                                             0)
                                    IF @decpos <> 0 
                                        BEGIN
                                            SELECT  @errmsg = @errstart
                                                    + 'Mask may not include a decimal unless the precision is numeric.',
                                                    @rcode = 1
                                            GOTO bspexit
                                        END --decpos<>0
                                END --@prec=3
                        END --@inputtype=1
   
   
                    SELECT  @createstring = ISNULL(@createstring, '') + '['
                            + @columnname + '] '
                            + CONVERT(VARCHAR(50), CASE WHEN @inputtype IN ( 0,
                                                              5 )
                                                        THEN 'varchar('
                                                             + CONVERT(VARCHAR(10), CASE ISNULL(@inputlength,
                                                              30)
                                                              WHEN 0 THEN 1000
                                                              ELSE ISNULL(@inputlength,
                                                              30)
                                                              END) + ')'
                                                        WHEN @inputtype = 1
                                                        THEN ( CASE @prec
                                                              WHEN 0
                                                              THEN 'tinyint'
                                                              WHEN 1
                                                              THEN 'smallint'
                                                              WHEN 2
                                                              THEN 'int'
                                                              WHEN 3
                                                              THEN @numerictype
                                                              WHEN 4
                                                              THEN 'bigint'
                                                              END )
                                                        WHEN @inputtype IN ( 2,
                                                              3 )
                                                        THEN ( 'smalldatetime' )
                                                   END)
                            + ( CASE ISNULL(@keyseq, '')
                                  WHEN '' THEN ' null'
                                  ELSE ' not null'
                                END )
    


                END --systemdatatype
            ELSE 
                BEGIN
                    IF @systemdatatype = 'bYN' 
                        SELECT  @createstring = ISNULL(@createstring, '')
                                + '[' + @columnname + '] ' + @systemdatatype
                                + ' not null CONSTRAINT [DF_' + @tablename
                                + '_' + @columnname + '] DEFAULT (''N'')'
                    ELSE 
                        SELECT  @createstring = ISNULL(@createstring, '')
                                + '[' + @columnname + '] ' + @systemdatatype
                                + CASE ISNULL(@keyseq, '')
                                    WHEN '' THEN ' null'
                                    ELSE ' not null'
                                  END
                END
     
      	--print @createstring
            FETCH NEXT FROM createcursor INTO @columnname, @keyseq, @datatype,
                @inputtype, @inputmask, @inputlength, @prec
        END
     
    CLOSE createcursor
    DEALLOCATE createcursor
     
    SELECT  @usenotestab = UseNotesTab
    FROM    bUDTH
    WHERE   TableName = @tablename
      --If UseNotesTab=1 or 2, add notes.
    IF @usenotestab = 1 or @usenotestab = 2
        SELECT  @createstring = @createstring + ',Notes VARCHAR(MAX) null'
     
      --build the create string
	  -- Begin Change TP - 11/7/2007 - added - ,KeyID bigint IDENTITY(1,1) not null 
    SELECT  @createstring = 'Create table ' + @btablename + '('
            + @createstring
            + ',UniqueAttchID uniqueidentifier ,KeyID bigint IDENTITY(1,1) not null)'
      -- End Change 

      --print @createstring
     
    OPEN keycursor
     
    FETCH NEXT FROM keycursor INTO @columnname
    WHILE @@fetch_status = 0 
        BEGIN
            IF NOT @keystring IS NULL 
                SELECT  @keystring = @keystring + ', '
     
            SELECT  @keystring = ISNULL(@keystring, '') + '[' + @columnname
                    + ']'
     
            FETCH NEXT FROM keycursor INTO @columnname
        END
     
    CLOSE keycursor
    DEALLOCATE keycursor
     
      --Build the index string
    IF NOT @keystring IS NULL 
        SELECT  @keystring = 'Create unique clustered index bi' + @tablename
                + ' on ' + @btablename + '(' + @keystring + ')'
     
      --Actually create the table and index

    BEGIN TRAN
    EXEC(@createstring)
    IF NOT EXISTS ( SELECT  *
                    FROM    sysobjects
                    WHERE   name = @btablename ) 
        BEGIN
     
            SELECT  @rcode = 1,
                    @errmsg = 'Error: Table ' + @btablename + ' not created.'
            ROLLBACK TRAN
            GOTO bspexit
        END
    EXEC(@keystring)
    IF NOT EXISTS ( SELECT  *
                    FROM    sys.indexes
                    WHERE   name = 'bi' + @tablename ) 
        BEGIN
            SELECT  @rcode = 1,
                    @errmsg = 'Error: Index bi' + @tablename + ' not created.'
            ROLLBACK TRAN
            GOTO bspexit
        END
     
    UPDATE  bUDTH
    SET     Created = 'Y'
    WHERE   TableName = @tablename
    
      --Create View for table
    EXEC @rcode = vspVAViewGen @tablename, @btablename, @errmsg OUTPUT
    IF @rcode = 1 
        BEGIN
            SELECT  @errmsg = @errmsg + ' - error creating view'
            GOTO bspexit
        END
   
    COMMIT TRAN
     
      -- Add Security Entries if Needed
    DECLARE createddslcursor CURSOR local fast_forward
    FOR
        SELECT  ColumnName,
                DataType
        FROM    bUDTC
        WHERE   TableName = @tablename
                AND DataType IS NOT NULL
        ORDER BY DDFISeq
     
      --Get columns and info for create string
    OPEN createddslcursor
     
    FETCH NEXT FROM createddslcursor INTO @columnname, @datatype
     
    WHILE @@fetch_status = 0 
        BEGIN
     
            EXEC @rcode = dbo.vspDDSLUserColumn @btablename, @datatype,
                @columnname, @formname, 'Addition', @errmsg OUTPUT
            IF @rcode <> 0 
                BEGIN
                    SELECT  @errmsg = 'Error Adding User Data Column '
                            + @columnname + ' to the Security Links Table. ',
                            @rcode = 1
                END
   
        	--print @createstring
            FETCH NEXT FROM createddslcursor INTO @columnname, @datatype
        END
     
    CLOSE createddslcursor
    DEALLOCATE createddslcursor
		
    DECLARE @AuditTable bYN
		
    SELECT  @AuditTable = AuditTable
    FROM    UDTH
    WHERE   TableName = @tablename
		
    EXEC dbo.vspUDUpdateAuditTriggers @tablename, @AuditTable
		   
    bspexit:
    RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspUDCreateTable] TO [public]
GO
