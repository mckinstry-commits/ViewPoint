SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRUPConvert    Script Date: 8/28/08 9:36:48 AM ******/
   
	CREATE   procedure [dbo].[vspPRUPConvert]
	/************************************************************
	* CREATED BY: EN 8/28/08
	*
	*
	* USAGE:
	* Called by vspPRUserSettingSync to convert DDUI values into PRUP equivalent.
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
	@return_skip bYN output, @return_setting tinyint output, @errmsg varchar(255) output
	as
	set nocount on
   
    declare @rcode int, @ddskip bYN, @ddshowgrid bYN, @dfltshowdesc tinyint, @ddshowdesc tinyint

    select @rcode = 0
   
	--Get User info needed to determine PRUP settings from vDDFI (standard setup), vDDFIc (customer setup), 
	--	and vDDUI (user setup):
	-- To determine Show On Grid value; default to 'N', then look in vDDFI, then in vDDFIc, then in vDDUI.
    -- To determine Skip value; default to 'N', then look in vDDFIc, then in vDDUI.
	-- To determine Show Description value; default to 0, then look in vDDFI, then in vDDFIc, then in vDDUI. 
	select @ddshowgrid = 'N', @dfltshowdesc = 0
	select @ddshowgrid = ShowGrid, @dfltshowdesc = ShowDesc
	from dbo.DDFI with (nolock) where Form = 'PRTimeCards' and Seq = @seq

	select @ddskip = 'N'
	select @ddskip = InputSkip, @ddshowgrid = ShowGrid, @dfltshowdesc = ShowDesc
	from dbo.DDFIc with (nolock) where Form = 'PRTimeCards' and Seq = @seq

	select @ddshowdesc = null
	select @ddskip = InputSkip, @ddshowgrid = ShowGrid, @ddshowdesc = ShowDesc
	from dbo.DDUI with (nolock) where VPUserName = suser_sname() and Form = 'PRTimeCards' and Seq = @seq
	if @@rowcount = 0
		begin
		select @ddshowdesc = @dfltshowdesc
		end
	else
		begin
		if @ddshowgrid = 'Y' and @ddshowdesc is null
			begin
			select @ddshowdesc = 2
			if @prup_setting in (2,5) select @ddshowdesc = 1
			if @prup_setting = 4 select @ddshowdesc = 0
			end
		end

--	if @@rowcount <> 0
--		begin
--		select @return_skip = @prup_skip
--		if @ddui_skip is not null
--			if @ddui_skip <> @prup_skip select @return_skip = @ddui_skip
--

	-- select return values
	select @return_skip = isnull(@ddskip,'N')

	if @type = 1
		begin
		--if DD is setup with ShowInGrid = 'Y', change PRUP setting to 2 (field in grid)
		if @ddshowgrid = 'Y' select @return_setting = 2
		--if DD is setup with ShowInGrid = 'N' and PRUP setting is 2 (field in grid), change setting to 0 (no grid input)
		--by first checking that the PRUP setting is 2, we insure that we aren't disturbing a previous setting of 0 or 1
		if @ddshowgrid = 'N' 
			begin
			if @prup_setting = 2 
				select @return_setting = 0  
			else
				select @return_setting = @prup_setting
			end
		end
	if @type = 2
		begin
		select @return_setting = @prup_setting
		--if DD is setup with ShowInGrid = 'Y' and ShowDesc = 2, change PRUP setting to 3
		if @ddshowgrid = 'Y' and @ddshowdesc = 2 select @return_setting = 3
		--if DD is setup with ShowInGrid = 'Y' and ShowDesc = 0, change PRUP setting to 4
		if @ddshowgrid = 'Y' and @ddshowdesc = 0 select @return_setting = 4
		--if DD is setup with ShowInGrid = 'Y' and ShowDesc = 1, change PRUP setting to 5
		if @ddshowgrid = 'Y' and @ddshowdesc = 1 select @return_setting = 5
		--if DD is setup with ShowInGrid = 'N' and PRUP setting was previously set to 3 or 4, change PRUP setting to 0
		if @ddshowgrid = 'N' and @prup_setting in (3,4) select @return_setting = 0
		--if DD is setup with ShowInGrid = 'N' and PRUP setting was previously set to 5, change PRUP setting to 2
		if @ddshowgrid = 'N' and @prup_setting = 5 select @return_setting = 2
		end
--		end

   
    bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRUPConvert] TO [public]
GO
