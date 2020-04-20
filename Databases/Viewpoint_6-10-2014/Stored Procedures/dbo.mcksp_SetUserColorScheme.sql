SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[mcksp_SetUserColorScheme]
(
	@themeid  int
,	@vp_user_name VARCHAR(30)	
,	@company	int = NULL
,	@set_user_default bYN = 'N'
)
AS

SET NOCOUNT ON

--DECLARE @themeid  int
DECLARE @desc varchar(128)
DECLARE @smartcursorcolor  int
DECLARE @reqfieldcolor  int
DECLARE @accentcolor1 int
DECLARE @accentcolor2 int
DECLARE @usecolorgrad  bYN
DECLARE @formcolor1 int
DECLARE @formcolor2 int
DECLARE @graddirection tinyint
DECLARE @labelbackgroundcolor int
DECLARE @labeltextcolor int
DECLARE @labelborderstyle TINYINT
	
IF  ( 
		EXISTS ( SELECT 1 FROM DDUP WHERE UPPER(VPUserName)=UPPER(@vp_user_name)) 
	AND ( EXISTS ( SELECT 1 FROM dbo.bHQCO WHERE HQCo=@company) OR (@company IS NULL) )
	)
BEGIN

	IF NOT EXISTS ( SELECT 1 FROM DDCS WHERE ColorSchemeID=@themeid) 
	BEGIN
		SELECT @themeid = MAX(ColorSchemeID)+1 FROM DDCS 
		SELECT @desc = 'McKinstry Theme ' + CAST(@themeid AS varchar(10))
		EXEC dbo.vspDDInsertColorScheme	
			@themeid = @themeid, -- int
			@desc = @desc, -- varchar(128)
			@smartcursorcolor = -16711681, -- int
			@reqfieldcolor = -1336, -- int
			@accentcolor1 = -3023120, -- int
			@accentcolor2 = -3023120, -- int
			@usecolorgrad = 'N', -- bYN
			@formcolor1 = -723724, -- int
			@formcolor2 = -723724, -- int
			@graddirection = 3, -- tinyint
			@labelbackgroundcolor = -1970701, -- int
			@labeltextcolor = -1970701, -- int
			@labelborderstyle = 0 -- tinyint					
	END


	-- Set Theme for User

	--DECLARE @vp_user_name VARCHAR(30)

	--SELECT @vp_user_name='MCKINSTRY\billo',@themeid =44

	SELECT @vp_user_name=VPUserName FROM DDUP WHERE UPPER(VPUserName)=UPPER(@vp_user_name)

	SELECT
		@desc = Description
	,	@smartcursorcolor = SmartCursorColor
	,	@reqfieldcolor = ReqFieldColor -- -1336 -- int
	,   @accentcolor1 = AccentColor1 -- -3023120 -- int
	,   @accentcolor2 = AccentColor2 ---3023120 -- int
	,   @usecolorgrad = UseColorGrad -- 'N' -- bYN
	,   @formcolor1 = FormColor1 -- -723724 -- int
	,   @formcolor2 = FormColor2 -- -723724 -- int
	,   @graddirection = GradDirection -- 3 -- tinyint
	,   @labelbackgroundcolor = LabelBackgroundColor -- -1970701 -- int
	,   @labeltextcolor = LabelTextColor -- -14935012 -- int
	,   @labelborderstyle = LabelBorderStyle -- 0 -- tinyint
	FROM 
		DDCS
	WHERE
		ColorSchemeID=@themeid

	IF EXISTS ( SELECT 1 FROM DDUC WHERE (Company=@company OR @company IS NULL)  AND VPUserName=@vp_user_name)
	BEGIN
	UPDATE DDUC SET
		ColorSchemeID=@themeid
	,	SmartCursorColor=@smartcursorcolor	
	,	ReqFieldColor=@reqfieldcolor
	,	AccentColor1=@accentcolor1
	,	AccentColor2=@accentcolor2
	,	UseColorGrad=@usecolorgrad
	,	FormColor1=@formcolor1	
	,	FormColor2=@formcolor2
	,	GradDirection=@graddirection
	,	LabelBackgroundColor=@labelbackgroundcolor
	,	LabelTextColor=@labeltextcolor
	,	LabelBorderStyle=@labelborderstyle
	WHERE 
		VPUserName=@vp_user_name
	AND (Company=@company OR @company IS NULL)
	END
	ELSE
	BEGIN
		IF @company IS NULL
		BEGIN

		INSERT dbo.DDUC
				( VPUserName ,
				  Company ,
				  ColorSchemeID ,
				  SmartCursorColor ,
				  ReqFieldColor ,
				  AccentColor1 ,
				  AccentColor2 ,
				  UseColorGrad ,
				  FormColor1 ,
				  FormColor2 ,
				  GradDirection ,
				  LabelBackgroundColor ,
				  LabelTextColor ,
				  LabelBorderStyle
				)
		select  @vp_user_name , -- VPUserName - bVPUserName
				HQCo , -- Company - bCompany
				@themeid , -- ColorSchemeID - int
				@smartcursorcolor , -- SmartCursorColor - int
				@reqfieldcolor , -- ReqFieldColor - int
				@accentcolor1 , -- AccentColor1 - int
				@accentcolor2 , -- AccentColor2 - int
				@usecolorgrad , -- UseColorGrad - bYN
				@formcolor1 , -- FormColor1 - int
				@formcolor2 , -- FormColor2 - int
				@graddirection , -- GradDirection - tinyint
				@labelbackgroundcolor , -- LabelBackgroundColor - int
				@labeltextcolor , -- LabelTextColor - int
				@labelborderstyle  -- LabelBorderStyle - int
		FROM
			dbo.bHQCO
		WHERE HQCo NOT IN ( SELECT DISTINCT Company FROM DDUC WHERE VPUserName=@vp_user_name )
						
		END
		ELSE
		begin
		
		INSERT dbo.DDUC
				( VPUserName ,
				  Company ,
				  ColorSchemeID ,
				  SmartCursorColor ,
				  ReqFieldColor ,
				  AccentColor1 ,
				  AccentColor2 ,
				  UseColorGrad ,
				  FormColor1 ,
				  FormColor2 ,
				  GradDirection ,
				  LabelBackgroundColor ,
				  LabelTextColor ,
				  LabelBorderStyle
				)
		VALUES  ( @vp_user_name , -- VPUserName - bVPUserName
				  @company , -- Company - bCompany
				  @themeid , -- ColorSchemeID - int
				  @smartcursorcolor , -- SmartCursorColor - int
				  @reqfieldcolor , -- ReqFieldColor - int
				  @accentcolor1 , -- AccentColor1 - int
				  @accentcolor2 , -- AccentColor2 - int
				  @usecolorgrad , -- UseColorGrad - bYN
				  @formcolor1 , -- FormColor1 - int
				  @formcolor2 , -- FormColor2 - int
				  @graddirection , -- GradDirection - tinyint
				  @labelbackgroundcolor , -- LabelBackgroundColor - int
				  @labeltextcolor , -- LabelTextColor - int
				  @labelborderstyle  -- LabelBorderStyle - int
				)
				
				
		END
	END	
	
	IF @company IS null
		PRINT 'VP User "' + @vp_user_name + '" for All Companies updated to use Color Scheme "' + @desc + '"' + '" (' + CAST(@themeid AS VARCHAR(10)) + ')'
	ELSE
		PRINT 'VP User "' + @vp_user_name + '" for Company "' + CAST(@company AS VARCHAR(5)) + '" updated to use Color Scheme "' + @desc + '"' + '" (' + CAST(@themeid AS VARCHAR(10)) + ')'
	
