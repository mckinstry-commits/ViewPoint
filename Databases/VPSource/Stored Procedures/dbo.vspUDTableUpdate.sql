SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspUDTableUpdate    Script Date: 08/02/2007 09:08:43 ******/
CREATE            PROC [dbo].[vspUDTableUpdate]
   /***********************************************************
    * CREATED BY: TEP 08/02/2007
    * MODIFIED By : 
	*				TP 12/12/07 - When insert into vDDFIc if datatype bYN set Req = 'Y'
    *				CC 1/14/2008 - Set notes seq to 9999 for issue #126700
	*				CC 1/14/2008 - Added AutoSeqType field to vDDFIc insert and update statements issue #126690
	*				CC 01/14/2008 - Added "and i.UseNotes='Y'" to where clause for vDDFTc notes tab insert, issue #126731
	*				RM 06/25/2008 - Issue 128782 - Use a new method of generating Sequences for new columns
	*				RM 09/08/08 - Issue 129556 - Update label if it matches description.
	*				RM 02/23/2010 - Added check to ensure that only the last key is set to AutoSeq
	*				AR 02/08/2011 - 142350 - Fixing missing alias on DataType
	*				AMR - 1/13/2012 - TK-11721 - changing VARCHAR(MAX) back to bNotes
	*				ChrisG - 8/9/12 - TK-16852 | B-10065 - Added UD versioning.
	*				JA - 11/14/12 - TK-14366 Change UseNotes to UseNotesTab
	*				
    *
    * USAGE:
    * Updates and Inserts table data into the vDDFHc and vDDFIc Tables
    *
    * INPUT PARAMETERS
    *   TableName
    *   
    * OUTPUT PARAMETERS
    *   @errmsg        error message if something went wrong
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
    (
      @tablename VARCHAR(20),
      @errmsg VARCHAR(500) OUTPUT
    )
AS 
    SET nocount ON
    BEGIN
        DECLARE @rcode INT
        SELECT  @rcode = 0
        IF @tablename IS NULL 
            BEGIN
                SELECT  @errmsg = 'Missing Table Name',
                        @rcode = 1
                GOTO vspexit
            END
 
 
        BEGIN TRAN 
  	
        IF EXISTS ( SELECT  *
                    FROM    bUDTC c1
                    WHERE   KeySeq IS NOT NULL
                            AND c1.AutoSeqType > 0
                            AND EXISTS ( SELECT *
                                         FROM   bUDTC c2
                                         WHERE  c1.TableName = c2.TableName
                                                AND c2.KeySeq > c1.KeySeq )
                            AND c1.TableName = @tablename ) 
            BEGIN
                SELECT  @errmsg = 'Fields that use Auto Sequencing must be the last key for the form.',
                        @rcode = 1
                GOTO vspexit
            END
	





        DECLARE @udthformname VARCHAR(30),
            @ddfhformname VARCHAR(30)

        SELECT  @udthformname = i.FormName,
                @ddfhformname = h.Form
        FROM    UDTH i WITH ( NOLOCK )
                JOIN vDDFHc h ON i.TableName = h.ViewName
        WHERE   i.TableName = @tablename

        IF ( @udthformname <> @ddfhformname ) 
            BEGIN
    	--Insert Form Into DDFH
			--if UseNotesTab = 1
                INSERT  vDDFHc
                        ( Form, FormType, NotesTab,
                          Mod, ShowOnMenu, ViewName,
                          Title, SecurityForm, DetailFormSecurity,
                          AllowAttachments
                        )
                        SELECT  i.FormName, 1, 2,
                                'UD', 'Y', i.TableName,
                                i.Description, i.FormName, 'N',
                                'Y'
                        FROM    UDTH i
                        WHERE   i.TableName = @tablename AND i.UseNotesTab = 1
						
			--if UseNotesTab = 2
                INSERT  vDDFHc
                        ( Form, FormType, FormattedNotesTab,
                          Mod, ShowOnMenu, ViewName,
                          Title, SecurityForm, DetailFormSecurity,
                          AllowAttachments
                        )
                        SELECT  i.FormName, 1, 200,
                                'UD', 'Y', i.TableName,
                                i.Description, i.FormName, 'N',
                                'Y'
                        FROM    UDTH i
                        WHERE   i.TableName = @tablename AND i.UseNotesTab = 2
    
		--Insert Info Tab for Form
                INSERT  vDDFTc
                        ( Form, Tab, Title )
                        SELECT  i.FormName, 0, 'Grid'
                        FROM    UDTH i
                        WHERE   i.TableName = @tablename

    	--Insert Info Tab for Form
                INSERT  vDDFTc
                        ( Form, Tab, Title )
                        SELECT  i.FormName,
                                1,
                                'Info'
                        FROM    UDTH i
                        WHERE   i.TableName = @tablename
    	
		--Insert Standard or Formatted Notes tab for form
				INSERT  vDDFTc
						( Form, Tab, Title,
						  LoadSeq, Type				  
						)
						SELECT  i.FormName,
								CASE WHEN i.UseNotesTab = 1 THEN 2 --standard note tab number
								ELSE 200 --formatted notes tab number
								END,
								'Notes',
								2,
								CASE WHEN i.UseNotesTab = 1 THEN 0 --standard note tab type
								ELSE 2 --formatted notes tab type
								END
						FROM    UDTH i
						WHERE   i.TableName = @tablename
								AND (i.UseNotesTab = 1 OR i.UseNotesTab = 2)		
		
                UPDATE  vDDFIc
                SET     Form = @udthformname
                FROM    vDDFIc i
                WHERE   i.ViewName = @tablename
    	
    	--delete old form from DDFH
                DELETE  vDDFHc
                FROM    vDDFHc h
                WHERE   h.Form = @ddfhformname
    	
                DELETE  vDDFTc
                FROM    vDDFTc t
                WHERE   t.Form = @ddfhformname
    
            END

        DECLARE @udthdescription VARCHAR(30),
            @ddfhdescription VARCHAR(30)

        SELECT  @udthdescription = i.Description,
                @ddfhdescription = h.Title
        FROM    UDTH i WITH ( NOLOCK )
                JOIN vDDFHc h ON i.TableName = h.ViewName
        WHERE   i.TableName = @tablename

        IF ( @udthdescription <> @ddfhdescription ) 
            BEGIN
    	--Update vDDFHc
                UPDATE  vDDFHc
                SET     Title = @udthdescription
                FROM    UDTH i WITH ( NOLOCK )
                        JOIN vDDFHc h ON i.TableName = h.ViewName
                WHERE   i.TableName = @tablename
            END
    
        DECLARE @udthusenotestab VARCHAR(1),
            @ddfhusenotes VARCHAR(1)

        SELECT  @udthusenotestab = i.UseNotesTab,
                @ddfhusenotes = CASE WHEN h.Seq IS NULL THEN 'N'
                                     ELSE 'Y'
                                END
        FROM    UDTH i WITH ( NOLOCK )
                LEFT JOIN vDDFIc h ON i.TableName = h.ViewName
                                      AND h.Seq = 9999
        WHERE   i.TableName = @tablename

        IF ( ((@udthusenotestab = 1 OR @udthusenotestab = 2) AND @ddfhusenotes = 'N') 
			OR (@udthusenotestab = 0 AND @ddfhusenotes = 'Y') ) --if UD form has tab and DDFH doesn't or visa versa
            BEGIN
                IF EXISTS ( SELECT  1
                            FROM    UDTH i
                            WHERE   (i.UseNotesTab = 1 OR i.UseNotesTab = 2)
                                    AND i.TableName = @tablename ) 
                    BEGIN
    			/*If UseNotesTab=1 or 2, then create notes column*/
                        INSERT  INTO vDDFIc
                                ( Form, Seq, ViewName,
                                  ColumnName, Description, Datatype,
                                  InputType, InputMask, InputLength,
                                  Prec, FieldType, ControlType,
                                  Req, InputSkip, DefaultType,
                                  Tab, ShowForm, ShowGrid
                                )
                                SELECT  i.FormName, 9999, i.TableName,
                                        'Notes', 'User Notes', CASE WHEN i.UseNotesTab = 1 THEN 'bNotes' ELSE 'bFormattedNotes' END,
                                        NULL, NULL, NULL,
                                        NULL, 1, 8,
                                        'N', 'N', 0,
                                        CASE WHEN i.UseNotesTab = 1 THEN 2 ELSE 200 END, 'Y', 'Y'
                                FROM    UDTH i
                                WHERE   (i.UseNotesTab = 1 OR i.UseNotesTab = 2)
                                        AND i.TableName = @tablename

                        IF NOT EXISTS ( SELECT TOP 1
                                                1
                                        FROM    vDDFTc t
                                                JOIN UDTH i ON i.FormName = t.Form
                                        WHERE   i.TableName = @tablename
                                                AND t.Tab = 2 ) 
                            BEGIN
					--Insert Notes tab for form
                                INSERT  vDDFTc
                                        ( Form, Tab, Title,
                                          LoadSeq, Type
                                        )
                                        SELECT  i.FormName, CASE WHEN i.UseNotesTab = 1 THEN 2 ELSE 200 END, 'Notes',
                                                2, CASE WHEN i.UseNotesTab = 1 THEN 0 ELSE 2 END
                                        FROM    UDTH i
                                        WHERE   i.TableName = @tablename
                                                AND (i.UseNotesTab = 1 OR i.UseNotesTab = 2)
                            END
                    END
                ELSE 
                    BEGIN
    			/*Delete Notes Column if box gets unchecked.  
    			This will not actually drop the column from the table
    			it will only remove it from vDDFIc, so no data will be lost*/
                        DELETE  vDDFIc
                        FROM    vDDFIc i
                        WHERE   i.Seq = 9999
                                AND i.ViewName = @tablename

                        DELETE  vDDFTc
                        FROM    vDDFTc t
                        WHERE   t.Form = @ddfhformname
                                AND t.Tab = 2 or t.Tab = 200	
                    END
            END 
			
