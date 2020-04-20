SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vsp_helptext]
@objname nvarchar(776)
,@columnname sysname = NULL
as

set nocount on

declare @dbname sysname
,@BlankSpaceAdded   int
,@BasePos       int
,@CurrentPos    int
,@TextLength    int
,@LineId        int
,@AddOnLen      int
,@LFCR          int --lengths of line feed carriage return
,@DefinedLength int

/* NOTE: Length of @SyscomText is 4000 to replace the length of
** text column in syscomments.
** lengths on @Line, #CommentText Text column and
** value for @DefinedLength are all 255. These need to all have
** the same values. 255 was selected in order for the max length
** display using down level clients
*/
,@SyscomText	nvarchar(4000)
,@Line          nvarchar(255)

Select @DefinedLength = 255
SELECT @BlankSpaceAdded = 0 /*Keeps track of blank spaces at end of lines. Note Len function ignores
                             trailing blank spaces*/
CREATE TABLE #CommentText
(LineId	int
 ,Text  nvarchar(255) collate database_default)

/*
**  Make sure the @objname is local to the current database.
*/
select @dbname = parsename(@objname,3)

if @dbname is not null and @dbname <> db_name()
        begin
                raiserror(15250,-1,-1)
                return (1)
        end

/*
**  See if @objname exists.
*/
if (object_id(@objname) is null)
        begin
		select @dbname = db_name()
		raiserror(15009,-1,-1,@objname,@dbname)
                return (1)
        end

-- If second parameter was given.
if ( @columnname is not null)
    begin
        -- Check if it is a table
        if (select count(*) from sysobjects where id = object_id(@objname) and xtype in ('S ','U ','TF'))=0
            begin
                raiserror(15218,-1,-1,@objname)
                return(1)
            end
        -- check if it is a correct column name
        if ((select 'count'=count(*) from syscolumns where name = @columnname and id = object_id(@objname) and number = 0) =0)
            begin
                raiserror(15645,-1,-1,@columnname)
                return(1)
            end
    if ((select iscomputed from syscolumns where name = @columnname and id = object_id(@objname) and number = 0) = 0)
		begin
			raiserror(15646,-1,-1,@columnname)
			return(1)
		end

        DECLARE ms_crs_syscom  CURSOR LOCAL
        FOR SELECT text FROM syscomments WHERE id = object_id(@objname) and encrypted = 0 and number =
                        (select colid from syscolumns where name = @columnname and id = object_id(@objname) and number = 0)
                        order by number,colid
        FOR READ ONLY

    end
else
    begin
        /*
        **  Find out how many lines of text are coming back,
        **  and return if there are none.
        */
        if (select count(*) from syscomments c, sysobjects o where o.xtype not in ('S', 'U')
            and o.id = c.id and o.id = object_id(@objname)) = 0
                begin
                        raiserror(15197,-1,-1,@objname)
                        return (1)
                end

        if (select count(*) from syscomments where id = object_id(@objname)
            and encrypted = 0) = 0
                begin
                        raiserror(15471,-1,-1)
                        return (0)
                end

        DECLARE ms_crs_syscom  CURSOR LOCAL
        FOR SELECT text FROM syscomments WHERE id = OBJECT_ID(@objname) and encrypted = 0
                ORDER BY number, colid
        FOR READ ONLY
    end

/*
**  Else get the text.
*/
SELECT @LFCR = 2
SELECT @LineId = 1


OPEN ms_crs_syscom

FETCH NEXT FROM ms_crs_syscom into @SyscomText

WHILE @@fetch_status >= 0
BEGIN

    SELECT  @BasePos    = 1
    SELECT  @CurrentPos = 1
    SELECT  @TextLength = LEN(@SyscomText)

    WHILE @CurrentPos  != 0
    BEGIN
        --Looking for end of line followed by carriage return
        SELECT @CurrentPos =   CHARINDEX(char(13)+char(10), @SyscomText, @BasePos)

        --If carriage return found
        IF @CurrentPos != 0
        BEGIN
            /*If new value for @Lines length will be > then the
            **set length then insert current contents of @line
            **and proceed.
            */
            While (isnull(LEN(@Line),0) + @BlankSpaceAdded + @CurrentPos-@BasePos + @LFCR) > @DefinedLength
            BEGIN
                SELECT @AddOnLen = @DefinedLength-(isnull(LEN(@Line),0) + @BlankSpaceAdded)
                INSERT #CommentText VALUES
                ( @LineId,
                  isnull(@Line, N'') + isnull(SUBSTRING(@SyscomText, @BasePos, @AddOnLen), N''))
                SELECT @Line = NULL, @LineId = @LineId + 1,
                       @BasePos = @BasePos + @AddOnLen, @BlankSpaceAdded = 0
            END
            SELECT @Line    = isnull(@Line, N'') + isnull(SUBSTRING(@SyscomText, @BasePos, @CurrentPos-@BasePos + @LFCR), N'')
            SELECT @BasePos = @CurrentPos+2
            INSERT #CommentText VALUES( @LineId, @Line )
            SELECT @LineId = @LineId + 1
            SELECT @Line = NULL
        END
        ELSE
        --else carriage return not found
        BEGIN
            IF @BasePos <= @TextLength
            BEGIN
                /*If new value for @Lines length will be > then the
                **defined length
                */
                While (isnull(LEN(@Line),0) + @BlankSpaceAdded + @TextLength-@BasePos+1 ) > @DefinedLength
                BEGIN
                    SELECT @AddOnLen = @DefinedLength - (isnull(LEN(@Line),0) + @BlankSpaceAdded)
                    INSERT #CommentText VALUES
                    ( @LineId,
                      isnull(@Line, N'') + isnull(SUBSTRING(@SyscomText, @BasePos, @AddOnLen), N''))
                    SELECT @Line = NULL, @LineId = @LineId + 1,
                        @BasePos = @BasePos + @AddOnLen, @BlankSpaceAdded = 0
                END
                SELECT @Line = isnull(@Line, N'') + isnull(SUBSTRING(@SyscomText, @BasePos, @TextLength-@BasePos+1 ), N'')
                if LEN(@Line) < @DefinedLength and charindex(' ', @SyscomText, @TextLength+1 ) > 0
                BEGIN
                    SELECT @Line = @Line + ' ', @BlankSpaceAdded = 1
                END
            END
        END
    END

	FETCH NEXT FROM ms_crs_syscom into @SyscomText
END

IF @Line is NOT NULL
    INSERT #CommentText VALUES( @LineId, @Line )

SELECT  top 1 1                    as Tag, 
         NULL                 as Parent,
         @objname 				as [mssql:object!1!name],
         	NULL               as [mssql:source!2!text]
FROM #CommentText

UNION ALL
SELECT 		2                    as Tag, 
         	1                 as Parent,
         @objname 				as [mssql:object!1!name],
         	[Text]               as [mssql:source!2!text]
from #CommentText /*order by LineId*/ FOR XML explicit

CLOSE  ms_crs_syscom
DEALLOCATE 	ms_crs_syscom

DROP TABLE 	#CommentText

return (0) -- sp_helptext






GO
GRANT EXECUTE ON  [dbo].[vsp_helptext] TO [public]
GO
