SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDUCInsert] 
/*******************************************************************************
* Created: JRK 05/24/06
* Last Modified: 2010-12-17 Chris Crewdson
*
* Used to manage users' colors-by-company.
*
* Inputs:
*	The user's username.
*	The company.
*	Color parameters.  All are nullable.
*
* Output:
*	resultset of users' colors, by company.
*
*******************************************************************************
* Modified:
* 2010-12-17 - Chris Crewdson - Added LabelBackgroundColor and LabelTextColor columns - Issue #141940
* 2011-01-11 - Chris Crewdson - Added LabelBorderStyle column
*******************************************************************************/
	(
	@userid bVPUserName = null, @co bCompany = null, 
	@colorschemeid int = null, @smartcursorcolor int = null, @reqfieldcolor int = null,
	@accentcolor1 int = null, @accentcolor2 int = null, @usecolorgrad bYN = null,
	@formcolor1 int = null, @formcolor2 int = null, @graddirection tinyint = null,
	@labelbackgroundcolor int = null, @labeltextcolor int = null,
	@labelborderstyle tinyint = null
	)

AS
	SET NOCOUNT ON;
	
	INSERT INTO DDUC
     (VPUserName, Company, ColorSchemeID, SmartCursorColor, ReqFieldColor, 
			   AccentColor1, AccentColor2, UseColorGrad, FormColor1, FormColor2, 
               GradDirection, LabelBackgroundColor, LabelTextColor,
               LabelBorderStyle)
	VALUES (@userid, @co, @colorschemeid, @smartcursorcolor, @reqfieldcolor,
			@accentcolor1, @accentcolor2, @usecolorgrad, @formcolor1, @formcolor2, 
			@graddirection, @labelbackgroundcolor, @labeltextcolor,
			@labelborderstyle);

	

GO
GRANT EXECUTE ON  [dbo].[vspDDUCInsert] TO [public]
GO
