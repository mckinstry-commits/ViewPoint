SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPRAUATOLoadProc]
/*************************************
* CREATED:	KK/EN 07/26/11
* 
* MODIFIED:	 
* 
* NOTE:		Used to gather data used when loading PRAUProcessReporting
*
* Input:	@prco			PR Company
*
* Output:   @updatePAYGYN	Flag that allows for updating PAYG
*			@updateETPYN	Flag that allows for updating ETP
*			@msg			Error message				
*
* Return code:
*	0 = success, 1 = error 
**************************************/
(@prco bCompany, 
 @updatePAYGYN bYN OUTPUT, 
 @updateETPYN bYN OUTPUT, 
 @msg varchar(60) OUTPUT)

AS 
SET NOCOUNT ON

DECLARE @frmPAYG varchar(30),
		@frmETP varchar(30)

SELECT @frmPAYG = 'PRAUPAYGEmployees'
SELECT @frmETP = 'PRAUEmployeeETPAmounts'

DECLARE	@return_value int,
		@recupdate bYN,
		@recdelete bYN,
		@recadd bYN,
		@attachmentSecurityLevel int,
		@access tinyint,
		@errmsg varchar(512)

EXEC	@return_value = [dbo].[vspDDFormSecurity]
		@co = @prco,
		@form = @frmPAYG,
		@access = @access OUTPUT,
		@recadd = @recadd OUTPUT,
		@recupdate = @updatePAYGYN OUTPUT,
		@recdelete = @recdelete OUTPUT,
		@attachmentSecurityLevel = @attachmentSecurityLevel OUTPUT,
		@errmsg = @errmsg OUTPUT
		
EXEC	@return_value = [dbo].[vspDDFormSecurity]
		@co = @prco,
		@form = @frmETP,
		@access = @access OUTPUT,
		@recadd = @recadd OUTPUT,
		@recupdate = @updateETPYN OUTPUT,
		@recdelete = @recdelete OUTPUT,
		@attachmentSecurityLevel = @attachmentSecurityLevel OUTPUT,
		@errmsg = @errmsg OUTPUT
		

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPRAUATOLoadProc] TO [public]
GO
