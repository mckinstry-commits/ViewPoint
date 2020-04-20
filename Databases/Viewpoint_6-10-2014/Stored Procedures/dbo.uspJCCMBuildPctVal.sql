SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspJCCMBuildPctVal] /** User Defined Validation Procedure **/
(@Co varchar(100), @Contract varchar(100), @Seq varchar(100), @PTotConAmt varchar(100), @msg varchar(255) output)
AS

declare @rcode INT,@TotalPct bPct, @OldPct bPct
select @rcode = 0

SELECT @TotalPct = SUM(PTotConAmt) FROM dbo.udJCCMEnvInfo
	WHERE Co=@Co AND Contract=@Contract 

SELECT @OldPct = PTotConAmt FROM dbo.udJCCMEnvInfo
	WHERE Co = @Co AND Contract=@Contract AND Seq = @Seq


IF @TotalPct - @OldPct + @PTotConAmt > 1
begin
select @msg = 'Total must be 100 or less', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspJCCMBuildPctVal] TO [public]
GO
