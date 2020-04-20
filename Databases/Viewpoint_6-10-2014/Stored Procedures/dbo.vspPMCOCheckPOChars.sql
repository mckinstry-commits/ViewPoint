SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMCOCheckPOChars    Script Date: 04/19/2005 ******/
CREATE   proc [dbo].[vspPMCOCheckPOChars]
/*************************************
 * Created By:	GF 04/19/2005
 * Modified By:  TRL 08//19/2011  TK-07818 Changed size of POCharsProject and POSeqLen to 10 
 *					   TRL 10/29/2013 - Bug 64937.  Cleaned up error messages and allow seq to expand to greater than 20 chars
 *
 * validates PM Company PO Number type and characters.
 *
 *
 * Pass:
 * PMCo				PM Company
 * pono				PO Number Type ('P','V', 'A')
 * pocharsproject	PO Characters of project
 * pocharsvendor	PO Characters of vendor
 * pocharsseq		PO Characters of sequence
 *
 * Success returns:
 * 0
 *
 * Error returns:
 * 1 and error message
  **************************************/
(@pmco bCompany, @pono varchar(1), @pocharsproject tinyint, @pocharsvendor tinyint,
 @pocharsseq tinyint, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@pono,'') = ''
  	begin
  	select @msg = 'Missing PO Number type!', @rcode = 1
  	goto bspexit
  	end

-- -- -- check pono type project/vendor
if @pono = 'V'
	begin
	-- -- -- check project characters
	if @pocharsproject < 1 or @pocharsproject >10
		begin
		select @msg = 'Number of project characters for purchase order must be between 1 and 10', @rcode = 1
		goto bspexit
		end
	-- -- -- check vendor characters
	if @pocharsvendor < 1 or @pocharsvendor > 9 
		begin
		select @msg = 'Number of vendor characters for purchase order must be between 1 and 9', @rcode = 1
		goto bspexit
		end
	-- -- -- check length of project + vendor characters
	if @pocharsproject + @pocharsvendor > 30
		begin
		select @msg = 'Sum of project and vendor characters for purchase order may not exceed 10', @rcode = 1
		goto bspexit
		end
	-- -- -- done
	goto bspexit
	end


-- -- -- check pono type project/sequence
if @pono = 'P'
	begin
	-- -- -- check project characters
	if @pocharsproject < 1 or @pocharsproject > 10
		begin
		select @msg = 'Number of project characters for purchase order must be between 1 and 10', @rcode = 1
		goto bspexit
		end
	-- -- -- check sequence characters
	if @pocharsseq < 1 or (@pocharsseq > 20 and @pocharsproject = 10)
		begin
		select @msg = 'Number of sequence characters for purchase order must be between 1 and 20', @rcode = 1
		goto bspexit
		end
	-- -- -- check length of project + sequence characters
	if @pocharsproject + @pocharsseq > 30
		begin
		select @msg = 'Sum of project and sequence characters for purchase order may not exceed 30', @rcode = 1
		goto bspexit
		end
	-- -- -- done
	goto bspexit
	end





bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCOCheckPOChars] TO [public]
GO
