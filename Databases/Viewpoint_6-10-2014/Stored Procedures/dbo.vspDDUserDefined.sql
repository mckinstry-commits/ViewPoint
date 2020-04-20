SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspDDUserDefined    Script Date: 8/28/99 9:34:23 AM ******/
CREATE   PROCEDURE [dbo].[vspDDUserDefined]
  /********************************
  * Created DANF 06/02/2005
  * Modified: AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function. 	
  *
  * Retrieves all user defined inputs for a select VB form.
  * Pass - Form name (stored in Tag property)
  * Returns - Column Name
  *
  *********************************/ 
  ( @Form VARCHAR(30) )
AS 
    SET nocount ON
    SELECT  ColumnName = ISNULL(ColumnName, '')
    FROM    dbo.vfDDFIShared(@Form)
    WHERE   Form = @Form
            AND FieldType = 4
    ORDER BY ColumnName

GO
GRANT EXECUTE ON  [dbo].[vspDDUserDefined] TO [public]
GO
