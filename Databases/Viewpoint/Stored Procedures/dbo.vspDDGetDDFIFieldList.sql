SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************
* CREATED:		11/5/07  CC
*			
* Modified: 1/19/09 AL - Changed to use DDFIShared
*			2/4/09  AL - Removed column and view from Desc column
*			AMR - 6/27/11 - TK-06411, Fixing performance issue by using an inline table function.
* USAGE:
*   Returns a sequence number, view name, column name, description, and data type
*   form DDFI for a given form name
*
* CALLED FROM:
*	DDFH & DDFI  
*
* INPUT PARAMETERS:
*    DDFH Form name
*
************************************************************/
CREATE PROCEDURE [dbo].[vspDDGetDDFIFieldList] 
	-- Add the parameters for the stored procedure here
    @formname VARCHAR(250) = ''
AS 
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON ;

        SELECT  Seq,
                ISNULL(CAST(Seq AS VARCHAR(4)) + ' | ', '*')
                + ISNULL(Description + ' | ', '') + ISNULL(Datatype, '') AS [Desc],
                ISNULL(Datatype, '') AS Datatype
        FROM    dbo.vfDDFIShared(@formname)
	END

GO
GRANT EXECUTE ON  [dbo].[vspDDGetDDFIFieldList] TO [public]
GO
