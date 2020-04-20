SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDInsertColorScheme] 
/******************************************************************************
* Created: JRK 05/24/06
* Last Modified: Chris Crewdson 2010-12-17
*
* Created JRK 5/25/06 
*
* Used to insert a color scheme.  Will be used initially to insert 
*
* Inputs:
*	Color theme ID
*	Color theme description
*	Color parameters.  All are nullable.
*
* Output:
*
*******************************************************************************
* Modified:
* 2010-12-17 - Chris Crewdson - Added LabelBackgroundColor and LabelTextColor columns - Issue #141940
* 2011-01-11 - Chris Crewdson - Added LabelBorderStyle column
*******************************************************************************/
	(
	@themeid int = null, @desc varchar(128) = null, 
	@smartcursorcolor int = null, @reqfieldcolor int = null,
	@accentcolor1 int = null, @accentcolor2 int = null, @usecolorgrad bYN = null,
	@formcolor1 int = null, @formcolor2 int = null, @graddirection tinyint = null,
	@labelbackgroundcolor int = null, @labeltextcolor int = null,
	@labelborderstyle tinyint = null
	)

AS
	SET NOCOUNT ON;

	INSERT INTO DDCS
     (ColorSchemeID, Description, SmartCursorColor, ReqFieldColor, 
			   AccentColor1, AccentColor2, UseColorGrad, FormColor1, FormColor2, 
               GradDirection, LabelBackgroundColor, LabelTextColor,
               LabelBorderStyle)
	VALUES (@themeid, @desc, @smartcursorcolor, @reqfieldcolor,
			@accentcolor1, @accentcolor2, @usecolorgrad, @formcolor1, @formcolor2, 
			@graddirection, @labelbackgroundcolor, @labeltextcolor,
			@labelborderstyle);



GO
GRANT EXECUTE ON  [dbo].[vspDDInsertColorScheme] TO [public]
GO
