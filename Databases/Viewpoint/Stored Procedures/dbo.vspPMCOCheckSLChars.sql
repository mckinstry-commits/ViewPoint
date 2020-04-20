SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMCOCheckSLChars    Script Date: 04/19/2005 ******/
CREATE    proc [dbo].[vspPMCOCheckSLChars]
/*************************************
 * Created By:	GF 04/19/2005
 * Modified By:	GF 07/02/2010 - issue #135813 change to allow more subcontract characters
 *
 *
 * validates PM Company SL Number type and characters.
 *
 *
 * Pass:
 * PMCo				PM Company
 * slno				SL Number Type ('P','V')
 * slcharsproject	SL Characters of project
 * slcharsvendor	SL Characters of vendor
 * slcharsseq		SL Characters of sequence
 *
 * Success returns:
 * 0
 *
 * Error returns:
 * 1 and error message
  **************************************/
(@pmco bCompany, @slno varchar(1), @slcharsproject tinyint, @slcharsvendor tinyint,
 @slcharsseq tinyint, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@slno,'') = ''
  	begin
  	select @msg = 'Missing SL Number type!', @rcode = 1
  	goto bspexit
  	end

-- -- -- check slno type project/vendor
if @slno = 'V'
	begin
	-- -- -- check project characters
	if @slcharsproject < 1 or @slcharsproject > 10
		begin
		select @msg = 'Number of project characters for Subcontract must be between 1 and 10', @rcode = 1
		goto bspexit
		end
	-- -- -- check vendor characters
	if @slcharsvendor < 1 or @slcharsvendor > 9
		begin
		select @msg = 'Number of vendor characters for Subcontract must be between 1 and 8', @rcode = 1
		goto bspexit
		end
	-- -- -- check length of project + vendor characters
	if @slcharsproject + @slcharsvendor > 30
		begin
		select @msg = 'Sum of project and vendor characters for Subcontract may not exceed 30', @rcode = 1
		goto bspexit
		end
	-- -- -- done
	goto bspexit
	end


-- -- -- check slno type project/sequence
if @slno = 'P'
	begin
	-- -- -- check project characters
	if @slcharsproject < 1 or @slcharsproject > 10
		begin
		select @msg = 'Number of project characters for Subcontract must be between 1 and 10', @rcode = 1
		goto bspexit
		end
	-- -- -- check sequence characters
	if @slcharsseq < 1 or @slcharsseq > 20
		begin
		select @msg = 'Number of sequence characters for Subcontract must be between 1 and 10', @rcode = 1
		goto bspexit
		end
	-- -- -- check length of project + sequence characters
	if @slcharsproject + @slcharsseq > 30
		begin
		select @msg = 'Sum of project and sequence characters for Subcontract may not exceed 30', @rcode = 1
		goto bspexit
		end
	-- -- -- done
	goto bspexit
	end





bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCOCheckSLChars] TO [public]
GO
