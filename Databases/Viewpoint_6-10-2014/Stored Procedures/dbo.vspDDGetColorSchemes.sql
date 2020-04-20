SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDGetColorSchemes]
/******************************************************************************
* Created:  MJ 9/22/05 as vspVPMenuGetColorSchemes
*
* Used by the color picker form to retrieve color schemes.
* 
* Output
*	@errmsg
*
*******************************************************************************
* Modified:
* 2006-05-25 - Renamed by JRK to vspDDGetColorSchemes
* 2010-12-17 - Chris Crewdson - Added LabelBackgroundColor and LabelTextColor columns - Issue #141940
* 2011-01-11 - Chris Crewdson - Added LabelBorderStyle column
*******************************************************************************/
as

declare @rcode int
select @rcode = 0	--not used at this point.


set nocount on 
    select ColorSchemeID, Description, SmartCursorColor, ReqFieldColor,
        AccentColor1, AccentColor2, UseColorGrad, FormColor1, FormColor2, GradDirection,
        LabelBackgroundColor, LabelTextColor,
        LabelBorderStyle
    from DDCS
   
vspexit:
    return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspDDGetColorSchemes] TO [public]
GO
