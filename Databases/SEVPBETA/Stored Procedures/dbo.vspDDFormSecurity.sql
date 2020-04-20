SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspDDFormSecurity]
/********************************************************
* Created: GG 07/11/03
* Modified: GG 07/15/04 - add primary Module 'active' check
*			GG 01/21/05 - allow all Company entries (Co=-1)
*			GG 04/10/06 - mods for Mod and Form LicLevel
*			GG 03/12/07 - use least restrictive record level permissions
*			GG 09/05/07 - #125347 - mods for security form
*			JonathanP 02/25/09 - #132390 - Updated to handle attachment security level column in DDFS
			AR 12/27/2010 - refactoring procedure for performance gains
*
* Used to determine program security level for a specific 
* form and user.
*
* Inputs:
*	@co		Active Company#
*	@form	Form name
*	
* Outputs:
*	@access				Access level 0 = full, 1 = by tab, 2 = denied, null = missing
*	@recadd				Record Add option (Y/N)
*	@recupdate			Record Update option (Y/N)
*	@recdelete 			Record Delete option (Y/N)
*   @attachmentSecurityLevel	0 = Add, 1 = Add/Edit, 2 = Add/Edit/Delete, -1 = None
*	@errmsg				Message
*
* Return Code:
*	@rcode		0 = success, 1 = error
*
*********************************************************/
(
  @co bCompany = NULL,
  @form varchar(30) = NULL,
  @access tinyint OUTPUT,
  @recadd bYN = NULL OUTPUT,
  @recupdate bYN = NULL OUTPUT,
  @recdelete bYN = NULL OUTPUT,
  @attachmentSecurityLevel int = NULL OUTPUT,
  @errmsg varchar(512) OUTPUT
)
AS 
SET nocount ON

DECLARE @rcode int,
    @user bVPUserName,
    @mod char(2),
    @modliclevel tinyint,
    @formliclevel tinyint,
    @secureform varchar(30),
    @detailsecurity bYN,
    @subProcErr varchar(512)

