SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspUDTableInsert    Script Date: 07/31/2007 17:16:04 ******/
CREATE            PROC [dbo].[vspUDTableInsert]
   /***********************************************************
    * CREATED BY: TEP 07/31/2007
    * MODIFIED By : RM 08/28/07 - Use vDDMFc instead of UDTM
	*				TP 12/12/07 - When insert into vDDFIc if datatype bYN set Req = 'Y' 
    *				CC 01/14/2008 - Set notes seq to 9999 issue #126700
	*				CC 01/14/2008 - Added AutoSeqType insert for issue #126690
	*				CC 01/14/2008 - Added "and i.UseNotes='Y'" to where clause for vDDFTc notes tab insert, issue #126731
	*				George Clingerman 04-28-2008 - #124420 Modified insert into vDDFIc to default ActiveLookup to 'Y' and 
	*											   LookupLoadSeq to 0
	*				RM 02/23/2010 - Added check to ensure that only the last key is set to AutoSeq
	*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
	*				AMR - 1/13/2012 - TK-11721 - changing VARCHAR(MAX) back to bNotes
	*				ChrisG - 8/9/12 - TK-16852 | B-10065 - Added UD versioning.
	*				JA - 11/14/12 - TK-14366 Change UseNotes to UseNotesTab
	*				
    * USAGE:
    * Inserts UD Table data into the vDDFHc and vDDFIc Tables
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
	
  
  



--Insert Form Into DDFH
        INSERT  vDDFHc
                ( Form,
                  FormType,
                  NotesTab,
                  FormattedNotesTab,
                  Mod,
                  ShowOnMenu,
                  ViewName,
                  Title,
                  AssemblyName,
                  FormClassName,
                  SecurityForm,
                  DetailFormSecurity,
                  CoColumn,
                  AllowAttachments
                )
                SELECT  i.FormName,
                        1,
                        case when i.UseNotesTab = 1 then 2 else null end,
						case when i.UseNotesTab = 2 then 200 else null end,
                        'UD',
                        'Y',
                        i.TableName,
                        i.Description,
                        'UD',
                        'frmUDUserGeneratedForm',
                        i.FormName,
                        'N',
                        CASE i.CompanyBasedYN
                          WHEN 'Y' THEN 'Co'
                          ELSE NULL
                        END,
                        'Y'
                FROM    UDTH i
                WHERE   i.TableName = @tablename

--Insert Info Tab for Form
        INSERT  vDDFTc
                ( Form,
                  Tab,
                  Title,
                  LoadSeq
                )
                SELECT  i.FormName,
                        0,
                        'Grid',
                        0
                FROM    UDTH i
                WHERE   i.TableName = @tablename

--Insert Info Tab for Form
        INSERT  vDDFTc
                ( Form,
                  Tab,
                  Title,
                  LoadSeq
                )
                SELECT  i.FormName,
                        1,
                        'Info',
                        1
                FROM    UDTH i
                WHERE   i.TableName = @tablename

--Insert Standard or Formatted Notes tab for form
        INSERT  vDDFTc
                ( Form,
                  Tab,
                  Title,
                  LoadSeq,
		Type
                )
                SELECT  i.FormName,
                        CASE WHEN i.UseNotesTab = 1 THEN 2 ELSE 200 END,
                        'Notes',
                        2,
			CASE WHEN i.UseNotesTab = 1 THEN 0 ELSE 2 END
                FROM    UDTH i
                WHERE   i.TableName = @tablename
                        AND (i.UseNotesTab = 1 OR i.UseNotesTab = 2)


/*If UseNotesTab=1 or 2, then create standard or formatted notes column*/
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
                  ActiveLookup,
                  LookupLoadSeq
                )
                SELECT  i.FormName,
                        9999, --99,
                        i.TableName,
                        'Notes',
                        'User Notes',
						CASE WHEN i.UseNotesTab = 1 THEN 'bNotes' ELSE 'bFormattedNotes' END,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        1/*Notes*/,
                        8/*Notes*/,
                        'N'/*Req*/,
                        'N',
                        0,
                        CASE WHEN i.UseNotesTab = 1 THEN 2 ELSE 200 END, /*Notes Tab*/
                        'Y',
                        'Y',
                        'Y',
                        0
                FROM    UDTH i
                WHERE   (i.UseNotesTab = 1 OR i.UseNotesTab = 2)
                        AND i.TableName = @tablename



--insert UDTM table for the UD module
--declare @mod varchar(3)
--
--select @mod = min(Mod) from vDDMO
--while @mod is not null
--begin
--    insert bUDTM(TableName, Mod, Active)
--    select i.TableName, @mod, 
--	case when @mod = 'UD' then 'Y' else 'N' end 
--	from UDTH i 
--	where i.TableName = @tablename
--    
--    select @mod = min(Mod) from vDDMO where Mod > @mod
--end

--Associate this form with UD.
        INSERT  vDDMFc
                ( Mod,
                  Form,
                  Active
                )
                SELECT  'UD',
                        i.FormName,
                        'Y'
                FROM    UDTH i
                WHERE   i.TableName = @tablename


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
                        ( SELECT    ( COUNT(*) * 5 ) + 4995
                          FROM      UDTC u
                          WHERE     u.TableName = i.TableName
                                    AND u.KeyID <= i.KeyID
                        ),
                        i.TableName,
                        ColumnName,
                        i.Description,
                        DataType,
                        InputType,
                        InputMask,
                        InputLength,
                        Prec,
                        CASE WHEN i.KeySeq IS NULL THEN 4
                             ELSE 2
                        END,
                        i.ControlType,
                        CASE WHEN DataType = 'bYN' THEN 'Y'
                             WHEN i.KeySeq IS NULL THEN 'N'
                             ELSE 'Y'
                        END,
                        'N',
                        0,
                        CASE WHEN i.KeySeq IS NULL THEN 1
                             ELSE NULL
                        END,
                        'Y',
                        'Y',
                        ISNULL(i.Description, ColumnName),
                        i.ComboType,
                        i.AutoSeqType
                FROM    UDTC i
                        JOIN bUDTH h ON h.TableName = i.TableName
                WHERE   i.TableName = @tablename

        UPDATE  bUDTC
        SET     DDFISeq = d.Seq
        FROM    bUDTC c
                JOIN bUDTH h ON c.TableName = h.TableName
                JOIN vDDFIc d ON h.FormName = d.Form
                                 AND c.ColumnName = d.ColumnName
        WHERE   c.TableName = @tablename
  
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
GRANT EXECUTE ON  [dbo].[vspUDTableInsert] TO [public]
GO
