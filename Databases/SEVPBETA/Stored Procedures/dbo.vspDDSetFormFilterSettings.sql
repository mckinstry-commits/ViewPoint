SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDSetFormFilterSettings]
/********************************    
* Created: CC 2010-01-07   
* Modified: 
*    
* Input:    
* @FormName - the form to retrieve filter settings for
* @UserName - the user to retrieve filter settings for
* @Company	- the company to retrieve filter settings for, currently unused
*    
* Output: returns the field sequences used in filtering, and their value.
*    
* Return code: none
*    
*********************************/
	@FormName	VARCHAR(30),
	@UserName	VARCHAR(128),
	@Company	bCompany,
	@FieldSeq	SMALLINT,
	@Value		VARCHAR(MAX)
AS
BEGIN
	IF EXISTS (	SELECT 1
				FROM DDFormFilters
				WHERE	FormName = @FormName
						AND VPUserName = @UserName
						AND FieldSeq = @FieldSeq
			  )
		UPDATE DDFormFilters
		SET FilterValue = @Value
		WHERE	FormName = @FormName
		AND VPUserName = @UserName
		AND FieldSeq = @FieldSeq;
		
	ELSE
	
		INSERT INTO DDFormFilters ( FormName, VPUserName, Company, FieldSeq, FilterValue)
								  VALUES  ( @FormName, @UserName, @Company, @FieldSeq, @Value);

	IF ISNULL(@Value, '') = ''
		DELETE DDFormFilters		
		WHERE	FormName = @FormName
		AND VPUserName = @UserName
		AND FieldSeq = @FieldSeq;
		
END
GO
GRANT EXECUTE ON  [dbo].[vspDDSetFormFilterSettings] TO [public]
GO
