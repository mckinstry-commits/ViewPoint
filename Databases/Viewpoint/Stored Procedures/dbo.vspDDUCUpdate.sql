SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDUCUpdate] 
/******************************************************************************
* Created: JRK 05/24/06
* Last Modified: Chris Crewdson 2010-12-17
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
	SET NOCOUNT ON
	
	UPDATE DDUC SET
		ColorSchemeID = @colorschemeid, SmartCursorColor = @smartcursorcolor, 
		ReqFieldColor = @reqfieldcolor, AccentColor1 = @accentcolor1, 
		AccentColor2 = @accentcolor2, UseColorGrad = @usecolorgrad, FormColor1 = @formcolor1, 
		FormColor2 = @formcolor2, GradDirection = @graddirection, 
		LabelBackgroundColor = @labelbackgroundcolor, LabelTextColor = @labeltextcolor,
		LabelBorderStyle = @labelborderstyle
	WHERE VPUserName = @userid AND Company = @co


GO
GRANT EXECUTE ON  [dbo].[vspDDUCUpdate] TO [public]
GO
