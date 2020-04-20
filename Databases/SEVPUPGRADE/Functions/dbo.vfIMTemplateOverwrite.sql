SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[vfIMTemplateOverwrite]
(
	 @ImportTemplate	varchar(10)
	,@Form				varchar(30)
	,@ColumnName		varchar(50)
	,@RecType			varchar(30)
)
RETURNS bYN

/***********************************************************
* CREATED BY	: CC 02/17/09
* MODIFIED BY	: 
*
* USAGE:
* Used in Template default stored procedure to return the Y/N value of a template whether 
* or not to overwrite the upload value with the viewpoint value
*
* INPUT PARAMETERS
*  @ImportTemplate     Import Template
*  @Form               Import Form
*  @ColumnName         Column Name
*
* OUTPUT PARAMETERS
*  @OverwriteValue         
*
* RETURN VALUE
*   0                  templateid
*   1                  failure
*****************************************************/
AS 
BEGIN

	DECLARE @OverwriteValue bYN
	SET @OverwriteValue = 'N'
	
	IF ISNULL(@RecType,'')<>''
	BEGIN
		SELECT @OverwriteValue = IMTD.OverrideYN 
		FROM IMTD WITH (NOLOCK)
		INNER JOIN DDUD WITH (NOLOCK) ON IMTD.Identifier = DDUD.Identifier 
		WHERE	IMTD.ImportTemplate=@ImportTemplate AND 
				IMTD.DefaultValue = '[Bidtek]' AND 
				DDUD.ColumnName = @ColumnName AND 
				DDUD.Form = @Form AND 
				IMTD.RecordType = @RecType
	END
	
	RETURN @OverwriteValue
END

GO
GRANT EXECUTE ON  [dbo].[vfIMTemplateOverwrite] TO [public]
GO
