SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[bspPMVCColumnTitleVal]
/***********************************************************
 * CREATED BY:	GF 03/21/2007 6.x 
 * MODIFIED BY: AMR - 6/27/11 - TK-06411, Fixing performance issue by using an inline table function.
 *
 *
 *
 *
 * USAGE:
 * validates PM Grid View Column Title to make sure unique for 
 * ViewName/GridForm in PMVC. If not error will occur when loading
 * document tracking view.
 *
 * PASS:
 * ViewName		PM Document View
 * Form			PM Document View Grid Form
 * TableView	PM Document View Grid Form Table Name
 * ColumnTitle	PM Document View Grid Form Column Title
 * ColSeq		PM Document View Grid Form Column Sequence
 *
 * RETURNS:
 * ErrMsg if any
 * 
 * OUTPUT PARAMETERS
 *   @msg     Error message if invalid, 
 * RETURN VALUE
 *   0 Success
 *   1 fail
 *****************************************************/
    (
      @viewname VARCHAR(10) = NULL,
      @form VARCHAR(30) = NULL,
      @columntitle VARCHAR(30) = NULL,
      @colseq INT = NULL,
      @msg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON

    DECLARE @rcode INT

    SELECT  @rcode = 0

    IF ISNULL(@viewname, '') = '' 
        BEGIN
            SELECT  @msg = 'Missing Document View',
                    @rcode = 1
            RETURN @rcode
        END
    IF ISNULL(@form, '') = '' 
        BEGIN
            SELECT  @msg = 'Missing Document View Grid Form',
                    @rcode = 1
            RETURN @rcode
        END
    IF ISNULL(@columntitle, '') = '' 
        BEGIN
            SELECT  @msg = 'Missing Document Grid Form Column Title',
                    @rcode = 1
            RETURN @rcode
        END


---- verify that the column title is unique for the grid form
    IF ISNULL(@colseq, 0) = 0 
        BEGIN
            IF EXISTS ( SELECT  ColTitle
                        FROM    PMVC
                        WHERE   ViewName = @viewname
                                AND Form = @form
                                AND ColTitle = @columntitle ) 
                BEGIN
                    SELECT  @msg = 'Column title: ' + ISNULL(@columntitle, '')
                            + ' must be unique for the grid form.',
                            @rcode = 1
                    RETURN @rcode
                END
        END
    ELSE 
        BEGIN
            IF EXISTS ( SELECT  ColTitle
                        FROM    PMVC
                        WHERE   ViewName = @viewname
                                AND Form = @form
                                AND ColTitle = @columntitle
                                AND ColSeq <> @colseq ) 
                BEGIN
                    SELECT  @msg = 'Column title: ' + ISNULL(@columntitle, '')
                            + ' must be unique for the grid form.',
                            @rcode = 1
                    RETURN @rcode
                END
        END

---- check DDFI key field grid column headings
    IF EXISTS ( SELECT  Seq
					-- use inline table function for perf
                FROM    dbo.vfDDFIShared(@form)
                WHERE   GridColHeading = @columntitle ) 
        BEGIN
            SELECT  @msg = 'Column title: ' + ISNULL(@columntitle, '')
                    + ' already exists as a key field grid column heading.',
                    @rcode = 1
            RETURN @rcode
        END

    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMVCColumnTitleVal] TO [public]
GO
