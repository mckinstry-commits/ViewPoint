SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDUCSelect] 
/******************************************************************************
* Created: JRK 05/24/06
*
* Used to manage users' colors-by-company.
*
* Inputs:
*	The user's username.
*
* Output:
*	resultset of users' colors, by company.
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
*******************************************************************************
* Modified:
* 2010-12-17 - Chris Crewdson - Added LabelBackgroundColor and LabelTextColor columns - Issue #141940
* 2011-01-11 - Chris Crewdson - Added LabelBorderStyle column
*******************************************************************************/
(
    @userid bVPUserName,
    @errmsg varchar(512) OUTPUT
)
AS
    SET NOCOUNT ON

    SELECT
        VPUserName, Company, ColorSchemeID, SmartCursorColor, ReqFieldColor, 
        AccentColor1, AccentColor2, UseColorGrad, FormColor1, FormColor2, 
        GradDirection,
        LabelBackgroundColor, LabelTextColor,
        LabelBorderStyle
    FROM DDUC
    WHERE VPUserName = @userid
     
    RETURN

GO
GRANT EXECUTE ON  [dbo].[vspDDUCSelect] TO [public]
GO
