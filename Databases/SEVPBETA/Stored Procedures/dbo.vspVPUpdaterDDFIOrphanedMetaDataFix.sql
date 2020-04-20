SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* CREATED:	AR 4/20/2010    
* MODIFIED:	AR 12/2/2010 - 142268 null columns fail to be removed from vDDFIc 
*
* Purpose: Checks customer meta data table vDDFI versus our tables 
		   and removes bad records based on the key
			
* returns 1 and error msg if failed
*
-- test harness
	BEGIN TRAN
	EXEC dbo.vspVPUpdaterDDFIOrphanedMetaDataFix
	SELECT * FROM vDDFIc_vOld
	ROLLBACK TRAN
*************************************************************************/
CREATE PROCEDURE [dbo].[vspVPUpdaterDDFIOrphanedMetaDataFix]
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
    SET NOCOUNT ON ;

    DECLARE @dtNow datetime
    SET @dtNow = GETDATE()
	
    BEGIN TRY
        BEGIN TRAN
		-- do we have a logging table, if no, make one
        IF NOT EXISTS ( SELECT  1
                        FROM    sys.tables
                        WHERE   [name] = 'vDDFIc_vOld' ) 
            BEGIN
                SELECT  *,
                        @dtNow AS DelDate
                INTO    dbo.vDDFIc_vOld
                FROM    dbo.vDDFIc
                WHERE   1 = 0			
            END			
		-- log the new difference	
        INSERT  INTO [dbo].[vDDFIc_vOld]
                ( [Form],
                  [Seq],
                  [ViewName],
                  [ColumnName],
                  [Description],
                  [Datatype],
                  [InputType],
                  [InputMask],
                  [InputLength],
                  [Prec],
                  [ActiveLookup],
                  [LookupParams],
                  [LookupLoadSeq],
                  [SetupForm],
                  [SetupParams],
                  [StatusText],
                  [Tab],
                  [TabIndex],
                  [Req],
                  [ValProc],
                  [ValParams],
                  [ValLevel],
                  [UpdateGroup],
                  [ControlType],
                  [ControlPosition],
                  [FieldType],
                  [DefaultType],
                  [DefaultValue],
                  [InputSkip],
                  [Label],
                  [ShowGrid],
                  [ShowForm],
                  [GridCol],
                  [AutoSeqType],
                  [MinValue],
                  [MaxValue],
                  [ValExpression],
                  [ValExpError],
                  [ComboType],
                  [GridColHeading],
                  [HeaderLinkSeq],
                  [CustomControlSize],
                  [Computed],
                  [ShowDesc],
                  [ColWidth],
                  [DescriptionColWidth],
                  [IsFormFilter],
                  [DelDate]
                )
                SELECT fic.[Form],
                       fic.[Seq],
                       fic.[ViewName],
                       fic.[ColumnName],
                       fic.[Description],
                       fic.[Datatype],
                       fic.[InputType],
                       fic.[InputMask],
                       fic.[InputLength],
                       fic.[Prec],
                       fic.[ActiveLookup],
                       fic.[LookupParams],
                       fic.[LookupLoadSeq],
                       fic.[SetupForm],
                       fic.[SetupParams],
                       fic.[StatusText],
                       fic.[Tab],
                       fic.[TabIndex],
                       fic.[Req],
                       fic.[ValProc],
                       fic.[ValParams],
                       fic.[ValLevel],
                       fic.[UpdateGroup],
                       fic.[ControlType],
                       fic.[ControlPosition],
                       fic.[FieldType],
                       fic.[DefaultType],
                       fic.[DefaultValue],
                       fic.[InputSkip],
                       fic.[Label],
                       fic.[ShowGrid],
                       fic.[ShowForm],
                       fic.[GridCol],
                       fic.[AutoSeqType],
                       fic.[MinValue],
                       fic.[MaxValue],
                       fic.[ValExpression],
                       fic.[ValExpError],
                       fic.[ComboType],
                       fic.[GridColHeading],
                       fic.[HeaderLinkSeq],
                       fic.[CustomControlSize],
                       fic.[Computed],
                       fic.[ShowDesc],
                       fic.[ColWidth],
                       fic.[DescriptionColWidth],
                       fic.[IsFormFilter],
                        @dtNow
                FROM    dbo.vDDFIc AS fic
                        LEFT JOIN dbo.vDDFI AS fi ON fi.Form = fic.Form
                                                     AND fi.Seq = fic.Seq
                WHERE   fi.Seq IS NULL
                        AND NOT ( fic.Form LIKE 'ud%'
                              OR ISNULL(fic.ColumnName,'') LIKE 'ud%'
                              OR ISNULL(fic.ViewName,'') LIKE 'ud%'
                            )			
		-- delete records, not going to worry about checking if we even have to delete,
		-- not enough overhead
        DELETE  fic
        FROM    dbo.vDDFIc AS fic
                LEFT JOIN dbo.vDDFI AS fi ON fi.Form = fic.Form
                                             AND fi.Seq = fic.Seq
        WHERE   fi.Seq IS NULL
				-- the isNULL is bad but to make the code more readable I am using it
				-- since this is only run during install
                AND NOT ( fic.Form LIKE 'ud%'
                              OR ISNULL(fic.ColumnName,'') LIKE 'ud%'
                              OR ISNULL(fic.ViewName,'') LIKE 'ud%'
                            )								
		-- commit	
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg varchar(max)
        SET @ErrMsg = ERROR_MESSAGE()
			
        IF @@TRANCOUNT > 0 
            BEGIN
                ROLLBACK TRAN
            END
        RAISERROR (@ErrMsg,15,1)
        
        RETURN (1)
    END CATCH
    
    RETURN (0)
END

GO
GRANT EXECUTE ON  [dbo].[vspVPUpdaterDDFIOrphanedMetaDataFix] TO [public]
GO