-- Update DDFH entry for NotesTab changes
		UPDATE vDDFHc 
		SET NotesTab = CASE @udthusenotestab
						WHEN 0 THEN NULL
						WHEN 1 THEN 2
						WHEN 2 THEN NULL
						END,
			FormattedNotesTab = CASE @udthusenotestab
								 WHEN 0 THEN NULL
								 WHEN 1 THEN NULL
								 WHEN 2 THEN 200
								 END
		WHERE Form = @ddfhformname 
		
-- Update DDFI entry for NotesTab changes
		UPDATE vDDFIc
		SET Tab = CASE @udthusenotestab
						WHEN 0 THEN NULL
						WHEN 1 THEN 2
						WHEN 2 THEN 200
						END
		WHERE Form = @ddfhformname AND Seq = 9999

--Update DDFT entry for NotesTab changes
		UPDATE vDDFTc
		SET Tab = CASE @udthusenotestab
						WHEN 0 THEN NULL
						WHEN 1 THEN 2
						WHEN 2 THEN 200
						END
		WHERE Form = @ddfhformname AND Title = 'Notes'
			
--Update Rows that are already there
        UPDATE  vDDFIc
        SET     Form = h.FormName,
                Seq = i.DDFISeq,
                ViewName = i.TableName,
                ColumnName = i.ColumnName,
                Description = i.Description,
                Datatype = i.DataType,
                InputType = i.InputType,
                InputMask = i.InputMask,
                InputLength = i.InputLength,
                Prec = i.Prec,
                FieldType = CASE WHEN i.KeySeq IS NULL THEN 4
                                 ELSE 2
                            END,
                ControlType = i.ControlType,
                ComboType = i.ComboType,
                AutoSeqType = i.AutoSeqType,
                Label = CASE WHEN d.Label = d.Description
                             THEN ISNULL(i.Description, i.ColumnName)
                             ELSE d.Label
                        END
        FROM    UDTC i
                JOIN bUDTH h ON i.TableName = h.TableName
                JOIN vDDFIc d ON h.FormName = d.Form
                                 AND i.DDFISeq = d.Seq 
								 
