/**************************************************************************************************
Client:		McKinstry Co., LLC
Project:	VU15391 - Sync Vendor Compliance Across Companies
Author:		Neil Jones

Purpose:	Create and attach "Sync Vendor/Comp Attachments" 
			button to AP Vendor Compliance

Requirements:
			Button Name: Sync Vendor/Comp Attachments
			
			Button click, or
				EXEC cspAPVCSyncAttach 
					@Fail,
					@ReturnMessage,
					@APCo,
					@VendorGroup,
					@Vendor,
					@CompCode
			
Change Log:

	20141121	NJ	Initial Coding

**************************************************************************************************/
	BEGIN TRANSACTION
	BEGIN TRY
	  
		DECLARE @Err_Msg		VARCHAR(8000),
				@ErrorSeverity	INT,
				@ErrorState		INT,
				@NextButtonID	INT,
				@FormName		VARCHAR(30),
				@ButtonAction	VARCHAR(MAX),
				@ButtonText		VARCHAR(64),
				@ButtonParent	VARCHAR(255),
				@ButtonActionType	CHAR(1),
				@ButtonWidth	INT,
				@ButtonHeight	INT,
				@ButtonTop		INT,
				@ButtonLeft		INT,
				@ButtonRefresh	TINYINT
				

		SELECT	@FormName			= 'APVendComp',
				@NextButtonID		= NULL,
				@ButtonText			= 'Sync Vendor/Comp Attachments',
				@ButtonParent		= 'pnlKey',
				@ButtonActionType	= '2',
				@ButtonAction		= 'cspAPVCSyncAttach',
				@ButtonWidth		= 142,
				@ButtonHeight		= 42,
				@ButtonTop			= 14,
				@ButtonLeft			= 374,
				@ButtonRefresh		= 1

		--cspAPVCSyncAttach Stored Procedure from APVendComp form.
		IF NOT EXISTS(	SELECT	KeyID
						FROM	vDDFormButtonsCustom
						WHERE	Form = @FormName
							AND	ButtonAction = @ButtonAction)
		BEGIN
		
			--Client may already have a button on APVC. Compensate for this and use the next ButtonID available.
			SELECT	@NextButtonID = ISNULL(MAX(ButtonID),0) + 1
			FROM	vDDFormButtonsCustom
			WHERE	Form = @FormName
			
			INSERT	vDDFormButtonsCustom (
					Form, 
					ButtonID, 
					ButtonText, 
					Parent, 
					ActionType, 
					ButtonAction, 
					Width, 
					Height,
					ButtonTop, 
					ButtonLeft,
					ButtonRefresh)
			VALUES (@FormName,
					@NextButtonID,
					@ButtonText,
					@ButtonParent,
					@ButtonActionType,
					@ButtonAction,
					@ButtonWidth,
					@ButtonHeight,
					@ButtonTop,
					@ButtonLeft,
					@ButtonRefresh)	
		END		
		
		-- don't add parameters if the PRPC button exists and has parameters
		IF NOT EXISTS(	SELECT	parm.KeyID
						FROM	vDDFormButtonParametersCustom as parm
						JOIN	vDDFormButtonsCustom as button
							ON	button.Form = parm.Form
							AND button.ButtonID = parm.ButtonID
						WHERE	button.Form = @FormName
							AND	button.ButtonAction = @ButtonAction)
		BEGIN
			INSERT	vDDFormButtonParametersCustom
				(Form, ButtonID, ParameterID, Name, DefaultType, DefaultValue)
			VALUES
				(@FormName, @NextButtonID, 1, 'FailValue',	0, '0'),
				(@FormName, @NextButtonID, 2, 'ReturnMsg',	0, ''''''),
				(@FormName, @NextButtonID, 3, 'APCo',		4, NULL)	,
				(@FormName, @NextButtonID, 4, 'VGroup',		3, '3'),
				(@FormName, @NextButtonID, 5, 'Vendor',		3, '4'),
				(@FormName, @NextButtonID, 6, 'CompCode',	3, '20')
				
		END

		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		
		ROLLBACK TRANSACTION
	
		SELECT	@Err_Msg	= 'VU15391 - Sync Vendor Compliance Across Companies: Error creating/attaching custom button to AP Vendor Compliance: ' 
							+ ERROR_MESSAGE(),
				@ErrorState = ERROR_STATE(),
				@ErrorSeverity = ERROR_SEVERITY()

		RAISERROR (@Err_Msg, @ErrorSeverity, @ErrorState);

	END CATCH