END
ELSE
BEGIN
	PRINT 'VP User "' + @vp_user_name + '" or Company "' + CAST(@company AS VARCHAR(5)) + '" does not exist.'
END


IF @set_user_default='Y'
BEGIN
	-- User Profile Default
	UPDATE DDUP SET
		ColorSchemeID=@themeid
	,	SmartCursorColor=@smartcursorcolor
	,	ReqFieldColor=@reqfieldcolor
	,	AccentColor1=@accentcolor1
	,	AccentColor2=@accentcolor2
	,	UseColorGrad=@usecolorgrad
	,	FormColor1=@formcolor1	
	,	FormColor2=@formcolor2
	,	GradDirection=@graddirection
	,	LabelBackgroundColor=@labelbackgroundcolor
	,	LabelTextColor=@labeltextcolor
	,	LabelBorderStyle=@labelborderstyle
	WHERE 
		VPUserName=@vp_user_name
	
	-- User Profile (Extended) Default	
	UPDATE DDUPExtended SET
		ColorSchemeID=@themeid
	,	SmartCursorColor=@smartcursorcolor
	,	ReqFieldColor=@reqfieldcolor
	,	AccentColor1=@accentcolor1
	,	AccentColor2=@accentcolor2
	,	UseColorGrad=@usecolorgrad
	,	FormColor1=@formcolor1	
	,	FormColor2=@formcolor2
	,	GradDirection=@graddirection
	,	LabelBackgroundColor=@labelbackgroundcolor
	,	LabelTextColor=@labeltextcolor
	,	LabelBorderStyle=@labelborderstyle
	WHERE 
		VPUserName=@vp_user_name

	-- User Specific SmartCursor and ReqFieldCursor
	UPDATE DDUT SET
		ColorSchemeID=@themeid
	,	SmartCursorColor=@smartcursorcolor	
	,	ReqFieldColor=@reqfieldcolor
	
	DELETE DDUC WHERE VPUserName=@vp_user_name AND ColorSchemeID=@themeid
	
	PRINT 'VP User "' + @vp_user_name + '" Default Color Scheme updated to use Color Scheme "' + @desc + '" (' + CAST(@themeid AS VARCHAR(10)) + ')'
END
GO
