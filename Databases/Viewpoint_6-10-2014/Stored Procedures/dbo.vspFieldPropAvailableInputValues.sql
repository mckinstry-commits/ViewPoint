SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL, vspFieldPropAvailableInputValues
-- Create date: 1/29/09
-- Description:	Gets the types available for fixed values
-- =============================================
CREATE PROCEDURE [dbo].[vspFieldPropAvailableInputValues]
(@form varchar(30), @fieldseq smallint,
 @fieldvalues varchar(255) output, @msg varchar(60) output)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
declare @datatype as varchar(30)
Select @datatype = (select Datatype from DDFI 
																				where Form = @form and
																				Seq = @fieldseq)
																				
declare @controltype as tinyint
Select @controltype = (select ControlType from DDFI 
																				where Form = @form and
																				Seq = @fieldseq)
	
If @controltype = 1 and @datatype is null
				begin
				Select @fieldvalues = 'Enter a 0 for unchecked or a 1 for checked.'
				goto vspexit
				end



vspexit:

return
				
				
				




END

GO
GRANT EXECUTE ON  [dbo].[vspFieldPropAvailableInputValues] TO [public]
GO