--Insert Rows that aren't already there
        INSERT  INTO vDDFIc
                ( Form,
                  Seq,
                  ViewName,
                  ColumnName,
                  Description,
                  Datatype,
                  InputType,
                  InputMask,
                  InputLength,
                  Prec,
                  FieldType,
                  ControlType,
                  Req,
                  InputSkip,
                  DefaultType,
                  Tab,
                  ShowForm,
                  ShowGrid,
                  Label,
                  ComboType,
                  AutoSeqType
                )
                SELECT  h.FormName,
                        ( SELECT    ( COUNT(*) * 5 )
                                    + ( SELECT  ISNULL(MAX(Seq), 4995)
                                        FROM    DDFIc
                                        WHERE   DDFIc.ViewName = i.TableName
                                                AND DDFIc.Seq <> 9999
                                      )
                          FROM      UDTC u
                          WHERE     u.TableName = i.TableName
                                    AND u.KeyID <= i.KeyID
                        ),
                        i.TableName,
                        i.ColumnName,
                        i.Description,
                        i.DataType,
                        i.InputType,
                        i.InputMask,
                        i.InputLength,
                        i.Prec,
                        CASE WHEN i.KeySeq IS NULL THEN 4
                             ELSE 2
                        END,
                        i.ControlType,
                        CASE WHEN i.DataType = 'bYN' THEN 'Y'
                             WHEN i.KeySeq IS NULL THEN 'N'
                             ELSE 'Y'
                        END,
                        'N',
                        0,
                        CASE WHEN i.KeySeq IS NULL THEN 1
                             ELSE 0
                        END,
                        'Y',
                        'Y',
                        ISNULL(i.Description, i.ColumnName),
                        i.ComboType,
                        i.AutoSeqType
                FROM    UDTC i
                        LEFT JOIN bUDTH h ON h.TableName = i.TableName
                        LEFT JOIN vDDFIc c ON c.ViewName = i.TableName
                                              AND c.ColumnName = i.ColumnName
                WHERE   i.TableName = @tablename
                        AND c.ColumnName IS NULL 

        UPDATE  bUDTC
        SET     DDFISeq = d.Seq
        FROM    bUDTC c
                JOIN bUDTH h ON c.TableName = h.TableName
                JOIN vDDFIc d ON h.FormName = d.Form
                                 AND c.ColumnName = d.ColumnName
        WHERE   c.TableName = @tablename

--Delete rows that aren't in UDTC
        DELETE  vDDFIc
        FROM    vDDFIc d
        WHERE   d.ViewName = @tablename
                AND NOT d.ColumnName IN ( SELECT    ColumnName
                                          FROM      UDTC
                                          WHERE     TableName = @tablename )
                AND d.Seq <> 9999

		-- Update the UD Table version
		EXEC vspUDVersionUpdate @tablename
		
        vspexit:
        IF @rcode = 0 
            COMMIT TRAN
        ELSE 
            ROLLBACK TRAN

        RETURN @rcode                                                   
    END

GO
GRANT EXECUTE ON  [dbo].[vspUDTableUpdate] TO [public]
GO