BEGIN TRY
	SET @rcode = 0;
	
	IF @co IS NULL
		OR @form IS NULL 
	BEGIN
		SET  @errmsg = 'Missing required input parameter(s): Company # and/or Form!'
		RAISERROR(@errmsg, 15,1)
	END

	-- get security form (security form should equal current form for all custom forms)
	SELECT  @secureform = SecurityForm,
			@detailsecurity = DetailFormSecurity,
			@formliclevel = LicLevel,
			@mod = [Mod]
	FROM    dbo.DDFHSharedSingleForm (NOLOCK)
	WHERE   Form = @form

	IF @@ROWCOUNT = 0 
    BEGIN
        SET  @errmsg = @form + ' is not setup in DD Form Header!'
        RAISERROR(@errmsg, 15,2)
    END
	
	--check for security override, if set use current not security form
	IF @detailsecurity = 'Y'
	BEGIN
		SET @secureform = @form
	END
	
	--validate security form
	IF @secureform <> @form 
    BEGIN
        IF NOT EXISTS ( SELECT  1
                        FROM    dbo.DDFHSharedSingleForm (NOLOCK)
                        WHERE   Form = @secureform ) 
            BEGIN
                SET  @errmsg = 'Security form ' + @secureform
                        + ' is not setup in DD Form Header!'
                RAISERROR(@errmsg, 15,3)
            END
        ELSE
        -- we need to grab the secured form params now
        -- do this here for no reason to hit the view again if we don't have a 
        -- secured form
        BEGIN 
			  SELECT	@formliclevel = LicLevel,
						@mod = [Mod]
			FROM    dbo.DDFHSharedSingleForm (NOLOCK)
			WHERE   Form = @secureform
        END
    END

	-- make sure the forms' primary module is active and check license level
	SELECT  @modliclevel = m.LicLevel
	FROM    dbo.vDDMO m ( NOLOCK )
	WHERE   m.[Mod] = @mod
			AND m.Active = 'Y'
			
	IF @@ROWCOUNT = 0 
    BEGIN
        SET  @errmsg = 'Primary module for this form is not active!'
        RAISERROR(@errmsg, 15,4)
    END
    

    
	SELECT  @user = SUSER_SNAME()	-- current user name

  	-- cannot run DD forms unless logged on as 'viewpointcs'
	IF @user <> 'viewpointcs' AND @mod = 'DD'
	BEGIN
		SET  @errmsg = 'Must use the ''viewpointcs'' login to access DD forms!'
		RAISERROR(@errmsg, 15,5)
	END
	 -- initialize return params, which in this spot seems to be invalid, but the old proc did it here
	 -- if we error out right now, we have allowed the user access to the form ... this seems wrong
	SELECT 
		@access = 0,
		@recadd = 'Y',
		@recupdate = 'Y',
		@recdelete = 'Y',
		@attachmentSecurityLevel = 2
		
	IF @user = 'viewpointcs' 
		BEGIN			  
			SET @errmsg = 'user is viewpointcs'
			RETURN(0)
		END
	--check Module and Form license levels - don't return error but deny access
	IF @formliclevel > @modliclevel 
		BEGIN
			SELECT  @errmsg = 'Module/Form license level violation.',
					@access = 2,
					@recadd = 'N',
					@recupdate = 'N',
					@recdelete = 'N',
					@attachmentSecurityLevel = -1
			RETURN(0)
		END

	-- 1st check: Form security for user and active company, Security Group -1 
	EXEC @rcode = dbo.vspDDFormUserSecurityCheck
					@co = @co, 
					@form = @secureform,
					@user = @user,
					@recupdate = @recupdate OUTPUT,
					@recdelete = @recdelete OUTPUT,
					@recadd = @recadd OUTPUT,
					@attachmentSecurityLevel = @attachmentSecurityLevel OUTPUT,
					@access = @access OUTPUT,
					@errmsg = @subProcErr OUTPUT
	-- because of the output errmsg, we could have an error passed in, use the one from the sub proc
	-- to determine if we have a valid check
	IF @subProcErr IS NOT NULL
	BEGIN 
		SET @errmsg = @subProcErr
		RETURN (0)
	END

	-- 2nd check: Form security for user across all companies, Security Group -1 and Company = -1
	EXEC @rcode = dbo.vspDDFormUserSecurityCheck
					@co = -1, 
					@form = @secureform,
					@user = @user,
					@recupdate = @recupdate OUTPUT,
					@recdelete = @recdelete OUTPUT,
					@recadd = @recadd OUTPUT,
					@attachmentSecurityLevel = @attachmentSecurityLevel OUTPUT,
					@access = @access OUTPUT,
					@errmsg = @subProcErr   OUTPUT

	-- because of the output errmsg, we could have an error passed in, use the one from the sub proc
	-- to determine if we have a valid check	
	IF @subProcErr IS NOT NULL
	BEGIN 
		SET @errmsg = @subProcErr
		RETURN (0)
	END
		
	-- 3rd check: Form security for groups that user is a member of within active company
	EXEC @rcode = dbo.vspDDFormGroupSecurityCheck	
								@co = @co,
								@form = @secureform,
								@user =@user,
								@recupdate = @recupdate OUTPUT,
								@recdelete = @recdelete OUTPUT,
								@recadd = @recadd OUTPUT,
								@attachmentSecurityLevel = @attachmentSecurityLevel OUTPUT,
								@access = @access OUTPUT,
								@errmsg = @subProcErr OUTPUT
	-- because of the output errmsg, we could have an error passed in, use the one from the sub proc
	-- to determine if we have a valid check
	IF @subProcErr IS NOT NULL
	BEGIN 
		SET @errmsg = @subProcErr
		RETURN (0)
	END
	
	-- 4th check: Form security for groups that user is a member of across all companies, Company = -1
	EXEC @rcode = dbo.vspDDFormGroupSecurityCheck	
								@co = -1,
								@form = @secureform,
								@user =@user,
								@recupdate = @recupdate OUTPUT,
								@recdelete = @recdelete OUTPUT,
								@recadd = @recadd OUTPUT,
								@attachmentSecurityLevel = @attachmentSecurityLevel OUTPUT,
								@access = @access OUTPUT,
								@errmsg = @subProcErr OUTPUT
	-- because of the output errmsg, we could have an error passed in, use the one from the sub proc
	-- to determine if we have a valid check
	IF @subProcErr IS NOT NULL
	BEGIN 
		SET @errmsg = @subProcErr
		RETURN (0)
	END
	ELSE
	BEGIN 
		SET  @errmsg = @user + ' has not been setup with access to the '
			+ @secureform + ' form!'
		RETURN (0)
	END

END TRY
BEGIN CATCH
   RETURN (1)
END CATCH
	
RETURN 0



GO
GRANT EXECUTE ON  [dbo].[vspDDFormSecurity] TO [public]
GO
