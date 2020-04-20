SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPOCommonInfoGetForPOEntry]
/********************************************************
* CREATED BY: 	DC 06/07/06
* MODIFIED BY:	DC added the Co parameter check
*				DC 08/21/08 - #128925 - Added HQ Country to output params
*				JVH 4/25/11 - Added the SM Pay Type as an output param. Also updated USER_NAME to SUSER_NAME to work with viewpointcs
*				DAN SO 10/28/2011 - D-03038 - Make sure AP/PO Company exist
*              
* USAGE:
* 	Retrieves common info from AP Company and PO Company for use in PO
*	form's DDFH LoadProc field 
*
* INPUT PARAMETERS:
*	@co			AP Co#
*
* OUTPUT PARAMETERS:
*	@jcco				JC Co#
*	@emco				EM Co#
*	@glco				GL Co#
*	@paycategoryyn		Pay Categories option
*	@vendorgroup		Vendor Group
*	@taxgroup			Tax Group
*	@receiptupdateYN	Receipt Update from POCO
*	@glrecexpinterfacelvl	GL Rec Exp Interface Lvl from POCO
*	@recjcinterfacelvl	Rec JC Interface Lvl from POCO
*	@receminterfacelvl	Rec EM Interface Lvl from POCO
*	@recininterfacelvl	Rec IN Interface Lvl from POCO
*	@paytypeyn			Pay Type YN from POCO
*	@exppaytype			Exp Pay Type from APCO
*	@jobpaytype			Job Pay Type from APCO
*	@SMPayType			SM Pay Type from APCO
*	@userprofilepaycategory	Pay Category from DDUP
*	@paycategoryapco	Pay Category from APCO
*	
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
  (@co bCompany=0, 
  @jcco bCompany =null output,
  @emco bCompany =null output,
  @glco bCompany =null output,
  @paycategoryyn bYN = null output,
  @vendorgroup bGroup = null output, 
  @taxgroup bGroup =  null output, 
  @receiptupdateyn bYN output,
  @glrecexpinterfacelvl tinyint output,
  @recjcinterfacelvl tinyint output,
  @receminterfacelvl tinyint output,
  @recininterfacelvl tinyint output,
  @paytypeyn bYN output,
  @exppaytype tinyint output,
  @jobpaytype tinyint output,
  @SMPayType tinyint OUTPUT,
  @userprofilepaycategory int output,
  @paycategoryapco int output, 
	@matlgroup bGroup = null output,
	@hqcountry char(2) output,  --DC #128925
	@errmsg varchar(255) output)

  as 
set nocount on
declare @rcode int

select @rcode = 0 

-- Get info from APCO
	select @jcco=JCCo, 
		@emco=EMCo, 
		@glco=GLCo,
		@paycategoryyn=PayCategoryYN,
		@exppaytype = ExpPayType,
		@jobpaytype = JobPayType,
		@SMPayType = SMPayType,
		@paycategoryapco = PayCategory
	from bAPCO with (nolock)
	where APCo=@co
	
	-- D-03038 --
	IF @@ROWCOUNT = 0
		BEGIN
			SET @errmsg = 'AP Company does NOT exist!' 
			SET @rcode = 1
			GOTO vspexit
		END


--Get info from POCO
   select @receiptupdateyn = ReceiptUpdate, 
   		@glrecexpinterfacelvl = GLRecExpInterfacelvl,
   		@recjcinterfacelvl = RecJCInterfacelvl,
   		@receminterfacelvl = RecEMInterfacelvl,
   		@recininterfacelvl = RecINInterfacelvl,
   		@paytypeyn = PayTypeYN
   	from bPOCO with(nolock)
   	where POCo=@co
   	
   	-- D-03038 --
	IF @@ROWCOUNT = 0
		BEGIN
			SET @errmsg = 'PO Company does NOT exist!' 
			SET @rcode = 1
			GOTO vspexit
		END


	-- Get info from HQCO
	select  @vendorgroup =VendorGroup, @taxgroup=TaxGroup, 
		@matlgroup = MatlGroup,
		@hqcountry = DefaultCountry --DC #128925
	from bHQCO with (nolock)
	where HQCo = @co 
	
	-- D-03038 --
	IF @@ROWCOUNT = 0
		BEGIN
			SET @errmsg = 'HQ Company does NOT exist!' 
			SET @rcode = 1
			GOTO vspexit
		END
	
	
	-- get info from DDUP
	Select @userprofilepaycategory = PayCategory
	from DDUP
	Where VPUserName = SUSER_NAME()

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPOCommonInfoGetForPOEntry] TO [public]
GO
