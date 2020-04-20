SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPRAllowanceTypeCheck]
/***********************************************************
 * Created By:	DAN SO 11/09/2012 TK-19235 - Check to see if PR Allowance Type is being used
 * Modified By:	DAN SO 11/19/2012 TK-19235 - reworked checking tables
 *
 *
 *
 * USAGE:
 * Called from frmPRAllowanceType - check to see if a PRAllowanceType is being used in
 *		vPRCraftClassAllowance OR
 *		vPRCraftClassTemplateAllowance OR
 *		vPRCraftMasterAllowance OR
 *		vPRCraftTemplateAllowance 
 *
 * INPUT PARAMETERS
 *	@AllowanceType	PR Allowance Type
 *
 * OUTPUT PARAMETERS
 *	@InUseYN		Is the PR Allowance Type already being used?
 *	@errmsg			Error message
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *
 *****************************************************/
(@AllowanceType VARCHAR(16),
 @InUseYN bYN OUTPUT, @errmsg VARCHAR(255) OUTPUT)
 
	AS
	SET NOCOUNT ON

	DECLARE @rcode int

	-- PRIME VARIABLES --
	SET @rcode = 0
	SET @InUseYN = 'N'

	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @AllowanceType IS NULL
		BEGIN
   			SET @errmsg = 'Missing Allowance Type!'
   			SET @rcode = 1
   			GOTO vspExit
		END

	------------------------------------
	-- CHECK TABLES FOR AllowanceType --
	------------------------------------
	IF EXISTS (select a.* from
		(
			SELECT AllowanceTypeName, 'vPRCraftClassAllowance' AS TableName
			  FROM dbo.vPRCraftClassAllowance
                                          
		     UNION ALL 
	                                          
			SELECT AllowanceTypeName, 'vPRCraftClassTemplateAllowance' AS TableName
			  FROM dbo.vPRCraftClassTemplateAllowance 
	     
			 UNION ALL 
	                                          
			SELECT AllowanceTypeName, 'vPRCraftMasterAllowance' AS TableName
			  FROM dbo.vPRCraftMasterAllowance 
	     
			 UNION ALL 
	                                          
			SELECT AllowanceTypeName, 'vPRCraftTemplateAllowance' AS TableName
			  FROM dbo.vPRCraftTemplateAllowance
		) a
		              
		WHERE a.AllowanceTypeName = @AllowanceType)
			BEGIN
				SET @InUseYN = 'Y'
			END


vspExit:
	IF @rcode <> 0 SET @errmsg = isnull(@errmsg,'')
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRAllowanceTypeCheck] TO [public]
GO
