SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL,VADDUPAddConnectsUser
-- Create date: 09/20/2011
--
-- MODIFIED BY:	PW 09/21/2012 - Removed Recording Framwork columns
--
-- Description:	This proc adds a Viewpoint user to the database
-- =============================================
CREATE PROCEDURE [dbo].[vspVADDUPAddConnectsUser]
	-- Add the parameters for the stored procedure here
	(@username varchar(40))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF NOT EXISTS (Select VPUserName from DDUP where VPUserName = @username)
	
	exec sp_executesql N'insert DDUP ([VPUserName],[MaxLookupRows],[MaxFilterRows],[DefaultDestType],[WindowsUserName],
[UserType],[FullName],[EMail],[Phone],[EnterAsTab],[ConfirmUpdate],
[ExtendControls],[ToolTipHelp],[SmartCursor],[SavePrinterSettings],[MergeGridKeys],[RestrictedBatches],[DefaultCompany],[PayCategory],
[AccessibleOnly],[MinimizeUse],[HideModFolders],[MultiFormInstance],[MenuInfo],[MenuAdmin],[FormAdmin],[ShowRates],[AltGridRowColors],
[HRCo],[HRRef],[PRCo],[Employee],[MyTimesheetRole]) values (@VPUserName,@MaxLookupRows,@MaxFilterRows,@DefaultDestType,@WindowsUserName,
@UserType,@FullName,@EMail,@Phone,@EnterAsTab,@ConfirmUpdate,@ExtendControls,
@ToolTipHelp,@SmartCursor,@SavePrinterSettings,@MergeGridKeys,@RestrictedBatches,@DefaultCompany,@PayCategory,@AccessibleOnly,@MinimizeUse,
@HideModFolders,@MultiFormInstance,@MenuInfo,@MenuAdmin,@FormAdmin,@ShowRates,@AltGridRowColors,@HRCo,@HRRef,@PRCo,@Employee,@MyTimesheetRole)',
N'@VPUserName varchar(40),@MaxLookupRows int,@MaxFilterRows varchar(8000),@DefaultDestType varchar(5),@WindowsUserName varchar(8000),
@UserType smallint,@FullName varchar(40),
@EMail varchar(8000),@Phone varchar(8000),@EnterAsTab varchar(1),@ConfirmUpdate varchar(1),@ExtendControls varchar(1),@ToolTipHelp varchar(1),
@SmartCursor varchar(1),@SavePrinterSettings varchar(1),@MergeGridKeys varchar(1),@RestrictedBatches varchar(1),@DefaultCompany tinyint,
@PayCategory int,@AccessibleOnly varchar(1),@MinimizeUse varchar(1),@HideModFolders varchar(1),@MultiFormInstance varchar(1),@MenuInfo tinyint,
@MenuAdmin varchar(1),@FormAdmin varchar(1),@ShowRates varchar(1),@AltGridRowColors varchar(1),@HRCo tinyint,@HRRef int,@PRCo tinyint,
@Employee int,@MyTimesheetRole tinyint',
@VPUserName=@username,@MaxLookupRows=NULL,@MaxFilterRows=NULL,@DefaultDestType='EMail',@WindowsUserName=NULL,
@UserType=1,@FullName=@username,@EMail=NULL,@Phone=NULL,
@EnterAsTab='Y',@ConfirmUpdate='N',@ExtendControls='N',@ToolTipHelp='Y',@SmartCursor='N',@SavePrinterSettings='N',@MergeGridKeys='N',
@RestrictedBatches='N',@DefaultCompany=1,@PayCategory=NULL,@AccessibleOnly='N',@MinimizeUse='N',@HideModFolders='N',@MultiFormInstance='N',
@MenuInfo=0,@MenuAdmin='N',@FormAdmin='N',@ShowRates='N',@AltGridRowColors='N',@HRCo=NULL,@HRRef=NULL,@PRCo=NULL,@Employee=NULL,@MyTimesheetRole=1
END
GO
GRANT EXECUTE ON  [dbo].[vspVADDUPAddConnectsUser] TO [public]
GO
