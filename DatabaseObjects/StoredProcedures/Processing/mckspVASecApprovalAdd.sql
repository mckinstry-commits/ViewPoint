USE [Viewpoint]
GO
/****** Object:  StoredProcedure [dbo].[mckspVASecApprovalAdd]    Script Date: 11/25/2014 1:16:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Eric Shafer
-- Create date: 9/24/2014
-- Description:	Create User Account if one doesn't already exist and...
--	create (ud)VA Security review records for Security approvals
-- Used by the McKinstry help desk to create VP user profiles from the onboarding form.
-- Changed 11/25/2014 Arun Thomas
   /* Condition logic for insert into udVASecApprovals if it exists*/
-- =============================================
ALTER PROCEDURE [dbo].[mckspVASecApprovalAdd] 
	-- Add the parameters for the stored procedure here
	@User bVPUserName = '', 
	@Package varchar(10) = '',
	 @Email varchar(255) = ''
	, @EmployeeNumber bEmployee
	, @EmployeeCo bCompany
	, @EmployeeName VARCHAR(255)
	, @OfficePhone VARCHAR(255)
	, @CellPhone VARCHAR(255)
	, @ReturnMessage VARCHAR(MAX) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode INT = 1, @VPUserName bVPUserName

    -- Insert statements for procedure here
	IF @User NOT LIKE 'MCKINSTRY\%'
	BEGIN
		SET @VPUserName = 'MCKINSTRY\' + @User
	END
	ELSE
	BEGIN
		SET @VPUserName = @User
	END
	BEGIN
		--CHECK FOR AND ADD VP USER ACCOUNT (DDUP)
		IF NOT EXISTS(
				SELECT TOP 1 1 FROM dbo.DDUP
				WHERE VPUserName = @VPUserName
			)
																																																																																																																																																																																																					BEGIN
			BEGIN TRY
			INSERT INTO dbo.DDUP
			    ( VPUserName ,
			        ShowRates ,
			        HotKeyForm ,
			        RestrictedBatches ,
			        FullName ,
			        Phone ,
			        EMail ,
			        ConfirmUpdate ,
			        DefaultCompany ,
			        EnterAsTab ,
			        ExtendControls ,
			        SavePrinterSettings ,
			        SmartCursor ,
			        ToolTipHelp ,
			        Project ,
			        PRGroup ,
			        PREndDate ,
			        JBBillMth ,
			        JBBillNumber ,
			        MenuColWidth ,
			        LastNode ,
			        LastSubFolder ,
			        MinimizeUse ,
			        AccessibleOnly ,
			        ViewOptions ,
			        ReportOptions ,
			        SmartCursorColor ,
			        AccentColor1 ,
			        UseColorGrad ,
			        FormColor1 ,
			        FormColor2 ,
			        GradDirection ,
			        UniqueAttchID ,
			        MenuAdmin ,
			        AccentColor2 ,
			        ReqFieldColor ,
			        IconSize ,
			        FontSize ,
			        FormAdmin ,
			        MultiFormInstance ,
			        PayCategory ,
			        HideModFolders ,
			        FolderSize ,
			        Job ,
			        Contract ,
			        MenuInfo ,
			        LastReportID ,
			        ColorSchemeID ,
			        MappingID ,
			        ImportId ,
			        ImportTemplate ,
			        JBTMBillMth ,
			        JBTMBillNumber ,
			        PMTemplate ,
			        MergeGridKeys ,
			        MaxLookupRows ,
			        MaxFilterRows ,
			        PMViewName ,
			        DefaultColorSchemeID ,
			        AltGridRowColors ,
			        HRCo ,
			        HRRef ,
			        DefaultDestType ,
			        WindowsUserName ,
			        SelectedTemplate ,
			        RQEntyHeaderID ,
			        PRCo ,
			        Employee ,
			        RQQuoteEditHeaderID ,
			        MyTimesheetRole ,
			        AttachmentGrouping ,
			        IsHelpUpToDate ,
			        LabelBackgroundColor ,
			        LabelTextColor ,
			        LabelBorderStyle ,
			        ShowLogoPanel ,
			        ShowMainToolbar ,
			        UserType ,
			        SaveLastUsedParameters ,
			        ReportViewerOptions ,
			        ThumbnailMaxCount ,
			        udReviewer ,
			        --FourProjectsUserName ,
			        --FourProjectsPassword ,
			        SendViaSmtp ,
			        udApplyMaster ,
			        udTempUser ,
			        udTermYN
			    )
			VALUES  ( @VPUserName , -- VPUserName - bVPUserName
			        'N' , -- ShowRates - bYN
			        '' , -- HotKeyForm - varchar(30)
			        'N' , -- RestrictedBatches - bYN
			        @EmployeeName , -- FullName - varchar(60)
			        @OfficePhone , -- Phone - varchar(20)
			        @Email , -- EMail - varchar(60)
			        'N' , -- ConfirmUpdate - bYN
			        @EmployeeCo , -- DefaultCompany - bCompany
			        'Y' , -- EnterAsTab - bYN
			        'Y' , -- ExtendControls - bYN
			        'Y' , -- SavePrinterSettings - bYN
			        'Y' , -- SmartCursor - bYN
			        'Y' , -- ToolTipHelp - bYN
			        NULL , -- Project - bJob
			        NULL , -- PRGroup - bGroup
			        NULL , -- PREndDate - bDate
			        NULL , -- JBBillMth - bMonth
			        0 , -- JBBillNumber - int
			        '' , -- MenuColWidth - varchar(60)
			        '' , -- LastNode - varchar(20)
			        '' , -- LastSubFolder - varchar(30)
			        'N' , -- MinimizeUse - bYN
			        'N' , -- AccessibleOnly - bYN
			        '' , -- ViewOptions - varchar(20)
			        '' , -- ReportOptions - varchar(20)
			        -269163 , -- SmartCursorColor - int
			        -3021587 , -- AccentColor1 - int
			        'N' , -- UseColorGrad - bYN
			        -723724 , -- FormColor1 - int
			        -723724 , -- FormColor2 - int
			        3 , -- GradDirection - tinyint
			        NULL , -- UniqueAttchID - uniqueidentifier
			        'N' , -- MenuAdmin - bYN
			        NULL , -- AccentColor2 - int
			        NULL , -- ReqFieldColor - int
			        NULL , -- IconSize - tinyint
			        NULL , -- FontSize - tinyint
					--SELECT UseColorGrad FROM DDUP
			        'N' , -- FormAdmin - bYN
			        'N' , -- MultiFormInstance - bYN
			        0 , -- PayCategory - int
			        'N' , -- HideModFolders - bYN
			        0 , -- FolderSize - tinyint
			        NULL , -- Job - bJob
			        NULL , -- Contract - bContract
			        CASE WHEN @Package = 'PM' THEN 1 ELSE 0 END , -- MenuInfo - tinyint
			        0 , -- LastReportID - int
			        28 , -- ColorSchemeID - int
			        0 , -- MappingID - int
			        NULL , -- ImportId - varchar(20)
			        NULL , -- ImportTemplate - varchar(10)
			        NULL , -- JBTMBillMth - bMonth
			        NULL , -- JBTMBillNumber - int
			        NULL , -- PMTemplate - varchar(50)
			        'N' , -- MergeGridKeys - bYN
			        NULL , -- MaxLookupRows - int
			        NULL , -- MaxFilterRows - int
			        NULL , -- PMViewName - varchar(10)
			        28 , -- DefaultColorSchemeID - int
			        'Y' , -- AltGridRowColors - bYN
			        NULL , -- HRCo - bCompany
			        NULL , -- HRRef - bHRRef
			        'EMail' , -- DefaultDestType - varchar(30)
			        @User , -- WindowsUserName - bVPUserName
			        '' , -- SelectedTemplate - varchar(50)
			        '' , -- RQEntyHeaderID - varchar(10)
			        @EmployeeCo , -- PRCo - bCompany
			        @EmployeeNumber , -- Employee - bEmployee
			        NULL , -- RQQuoteEditHeaderID - varchar(10)
			        1 , -- MyTimesheetRole - tinyint
			        NULL , -- AttachmentGrouping - varchar(200)
			        'N' , -- IsHelpUpToDate - bYN
			        NULL , -- LabelBackgroundColor - int
			        NULL , -- LabelTextColor - int
			        NULL , -- LabelBorderStyle - int
			        'Y' , -- ShowLogoPanel - bYN
			        'Y' , -- ShowMainToolbar - bYN
			        0 , -- UserType - smallint
			        'Y' , -- SaveLastUsedParameters - bYN
			        2 , -- ReportViewerOptions - tinyint
			        NULL , -- ThumbnailMaxCount - int
			        NULL , -- udReviewer - varchar(3)
			        --N'' , -- FourProjectsUserName - nvarchar(255)
			        --N'' , -- FourProjectsPassword - nvarchar(max)
			        'Y' , -- SendViaSmtp - bYN
			        'Y' , -- udApplyMaster - bYN
			        CASE WHEN @EmployeeNumber IS NULL OR @EmployeeNumber = '' THEN 'Y' ELSE 'N' END , -- udTempUser - bYN
			        'N'  -- udTermYN - bYN
			    )
			END TRY
			BEGIN CATCH
			DECLARE @ErrorMsg VARCHAR(8000)
			SELECT @ErrorMsg = ERROR_MESSAGE()
				EXEC msdb.dbo.sp_send_dbmail 
					@profile_name = 'Viewpoint',
					@recipients = 'erics@mckinstry.com',
					@subject = 'Error on VP User Profile Create',
					@body = @ErrorMsg,
					@body_format = 'HTML'
			END CATCH
					

		END
			ELSE
			BEGIN
				SELECT @rcode = 0, @ReturnMessage = 'User already exists.  '
			END


		--CHECK FOR MISSING SECURITY GROUP MEMBERSHIP AND ADD REQUESTS
																																																																																																	
																																																																																																	
	    IF EXISTS(
		
		SELECT --p.SecGroup --
			TOP 1 1
		FROM dbo.udVAScGrpPacMember p
			LEFT JOIN dbo.DDSU u ON p.SecGroup = u.SecurityGroup AND u.VPUserName = @VPUserName
		WHERE u.SecurityGroup IS NULL AND p.Package = @Package
		)
		BEGIN
		

			DECLARE @Sequence INT = 1
			BEGIN
				
				IF NOT EXISTS(SELECT TOP 1 1
				FROM dbo.udVASecApprovals a
					JOIN dbo.udVASPckAuthMembers m ON a.Approver = m.VPUserName AND a.SecPack = m.Package
				WHERE @VPUserName = VPUser AND @Package = a.SecPack
				      and a.Processed = 'N'
				GROUP BY a.Approver, a.SecPack, a.VPUser)

				BEGIN
				

					SELECT 
						@Sequence = MAX(a.Seq)+1
					FROM dbo.udVASecApprovals a
						JOIN dbo.udVASPckAuthMembers m ON a.Approver = m.VPUserName AND a.SecPack = m.Package
					WHERE @VPUserName = VPUser AND @Package = a.SecPack
					GROUP BY a.Approver, a.SecPack, a.VPUser

	
				
				
				
					BEGIN TRY
						INSERT INTO udVASecApprovals (
							Approver
							, SecPack
							, Seq
							, ApprovedYN, RejectedYN
							,VPUser 
							, Processed)
						SELECT VPUserName --Approver
							, Package --Package
							, @Sequence --Sequence
							, 'N','N'
							,@VPUserName --User Requesting Access
							, 'N'
						FROM dbo.udVASPckAuthMembers
						WHERE Package = @Package

						
					END TRY
					BEGIN CATCH
						SELECT @ErrorMsg = ERROR_MESSAGE()
						
					END CATCH
			
					SELECT @rcode = 0, @ReturnMessage = ISNULL(@ReturnMessage,'')+'Approval of security pack, ' + @Package + ', for user, '+@User + ', has been requested.'

			END
			END
			--SEND EMAILS TO WARN APPROVERS OF AWAITING APPROVALS
			DECLARE @To VARCHAR(255), @subject VARCHAR(255), @body NVARCHAR(MAX)

			DECLARE sndmail_Crsr CURSOR FOR 
			SELECT up.EMail
			FROM dbo.udVASecApprovals a
				JOIN dbo.DDUP up ON a.Approver = up.VPUserName
			WHERE @VPUserName = VPUser AND SecPack = @Package AND Seq = CONVERT(VARCHAR(10),@Sequence)

			OPEN sndmail_Crsr
			FETCH NEXT FROM sndmail_Crsr INTO @To

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @subject = 'Request for access to '+ @Package 
				SET @To = @To +'; erptest@mckinstry.com'
				SET @body = @subject + ' is awaiting your approval.'+CHAR(10)+CHAR(13)+ 
					'Open Viewpoint and go to ''User Database > Programs > VA Security Approvals'' to process the request(s).'

				EXEC msdb.dbo.sp_send_dbmail 
					@profile_name = 'Viewpoint',
					@recipients = @To,
					@subject = @subject,
					@body = @body,
					@body_format = 'HTML'

				FETCH NEXT FROM sndmail_Crsr INTO @To
			END	
			CLOSE sndmail_Crsr
			DEALLOCATE sndmail_Crsr
		END
		ELSE
		BEGIN
			SELECT @rcode = 1, @ReturnMessage = ISNULL(@ReturnMessage,'')+'All security groups have already been added for this user.  No approval needed.'
		END
	
	END
		RETURN @rcode
END


