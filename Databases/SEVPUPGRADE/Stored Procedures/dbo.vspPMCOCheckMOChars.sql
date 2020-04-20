SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMCOCheckMOChars    Script Date: 04/19/2005 ******/
CREATE    proc [dbo].[vspPMCOCheckMOChars]
/*************************************
 * Created By:	GF 04/19/2005
 * Modified By:
 *
 *
 * validates PM Company MO Number type and characters.
 *
 *
 * Pass:
 * PMCo				PM Company
 * mono				MO Number Type ('P','L', 'A')
 * mocharsproject	MO Characters of project
 * mocharsloc		MO Characters of location
 * mocharsseq		MO Characters of sequence
 *
 * Success returns:
 * 0
 *
 * Error returns:
 * 1 and error message
  **************************************/
(@pmco bCompany, @mono varchar(1), @mocharsproject tinyint, @mocharsseq tinyint, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@mono,'') = ''
  	begin
  	select @msg = 'Missing MO Number type!', @rcode = 1
  	goto bspexit
  	end


-- -- -- check mono type project/sequence
if @mono = 'P'
	begin
	-- -- -- check project characters
	if @mocharsproject < 1 or @mocharsproject > 9
		begin
		select @msg = 'Number of project characters for material order must be between 1 and 9', @rcode = 1
		goto bspexit
		end
	-- -- -- check sequence characters
	if @mocharsseq < 1 or @mocharsseq > 9
		begin
		select @msg = 'Number of sequence characters for material order must be between 1 and 9', @rcode = 1
		goto bspexit
		end
	-- -- -- check length of project + sequence characters
	if @mocharsproject + @mocharsseq > 10
		begin
		select @msg = 'Sum of project and sequence characters for material order may not exceed 10', @rcode = 1
		goto bspexit
		end
	-- -- -- done
	goto bspexit
	end





bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCOCheckMOChars] TO [public]
GO
