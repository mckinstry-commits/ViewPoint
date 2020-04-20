SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRDDUIUpdate    Script Date: 8/28/08 9:36:48 AM ******/

	CREATE   procedure [dbo].[vspPRDDUIUpdate]
	/************************************************************
	* CREATED BY: EN 8/28/08
	*
	*
	* USAGE:
	* Called by vspPRUserSettingSync to prepare for and call vspDDUIUpdate.
	*
	* INPUT PARAMETERS
	*   @seq          DDFI seq # of field for which to update DDUI
	*   @prup_skip	Skip value from PRUP for this field
	*   @prup_setting	PRUP integer setting for field used to indicate whether or not to show it in the grid
	*   @type			1 if field combotype is PRTCUserOpts1 or 2 if combotype is PRTCUserOpts2
	*
	* OUTPUT PARAMETERS
	*   @errmsg       error message
	*
	* RETURN VALUE
	*   0   success
	*   1   fail
	************************************************************/
	@seq smallint, @prup_skip bYN, @prup_setting tinyint, @type tinyint,
	@errmsg varchar(255) output
	as
	set nocount on

	declare @rcode int, @ddui_skip bYN, @ddui_showgrid bYN, @ddui_dflttype tinyint, 
		@ddui_dfltvalue varchar(256), @ddui_req bYN, @ddui_showform bYN, @ddui_showdesc tinyint,
		@ddshowgrid bYN, @ddshowdesc tinyint

	select @rcode = 0
   
	-- check for null input params
	if @prup_skip is null or @prup_setting is null or @type is null
		begin
		select @errmsg = 'Missing a required input parameter', @rcode = 1
		goto bspexit
		end

	select @ddui_skip = null, @ddui_showgrid = null, @ddui_dflttype = null, 
		@ddui_dfltvalue = null, @ddui_req = null, @ddui_showform = null, @ddui_showdesc = null

	select @ddui_skip = InputSkip, @ddui_showgrid = ShowGrid, @ddui_dflttype = DefaultType, 
		@ddui_dfltvalue = DefaultValue, @ddui_req = InputReq, @ddui_showform = ShowForm, @ddui_showdesc = ShowDesc
	from dbo.DDUI with (nolock) where VPUserName = suser_sname() and Form = 'PRTimeCards' and Seq = @seq

	if @ddui_skip is null select @ddui_skip = 'N'
	if @ddui_showgrid is null select @ddui_showgrid = 'N'

	if @type = 1
		begin
		if @prup_setting in (0,1) select @ddshowgrid = 'N' else select @ddshowgrid = 'Y'
		select @ddshowdesc = null
		end
	if @type = 2
		--if @prup_setting in (0,1,2) select @ddshowgrid = 'N' else select @ddshowgrid = 'Y'
		begin
		if @prup_setting in (0,1,2) select @ddshowgrid = 'N', @ddshowdesc = null
		--if @prup_setting in (0,1) select @ddshowgrid = 'N', @ddshowdesc = null
		--if @prup_setting = 2 select @ddshowgrid = 'N', @ddshowdesc = 1
		if @prup_setting = 3 select @ddshowgrid = 'Y', @ddshowdesc = 2
		if @prup_setting = 4 select @ddshowgrid = 'Y', @ddshowdesc = 0
		if @prup_setting = 5 select @ddshowgrid = 'Y', @ddshowdesc = 1
		end

	if @prup_skip <> @ddui_skip or @ddshowgrid <> @ddui_showgrid or isnull(@ddshowdesc,99) <> isnull(@ddui_showdesc,99)
		exec @rcode = vspDDUIUpdate 'PRTimeCards', @seq, @ddui_dflttype, @ddui_dfltvalue, @prup_skip,
							@ddui_req, @ddshowgrid, @ddui_showform, @ddshowdesc, @errmsg output
   
   
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRDDUIUpdate] TO [public]
GO
